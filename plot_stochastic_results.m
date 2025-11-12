clc; clear; close all;
fprintf('--- Generating Advanced Analysis Figures ---\n');
% --- Define Paths ---
functions_folder = 'functions';
ev_data_folder = 'E_Mobility_Data';
results_folder = 'Results';
addpath(genpath(functions_folder));
% --- Parameters for Analysis ---
YEAR_TO_ANALYZE = 10; % Analyze the final planning year (2031)
opt.Horizon = 8760; % Use 8760 to get full 8760-hour price/load profiles
opt.Period = 10;
Scenario = 1; EV = 1; SetC.netcase = 'MG'; SetC.interp = 1; 
fprintf('Loading data for Year %d (2031)...\n', YEAR_TO_ANALYZE);

%% --- Load All Required Data ---
try
    % Load the 'Trend' deterministic results
    load(fullfile(results_folder, 'deterministic_results_trend.mat'), 'Cost_Breakdown', 'Capacities');
    % Get the cost and caps for the FINAL year
    Cost_Optimized = Cost_Breakdown(:, YEAR_TO_ANALYZE);
    Caps_Deterministic = Capacities(:, YEAR_TO_ANALYZE);
    
    % Load the 'Trend' stochastic (IGDM) results
    load(fullfile(results_folder, 'stochastic_results_igdm.mat'), ...
         'IGDM_Robustness', 'IGDM_Final_Cost', 'IGDM_Final_Caps', ...
         'budget_factors_to_run');
    
    % Load the 'Trend' EV data file
    load(fullfile(ev_data_folder, 'EV_trend_h1.mat'), 'EV_beh');
    EV_Data_Year_10 = EV_beh{YEAR_TO_ANALYZE};
    
    % Run setup *once* to get 8760-hour base loads and price data
    path = Allp(SetC);
    % NOTE: We set opt.Horizon=8760 before calling this!
    [cost, ~, ~, ~, ~, opt, ANZ, NET, mpc, NOD, PROF, LIN, H2] = ...
        setup_optimization_parameters(opt, path, SetC, Scenario, EV);
    
    % Get the correct CO2 price for the final year
    co2_price_per_ton_by_year = [30, 30, 35, 35, 45, 55, 55, 60, 65, 70];
    cost.cCO2_per_kg = co2_price_per_ton_by_year(YEAR_TO_ANALYZE) / 1000;
    
    fprintf('All data loaded successfully.\n');
catch ME
    error('Could not load all required .mat files. Please run MAIN_Run_Holistic_Optimization.m first. Error: %s', ME.message);
end

%% --- Holistic Potential (Optimized vs. Grid-Only) ---
% Calculates the cost of a "Grid-Only" (no DERs) scenario
% and compares it to our optimized deterministic plan.
% -------------------------------------------------------------------------
fprintf('Generating Figure V3: Holistic Potential...\n');
% Calculate Total Hourly Load for Year 10
%    (NOD.PLoadProf is 35x8760, cost.price is 1x8760)
P_load_base_hourly = sum(NOD.PLoadProf, 1); % [1x8760]
P_load_ev_hourly = EV_Data_Year_10.Private_Load_kW + EV_Data_Year_10.Public_Load_kW; % [1x8760]
P_load_total_hourly = P_load_base_hourly + P_load_ev_hourly;

%  Calculate Grid-Only Costs
% (We assume public EVCSs are built, so Inv cost is for EVCS only)
GridOnly_InvCost = cost.EVCS_capital_ann * 3; % 3 stations in Year 10
GridOnly_OpCost = sum(P_load_total_hourly .* cost.price);
GridOnly_CO2Cost = (sum(P_load_total_hourly) * cost.CO2grid_kg_per_kWh) * cost.cCO2_per_kg;
Cost_GridOnly = [GridOnly_InvCost; GridOnly_OpCost; GridOnly_CO2Cost];

% Get Optimized Costs (from our results file)
% (We add the base EVCS cost, which was not in the deterministic 'Inv')
Cost_Optimized_With_EVCS = Cost_Optimized + [cost.EVCS_capital_ann * 3; 0; 0];


% Plot the comparison
figure('Name', 'Figure V3: Holistic Potential (Year 2031)');
bar_data = [Cost_GridOnly, Cost_Optimized_With_EVCS] / 1000; % Convert to k€
b = bar(bar_data, 'stacked');


if length(b) >= 1
    b(1).FaceColor = [0.8 0 0];    % Investment
end
if length(b) >= 2
    b(2).FaceColor = [0 0.447 0.741]; % Operation
end
if length(b) >= 3
    b(3).FaceColor = [0.5 0.5 0.5];  % CO2
end
% *** END FIX ***

grid on;
title('Holistic Planning Value (Year 2031)', 'FontSize', 14);
ylabel('Total Annual Cost (k€)');
set(gca, 'XTickLabel', {'Grid-Only Plan', 'Holistic Microgrid Plan'});
legend('Investment Cost', 'Operational Cost', 'CO2 Penalty Cost', 'Location', 'northeast');

Total_GridOnly = sum(Cost_GridOnly);
Total_Optimized = sum(Cost_Optimized_With_EVCS);
Savings = Total_GridOnly - Total_Optimized;
Savings_Pct = (Savings / Total_GridOnly) * 100;
fprintf('  -> Grid-Only Cost: %.2f €\n', Total_GridOnly);
fprintf('  -> Optimized Cost: %.2f €\n', Total_Optimized);
fprintf('  -> Annual Savings: %.2f € (%.1f%%)\n', Savings, Savings_Pct);

%% --- Figure V4: IGDM Potential (Deterministic vs. Robust Capacity) ---
% Compares the final DER capacities for the "base" deterministic plan
% vs. the "100% robust" (1.8 budget) stochastic plan.
% -------------------------------------------------------------------------
fprintf('Generating Figure V4: IGDM Potential (Capacity Comparison)...\n');
Caps_Stochastic_Robust = IGDM_Final_Caps{end}; % Get caps from 1.8 budget
DER_Labels = {'PV', 'Wind', 'EESS', 'HP', 'TESS', 'FC', 'Elec', 'HESS'};
figure('Name', 'Figure V4: IGDM Capacity Comparison (Year 2031)');
bar_data_caps = [Caps_Deterministic, Caps_Stochastic_Robust];
bar(bar_data_caps, 'grouped');
grid on;
title('Impact of Robustness on Microgrid Design (Year 2031)', 'FontSize', 14);
ylabel('Installed Capacity (kW, kWh, or m³)');
set(gca, 'XTickLabel', DER_Labels);
legend('Deterministic Plan (0% Robust)', 'Stochastic Plan (100% Robust)', 'Location', 'northwest');

%% The Decision-Maker's Trade-Off ---
% Plots the "cost of robustness," showing how much robustness (Alpha)
% is "bought" for each increase in the total budget.
% -------------------------------------------------------------------------
fprintf('Generating Figure V5: Decision-Maker''s Trade-Off...\n');
figure('Name', 'Figure V5: The "Cost of Robustness" (Year 2031)');

yyaxis left;
plot(budget_factors_to_run, IGDM_Robustness, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
ylabel('Robustness Achieved (\alpha)');
ylim([0, 1.1]);
set(gca, 'YColor', 'b');

yyaxis right;
plot(budget_factors_to_run, IGDM_Final_Cost / 1000, 'r-s', 'LineWidth', 2, 'MarkerFaceColor', 'r');
ylabel('Total Annual Cost (k€)');
set(gca, 'YColor', 'r');

grid on;
title('IGDM Trade-Off: Cost vs. Robustness (Year 2031)', 'FontSize', 14);
xlabel('Allowable Budget Factor (f_b)');
legend('Robustness (\alpha)', 'Total Annual Cost', 'Location', 'southeast');
xticks(budget_factors_to_run);
xtickformat('%.1f'); % Format x-axis labels

fprintf('\n--- All analysis figures generated. ---\n');