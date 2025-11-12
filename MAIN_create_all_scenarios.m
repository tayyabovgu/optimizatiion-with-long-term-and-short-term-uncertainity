clc;
clear;
close all;
fprintf('--- Starting E-Mobility Data Generation for ALL Scenarios ---\n');
%% SETUP PATHS AND PARAMETERS
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
DEBUG_SAVE_DETAILS = true; 
% --- EV Parameters from Paper ---
PCS_PRIVATE = 11.0; % 11 kW private charging
PCS_PUBLIC = 22.0;  % 22 kW public charging
PRIVATE_CHARGE_PERCENT = 0.85;
%% GENERATE PROBABILITY DISTRIBUTIONS
% -------------------------------------------------------------------------
fprintf('Running PDF_TravelBehaviour2 to create fitness_travel.mat...\n');
try
    PDF_TravelBehaviour2(); 
    load('fitness_travel.mat', 'pdf_travel');
    fprintf('   ...fitness_travel.mat created and loaded.\n');
catch ME
    error('Failed to run PDF_TravelBehaviour2. Is travel_behaviour.xlsx in the path? Error: %s', ME.message);
end
%% LOAD EV ADOPTION DATA 
% -------------------------------------------------------------------------
try
    load(fullfile(functions_folder, '1_Files', 'EV', 'EVS.mat'), 'EVSS1');
    MAX_EV_POPULATION = max(EVSS1, [], 'all'); % Get the largest nEV (e.g., 150)
    fprintf('Loaded EV adoption data. Max EV population is %d.\n', MAX_EV_POPULATION);
catch ME
    error('Could not find EVS.mat. Please ensure it is in /functions/1_Files/EV/. Error: %s', ME.message);
end

%% CREATE STABLE BASE SIMULATION
% -------------------------------------------------------------------------
fprintf('Running 1-minute Monte Carlo simulation for stable base population of %d EVs...\n', MAX_EV_POPULATION);
% This is the key fix: We run the simulation ONCE.
base_behaviours = run_ev_simulation(PCS_PRIVATE, MAX_EV_POPULATION, 2, pdf_travel);
fprintf('   ...Base simulation complete.\n');

%% LOOP THROUGH SCENARIOS AND SAMPLE FROM BASE
% -------------------------------------------------------------------------
fprintf('Starting sampling loop for %d scenarios.\n', length(SCENARIOS_TO_RUN));
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
        
       
        selected_ev_indices = 1:nEV;
        
        % Split this year's EVs into Private and Public 
        nEV_Private = round(nEV * PRIVATE_CHARGE_PERCENT);
        nEV_Public = nEV - nEV_Private;
        
       
        rand_selection = randperm(nEV); 
        
      
        private_ev_list = selected_ev_indices(rand_selection(1:nEV_Private));
        public_ev_list = selected_ev_indices(rand_selection(nEV_Private + 1:end));
        
        %  Calculate Final Private Load (1-hour) 
        if nEV_Private > 0
            private_charging_1min = base_behaviours.v_is_charging(private_ev_list, :);
            private_charging_hourly_blocks = reshape(private_charging_1min, nEV_Private, 60, opt.Horizon);
            private_minutes_per_hour = sum(private_charging_hourly_blocks, 2);
            private_minutes_per_hour = squeeze(private_minutes_per_hour);
            if nEV_Private == 1
                private_minutes_per_hour = private_minutes_per_hour';
            end
            total_private_minutes_per_hour = sum(private_minutes_per_hour, 1);
            Private_Load_kW = total_private_minutes_per_hour * (PCS_PRIVATE / 60);
        else
            Private_Load_kW = zeros(1, opt.Horizon);
        end

        % Simulate the Public Queue (1-hour)
        if nEV_Public > 0
            public_charging_1min = base_behaviours.v_is_charging(public_ev_list, :);
            public_charging_hourly_blocks = reshape(public_charging_1min, nEV_Public, 60, opt.Horizon);
            public_request_hourly = any(public_charging_hourly_blocks, 2);
            Public_Charge_Request_Profile = squeeze(public_request_hourly);
            if nEV_Public == 1
                Public_Charge_Request_Profile = Public_Charge_Request_Profile'; 
            end

            %Get the correct number of public chargers for this year
            nEVCS_for_year = 1; % Default
            if scenario_col == 2 % Trend
                if y == 8 || y == 9; nEVCS_for_year = 2; end
                if y == 10; nEVCS_for_year = 3; end
            elseif scenario_col == 3 % Positive
                if y == 7 || y == 8; nEVCS_for_year = 2; end
                if y == 9; nEVCS_for_year = 3; end
                if y == 10; nEVCS_for_year = 4; end
            end
        
            [waiting_time, public_load, ~, ~] = GetEVPublicLoad(...
                Public_Charge_Request_Profile, ...
                opt.Horizon, ...
                nEV_Public, ...
                nEVCS_for_year);
            
            Public_Load_kW = public_load;
            Public_Waiting_Time_hrs = waiting_time;
            
            num_to_save_public = min(nEV_Public, 10);
            year_results.v_is_charging_request = Public_Charge_Request_Profile(1:num_to_save_public, :);
        
        else
            % No public EVs this year
            Public_Load_kW = zeros(1, opt.Horizon);
            Public_Waiting_Time_hrs = zeros(1, opt.Horizon);
            year_results.v_is_charging_request = zeros(1, opt.Horizon);
        end
        
        % --- Step 4e: Store Final Hourly Profiles ---
        year_results.Private_Load_kW = Private_Load_kW;
        year_results.Public_Load_kW = Public_Load_kW;
        year_results.Public_Waiting_Time_hrs = Public_Waiting_Time_hrs;
        
        if DEBUG_SAVE_DETAILS
            num_to_save = min(nEV, 10);
            % Get the indices from the base population
            debug_indices = selected_ev_indices(1:num_to_save);
            year_results.debug_soc_1min = base_behaviours.soc(debug_indices, :);
            year_results.debug_driving_1min = base_behaviours.v_is_driving(debug_indices, :);
            year_results.debug_private_charge_1min = base_behaviours.v_is_charging(debug_indices, :);
            fprintf('       ...Saved 1-minute  data for %d EVs.\n', num_to_save);
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