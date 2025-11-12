
clc;
clear;
close all;
yalmip('clear');
fprintf('--- Starting Holistic Optimization Workflow ---\n');
fprintf('*** RUNNING IN 10-YEAR "REPRESENTATIVE DAY" MODE (24-hour horizon) ***\n');

%%  SETUP PATHS AND PARAMETERS
% -------------------------------------------------------------------------
fprintf('\n--- Section 0: Checking Setup, Paths, and Data ---\n');
try
    % Check YALMIP and Solver
    fprintf('Checking YALMIP and solver...\n');
    yalmiptest; 
    fprintf('  -> VISUAL CHECK: Please confirm from the table above that GUROBI shows "Success" for SOCP and MISOCP.\n');
    fprintf('  -> Proceeding based on visual confirmation...\n');
    
    % Define and Check Folders
    functions_folder = 'functions';
    ev_data_folder = 'E_Mobility_Data';
    results_folder = 'Results';
    
    if ~exist(functions_folder, 'dir')
        error('PATH_ERROR: The ''%s'' folder is not in the current directory.', functions_folder);
    end
    addpath(genpath(functions_folder));
    fprintf('  -> Added ''%s'' folder to path.\n', functions_folder);
    
    if ~exist(ev_data_folder, 'dir')
        error('PATH_ERROR: The ''%s'' folder is not in the current directory.', ev_data_folder);
    end
    fprintf('  -> Found ''%s'' folder.\n', ev_data_folder);
    
    if ~exist(results_folder, 'dir')
       mkdir(results_folder);
       fprintf('  -> Created ''/Results/'' folder.\n');
    end
    
    %  Check for Core Function 'Allp.m' 
    if ~exist('Allp.m', 'file')
        error('FUNCTION_ERROR: ''Allp.m'' not found. Is it inside the ''%s'' folder?', functions_folder);
    end
    fprintf('  -> Found ''Allp.m''.\n');
    
    % Check for E-Mobility Data Files
    scenarios_to_run = {'Negative', 'Trend', 'Positive'};
    for s_check = 1:length(scenarios_to_run)
        scenario_file = sprintf('EV_%s_h1.mat', lower(scenarios_to_run{s_check}));
        scenario_path = fullfile(ev_data_folder, scenario_file);
        if ~exist(scenario_path, 'file')
            error('DATA_ERROR: Cannot find required data file: %s', scenario_path);
        end
    end
    fprintf('  -> All E-Mobility data files found in ''%s''.\n', ev_data_folder);

    % Set Horizon to 24 hours (Representative Day)
    opt.Horizon = 24; 
    opt.Period = 10;
    budget_factors_to_run = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8];
    
    % --- Global Parameters ---
    Scenario = 1; 
    EV = 1;
    SetC.netcase = 'MG';
    SetC.interp = 1; 
    co2_price_per_ton_by_year = [30, 30, 35, 35, 45, 55, 55, 60, 65, 70]; % 10-year vector
    
    % --- 5. Run 'Allp.m' to get data paths ---
    path = Allp(SetC);
    fprintf('  -> Paths from Allp.m loaded successfully.\n');
    
    % Check for Data Files loaded by Allp.m
    if ~exist(fullfile(path.dat1, 'LoadDat.m'), 'file')
        error('DATA_ERROR: Cannot find ''LoadDat.m'' in the path specified by Allp.m: %s', path.dat1);
    end
    if ~exist(fullfile(path.wind, 'wind.mat'), 'file')
        error('DATA_ERROR: Cannot find ''wind.mat'' in the path specified by Allp.m: %s', path.wind);
    end
    if ~exist(path.space_heating, 'file')
        error('DATA_ERROR: Cannot find space heating data at: %s', path.space_heating);
    end
    fprintf('  -> Core data files specified by Allp.m seem to exist.\n');
    
catch ME
    % Catch any error during setup
    fprintf('\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
    fprintf('*** SETUP FAILED. Please fix this error to continue. ***\n');
    fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
    rethrow(ME); % Rethrow the error to stop the script
end

% Initialize Base Parameters (Nodes, Grid, etc.) 
% function definition, which returns 13 arguments.
[base_cost, base_Grid, base_Bat, base_heat, base_CHP, base_opt, ...
 base_ANZ, base_NET, base_mpc, base_NOD, base_PROF, base_LIN, base_H2] = ...
    setup_optimization_parameters(opt, path, SetC, Scenario, EV);
fprintf('Base optimization parameters and YALMIP variables initialized.\n');
fprintf('--- Section 0: Setup Complete. ---\n');

%% RUN DETERMINISTIC OPTIMIZATION (All Scenarios)
% -------------------------------------------------------------------------
fprintf('\n--- STAGE 1: Running Deterministic Optimization (All Scenarios) ---\n');
tic;
for s = 1:length(scenarios_to_run)
    current_scenario = scenarios_to_run{s};
    fprintf('\n  == Processing Scenario: %s ==\n', current_scenario);
    SCENARIO_FILE = sprintf('EV_%s_h1.mat', lower(current_scenario));
    ev_data_path = fullfile(ev_data_folder, SCENARIO_FILE);
    load(ev_data_path, 'EV_beh');
    fprintf('  Loaded E-Mobility data from: %s\n', ev_data_path);
    
    Deterministic_Results = cell(opt.Period, 1);
    obj1_deterministic_cost = zeros(opt.Period, 1);
    inv1 = zeros(opt.Period, 1);
    ope1 = zeros(opt.Period, 1);
    co21 = zeros(opt.Period, 1);
    Capacities = zeros(8, opt.Period); % 8 DERs (no CHP)
    Cost_Breakdown = zeros(3, opt.Period); % Inv, Op, CO2
    for y = 1:opt.Period
        fprintf('    -> Processing Deterministic Year %d/%d... \n', y, opt.Period);
        
        Grid = base_Grid;
        cost = base_cost;
        
        cost.cCO2_per_kg = co2_price_per_ton_by_year(y) / 1000; 
        
        % 'Grid.Pload' is already the correct [35 x 24] averaged profile
        % inherited from 'base_Grid'. (Fix v25)
        
        year_data = EV_beh{y};
        
        % Average 8760-hour EV data down to 24-hour representative day 
        private_load_8760 = year_data.Private_Load_kW;
        public_load_8760 = year_data.Public_Load_kW;
        
        Grid.EV_load_private_avg = mean(reshape(private_load_8760, 24, 365), 2)';
        Grid.EV_load_public_avg = mean(reshape(public_load_8760, 24, 365), 2)';
        
        % Assign private load
        nEV_Private = sum(Grid.EV_load_private_avg > 0);
        if nEV_Private > 0
            % This line should now work, as base_ANZ is the correct struct
            busno = [2:base_ANZ.K]; 
            take_me = datasample(busno, min(nEV_Private, base_ANZ.K-1), 'Replace', false);
            Grid.Pload(take_me, :) = Grid.Pload(take_me, :) + (Grid.EV_load_private_avg / length(take_me));
        end
        Grid.EV_load = Grid.EV_load_public_avg; % [1 x 24]
        
        % Run the deterministic optimization function 
        Results = Deterministic_main1(y, cost, Grid, base_Bat, base_heat, ...
                                      base_opt, base_ANZ, base_NET, base_mpc, ...
                                      base_NOD, base_PROF, base_LIN, base_H2);
        
        Deterministic_Results{y} = Results;
        obj1_deterministic_cost(y) = Results.obj;
        inv1(y) = Results.inv;
        ope1(y) = Results.ope;
        co21(y) = Results.co2;
        Capacities(:, y) = Results.cap;
        Cost_Breakdown(:, y) = [Results.inv; Results.ope; Results.co2];
        
        fprintf('       ...Year %d Complete. Annualized Cost: %.2f €\n', y, Results.obj);
    end
    
    results_path_det = fullfile(results_folder, sprintf('deterministic_results_%s.mat', lower(current_scenario)));
    save(results_path_det, 'Deterministic_Results', 'obj1_deterministic_cost', ...
         'inv1', 'ope1', 'co21', 'Capacities', 'Cost_Breakdown');
    fprintf('  Scenario %s complete. Results saved to %s\n', current_scenario, results_path_det);
end
Deterministic_Run_Time = toc;
fprintf('\n--- STAGE 1 Complete (Total Time: %.2f s) ---\n', Deterministic_Run_Time);

%%  RUN IGDM STOCHASTIC (Trend Scenario Only) 
% -------------------------------------------------------------------------
fprintf('\n--- STAGE 2: Running IGDM Stochastic (Trend Scenario, %d Budgets) ---\n', length(budget_factors_to_run));
load(fullfile(results_folder, 'deterministic_results_trend.mat'), 'obj1_deterministic_cost', 'Deterministic_Results');
load(fullfile(ev_data_folder, 'EV_trend_h1.mat'), 'EV_beh');
IGDM_Robustness = zeros(length(budget_factors_to_run), 1);
IGDM_Final_Cost = zeros(length(budget_factors_to_run), 1);
IGDM_Final_Caps = cell(length(budget_factors_to_run), 1);
y = 10; % We only care about the final planning year for this chart
tic;
for b = 1:length(budget_factors_to_run)
    current_budget_factor = budget_factors_to_run(b);
    fprintf('  -> Processing Budget Factor: %.2f (%.0f%%)\n', ...
             current_budget_factor, (current_budget_factor-1)*100);
    Grid = base_Grid;
    cost = base_cost;
    
    cost.cCO2_per_kg = co2_price_per_ton_by_year(y) / 1000;
    
    % 'Grid.Pload' from 'base_Grid' is already the correct 24-hr profile. (Fix v25)
    
    year_data = EV_beh{y};
    
    private_load_8760 = year_data.Private_Load_kW;
    public_load_8760 = year_data.Public_Load_kW;
    Grid.EV_load_private_avg = mean(reshape(private_load_8760, 24, 365), 2)';
    Grid.EV_load_public_avg = mean(reshape(public_load_8760, 24, 365), 2)';
    nEV_Private = sum(Grid.EV_load_private_avg > 0);
    if nEV_Private > 0
        busno = [2:base_ANZ.K]; 
        take_me = datasample(busno, min(nEV_Private, base_ANZ.K-1), 'Replace', false);
        Grid.Pload(take_me, :) = Grid.Pload(take_me, :) + (Grid.EV_load_private_avg / length(take_me));
    end
    Grid.EV_load = Grid.EV_load_public_avg;
    
    Grid.nEVCS_base = 3; 
    base_evcs_cost = Grid.nEVCS_base * cost.EVCS_capital_ann;
    Grid.obj_budget = (obj1_deterministic_cost(y) + base_evcs_cost) * current_budget_factor;
    Deterministic_Caps = Deterministic_Results{y}.cap; 
    
    Results2 = Copy_of_IGDM(y, cost, Grid, base_Bat, base_heat, ...
                            base_opt, base_ANZ, base_NET, base_mpc, ...
                            Deterministic_Caps, base_NOD, base_PROF, base_LIN, base_H2);
    IGDM_Robustness(b) = -Results2.obj; 
    IGDM_Final_Cost(b) = Results2.obj1;
    IGDM_Final_Caps{b} = Results2.cap;
    
    fprintf('     ...Budget %.2f Complete. Robustness (Alpha): %.3f | Final Cost: %.2f €\n', ...
             current_budget_factor, IGDM_Robustness(b), IGDM_Final_Cost(b));
end
Stochastic_Run_Time = toc;
results_path_sto = fullfile(results_folder, 'stochastic_results_igdm.mat');
save(results_path_sto, 'IGDM_Robustness', 'IGDM_Final_Cost', ...
     'IGDM_Final_Caps', 'budget_factors_to_run');
fprintf('\n--- STAGE 2 Complete (Time: %.2f s). Results saved to %s ---\n', Stochastic_Run_Time, results_path_sto);
fprintf('\n*** Holistic Optimization Workflow Finished. ***\n');
fprintf('You can now run "plot_deterministic_results" and "plot_stochastic_results".\n');
