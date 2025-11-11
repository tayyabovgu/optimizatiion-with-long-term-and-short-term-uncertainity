% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot_deterministic_results.m
%
% This script loads the results from STAGE 1 and plots the
% deterministic figures (3.7, 3.8, and 3.9).
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc; clear; close all;
fprintf('--- Generating Deterministic Figures (3.7, 3.8, 3.9) ---\n');
results_folder = 'Results';
planning_horizon = 10;
years = 2022:(2022 + planning_horizon - 1);

% --- Load Data for All 3 Scenarios ---
try
    load(fullfile(results_folder, 'deterministic_results_negative.mat'), 'obj1_deterministic_cost', 'Capacities', 'Cost_Breakdown');
    results_neg.total_cost = obj1_deterministic_cost;
    results_neg.caps = Capacities;
    results_neg.costs = Cost_Breakdown;
    
    load(fullfile(results_folder, 'deterministic_results_trend.mat'), 'obj1_deterministic_cost', 'Capacities', 'Cost_Breakdown');
    results_trend.total_cost = obj1_deterministic_cost;
    results_trend.caps = Capacities;
    results_trend.costs = Cost_Breakdown;
    
    load(fullfile(results_folder, 'deterministic_results_positive.mat'), 'obj1_deterministic_cost', 'Capacities', 'Cost_Breakdown');
    results_pos.total_cost = obj1_deterministic_cost;
    results_pos.caps = Capacities;
    results_pos.costs = Cost_Breakdown;
    fprintf('Loaded all 3 deterministic results files.\n');
catch
    error('Could not load results files. Did MAIN_Run_... complete successfully?');
end

%% --- Generate Figure 3.8: Overall cost... for different scenarios ---
figure('Name', 'Figure 3.8: Overall Cost of Settlement Area');
plot(years, results_neg.total_cost / 1000, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
hold on;
plot(years, results_trend.total_cost / 1000, 'r--s', 'LineWidth', 1.5);
plot(years, results_pos.total_cost / 1000, 'Color', [0.5 0.5 0.5], 'LineStyle', '-.', 'Marker', '^', 'LineWidth', 1.5);
hold off;
grid on;
title('Overall Cost of the Settlement Area (Deterministic)');
xlabel('Years');
ylabel('Cost in € (Thousands)');
legend('Negative scenario', 'Trend scenario', 'Positive scenario', 'Location', 'northwest');
xlim([min(years), max(years)]);
% ylim([20, 180]); % Your costs are lower, let's adjust the ylim
ylim([min(results_neg.total_cost / 1000) - 2, max(results_pos.total_cost / 1000) + 2]);
fprintf('Generated Figure 3.8.\n');

%% --- Generate Figure 3.9: Cost analysis of microgrid (Trend) ---
figure('Name', 'Figure 3.9: Cost Analysis (Trend Scenario)');
% Data format is [3 x 10] (Inv; Op; CO2)
costs_trend_k = results_trend.costs / 1000; % Convert to thousands
bar(years, costs_trend_k', 'stacked');
grid on;
title('Cost Analysis of Microgrid (Trend Scenario)');
xlabel('Years');
ylabel('Cost in € (Thousands)');
legend('Investment cost', 'Operational cost', 'CO2 penalty cost', 'Location', 'northwest');
xlim([min(years)-0.5, max(years)+0.5]);
% ylim([0, 80]); % Adjusting ylim based on your data
ylim([0, max(sum(costs_trend_k, 1)) * 1.1]); % Set Y-limit to 10% above max
fprintf('Generated Figure 3.9.\n');

%% --- Generate Figure 3.7: Microgrid capacity (Trend) ---
figure('Name', 'Figure 3.7: Microgrid Capacity (Trend Scenario)');
% Data format is [8 x 10]
% [PV; Wind; EESS; HP; TESS; FC; Elec; HESS]
caps_trend = results_trend.caps;
DER_Labels = {'PV', 'Wind', 'EESS', 'HP', 'TESS', 'FC', 'Elec', 'HESS'};
bar(years, caps_trend', 'grouped');
grid on;
title('Microgrid Capacity (Trend Scenario)');
xlabel('Years');
ylabel('Capacities');
legend(DER_Labels, 'Location', 'northwest');
xlim([min(years)-0.5, max(years)+0.5]);
% ylim([0, 400]); % Adjusting ylim based on your data
ylim([0, max(caps_trend, [], 'all') * 1.1]); % Set Y-limit to 10% above max
fprintf('Generated Figure 3.7.\n');
fprintf('\nDeterministic figures (3.7, 3.8, 3.9) generated.\n');