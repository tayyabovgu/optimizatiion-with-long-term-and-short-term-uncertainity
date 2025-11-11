

clc;
clear;
close all;

fprintf('--- Starting E-Mobility Data Generation for ALL Scenarios ---\n');

%% ### 0. SETUP PATHS AND PARAMETERS ###
% -------------------------------------------------------------------------
functions_folder = 'functions';
ev_data_folder = 'E_Mobility_Data';
addpath(genpath(functions_folder));

% --- Create EV Data Folder ---
if ~exist(ev_data_folder, 'dir')
   mkdir(ev_data_folder);
   fprintf('Created /E_Mobility_Data/ folder.\n');
end

% --- Simulation Parameters ---
SCENARIOS_TO_RUN = {'Negative', 'Trend', 'Positive'};
NUM_YEARS = 10;
opt.Horizon = 8760; % 1-hour resolution

% --- This flag is still used by plot_ev_validation_figures.m ---
DEBUG_SAVE_DETAILS = true; 

% --- EV Parameters from Paper ---
PCS_PRIVATE = 11.0; % 11 kW private charging
PCS_PUBLIC = 22.0;  % 22 kW public charging
PRIVATE_CHARGE_PERCENT = 0.85;

%% ### 1. GENERATE PROBABILITY DISTRIBUTIONS (Run Once) ###
% -------------------------------------------------------------------------
fprintf('Step 1: Running PDF_TravelBehaviour2 to create fitness_travel.mat...\n');
try
    PDF_TravelBehaviour2(); 
    load('fitness_travel.mat', 'pdf_travel');
    fprintf('   ...fitness_travel.mat created and loaded.\n');
catch ME
    error('Failed to run PDF_TravelBehaviour2. Is travel_behaviour.xlsx in the path? Error: %s', ME.message);
end

%% ### 2. LOAD EV ADOPTION DATA (Run Once) ###
% -------------------------------------------------------------------------
try
    load(fullfile(functions_folder, '1_Files', 'EV', 'EVS.mat'), 'EVSS1');
    fprintf('Step 2: Loaded EV adoption data from EVS.mat.\n');
catch ME
    error('Could not find EVS.mat. Please ensure it is in /functions/1_Files/EV/. Error: %s', ME.message);
end

%% ### 3. LOOP THROUGH ALL SCENARIOS AND GENERATE FILES ###
% -------------------------------------------------------------------------
fprintf('Step 3: Starting simulation loop for %d scenarios.\n', length(SCENARIOS_TO_RUN));

for s = 1:length(SCENARIOS_TO_RUN)
    current_scenario = SCENARIOS_TO_RUN{s};
    fprintf('\n  == Processing Scenario: %s ==\n', current_scenario);
    
    switch current_scenario
        case 'Negative'
            EV_Count_Per_Year = EVSS1(1:NUM_YEARS, 1);
            scenario_col = 1;
        case 'Trend'
            EV_Count_Per_Year = EVSS1(1:NUM_YEARS, 2);
            scenario_col = 2;
        case 'Positive'
            EV_Count_Per_Year = EVSS1(1:NUM_YEARS, 3);
            scenario_col = 3;
    end
    
    EV_beh = cell(NUM_YEARS, 1); 
    
    % --- Loop through each year ---
    for y = 1:NUM_YEARS
        nEV = EV_Count_Per_Year(y);
        fprintf('    -> Processing Year %d/%d with %d EVs...\n', y, NUM_YEARS, nEV);
        
        if nEV == 0
            fprintf('       ...Skipping year %d, no EVs.\n', y);
            EV_beh{y} = struct('Private_Load_kW', zeros(1, opt.Horizon), ...
                               'Public_Load_kW', zeros(1, opt.Horizon), ...
                               'Public_Waiting_Time_hrs', zeros(1, opt.Horizon), ...
                               'v_is_charging_request', zeros(1, opt.Horizon));
            continue;
        end
        
        % --- Step 3a: Run 1-minute Monte Carlo Simulation ---
        % This generates the *truth* for 1-minute private charging
        behaviours = run_ev_simulation(PCS_PRIVATE, nEV, 2, pdf_travel);
        
        % --- Step 3b: Split 1-min charging events (85% / 15%) ---
        % Find all [EV, Minute] pairs where a private charge happened
        [ev_idx, min_idx] = find(behaviours.v_is_charging);
        num_requests = length(ev_idx);
        
        % Create a random decision (Private vs Public) for each event
        rand_split = rand(num_requests, 1);
        
        % Initialize 1-hour aggregate profiles
        % We count *minutes* of charging per hour, then convert to kWh
        Private_Charge_Minutes_1hr = zeros(nEV, opt.Horizon);
        Public_Charge_Request_Profile = zeros(nEV, opt.Horizon);

        for i = 1:num_requests
            ev = ev_idx(i);
            minute_of_year = min_idx(i);
            
            % Convert the minute-of-year to an hour-of-year (1 to 8760)
            hr = floor((minute_of_year - 1) / 60) + 1;
            
            if rand_split(i) <= PRIVATE_CHARGE_PERCENT
                % --- This is a Private Charging minute (85%) ---
                Private_Charge_Minutes_1hr(ev, hr) = Private_Charge_Minutes_1hr(ev, hr) + 1;
            else
                % --- This is a Public Charging minute (15%) ---
                % If *any* minute in this hour is a public request,
                % flag the *entire hour* as a request for the queue model.
                Public_Charge_Request_Profile(ev, hr) = 1;
            end
        end
        
        % --- Step 3c: Calculate Final Private Load ---
        % Sum all EV charging-minutes for each hour
        total_private_minutes_per_hour = sum(Private_Charge_Minutes_1hr, 1);
        % Convert minutes of charging at 11kW to an average hourly kW load
        % (e.g., 60 minutes * (11 kW / 60 min/hr) = 11 kWh)
        % (e.g., 30 minutes * (11 kW / 60 min/hr) = 5.5 kWh)
        Private_Load_kW = total_private_minutes_per_hour * (PCS_PRIVATE / 60);
        
        % --- Step 3d: Simulate the Public Queue ---
        nEVCS_for_year = 1; % Default
        if scenario_col == 2 % Trend
            if y == 8 || y == 9; nEVCS_for_year = 2; end
            if y == 10; nEVCS_for_year = 3; end
        elseif scenario_col == 3 % Positive
            if y == 7 || y == 8; nEVCS_for_year = 2; end
            if y == 9; nEVCS_for_year = 3; end
            if y == 10; nEVCS_for_year = 4; end
        end
        
        nEV_Public = sum(any(Public_Charge_Request_Profile, 2));
        
        if nEV_Public > 0
            public_ev_indices = find(any(Public_Charge_Request_Profile, 2));
            [waiting_time, public_load, ~, ~] = GetEVPublicLoad(...
                Public_Charge_Request_Profile(public_ev_indices, :), ...
                opt.Horizon, ...
                nEV_Public, ...
                nEVCS_for_year);
            
            Public_Load_kW = public_load;
            Public_Waiting_Time_hrs = waiting_time;
        else
            Public_Load_kW = zeros(1, opt.Horizon);
            Public_Waiting_Time_hrs = zeros(1, opt.Horizon);
        end

        % --- Step 3e: Store Final Hourly Profiles ---
        year_results.Private_Load_kW = Private_Load_kW;
        year_results.Public_Load_kW = Public_Load_kW;
        year_results.Public_Waiting_Time_hrs = Public_Waiting_Time_hrs;
        year_results.v_is_charging_request = Public_Charge_Request_Profile(1:min(nEV, end), :);
        
        % *** SAVE DEBUG DATA (Unchanged) ***
        if DEBUG_SAVE_DETAILS
            num_to_save = min(nEV, 10); 
            year_results.debug_soc_1min = behaviours.soc(1:num_to_save, :);
            year_results.debug_driving_1min = behaviours.v_is_driving(1:num_to_save, :);
            % Save the *original* 1-min private charging profile
            year_results.debug_private_charge_1min = behaviours.v_is_charging(1:num_to_save, :);
            fprintf('       ...Saved 1-minute debug data for %d EVs.\n', num_to_save);
        end
        
        EV_beh{y} = year_results;
        fprintf('       ...Year %d complete.\n', y);
    end
    
    % --- Save the final .mat file for this scenario ---
    output_filename = sprintf('EV_%s_h1.mat', lower(current_scenario));
    output_path = fullfile(ev_data_folder, output_filename);
    
    save(output_path, 'EV_beh');
    fprintf('  == Scenario %s FINISHED. Results saved to %s ==\n', current_scenario, output_path);
end

fprintf('\n*** All 3 E-Mobility Scenario files generated successfully. ***\n');