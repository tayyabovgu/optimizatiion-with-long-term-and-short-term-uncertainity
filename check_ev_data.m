

clc; 
clear; 
close all;

ev_data_folder = 'E_Mobility_Data';
planning_horizon = 10;
years = 2022:(2022 + planning_horizon - 1);
fprintf('--- Analyzing Input EV Data... ---\n');

try
    % --- 1. Analyze "Trend" Scenario ---
    fprintf('Loading Trend data from %s...\n', fullfile(ev_data_folder, 'EV_trend_h1.mat'));
    load(fullfile(ev_data_folder, 'EV_trend_h1.mat'), 'EV_beh');
    
    total_annual_ev_load_trend = zeros(planning_horizon, 1);
    for y = 1:planning_horizon
        year_data = EV_beh{y};
        % Sum all 8760 hourly loads for the year
        total_load = sum(year_data.Private_Load_kW) + sum(year_data.Public_Load_kW);
        total_annual_ev_load_trend(y) = total_load;
    end
    
    % --- 2. Analyze "Positive" Scenario ---
    fprintf('Loading Positive data from %s...\n', fullfile(ev_data_folder, 'EV_positive_h1.mat'));
    load(fullfile(ev_data_folder, 'EV_positive_h1.mat'), 'EV_beh');
    
    total_annual_ev_load_positive = zeros(planning_horizon, 1);
    for y = 1:planning_horizon
        year_data = EV_beh{y};
        % Sum all 8760 hourly loads for the year
        total_load = sum(year_data.Private_Load_kW) + sum(year_data.Public_Load_kW);
        total_annual_ev_load_positive(y) = total_load;
    end
    
catch ME
    error('Could not load EV data files. Are they in the ''%s'' folder?', ev_data_folder);
end

fprintf('Data loaded and analyzed. Generating plots.\n');

%% --- Plot 1: Trend Scenario EV Load ---
figure('Name', 'EV Load Analysis (Trend Scenario)');
% Plot in MWh (dividing by 1000)
plot(years, total_annual_ev_load_trend / 1000, 'r--s', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
title('Total Annual EV Load (Trend Scenario)');
xlabel('Years');
ylabel('Total Annual Load (MWh)');
grid on;
xlim([min(years), max(years)]);
xticks(years);
xtickangle(45);

%% --- Plot 2: Positive Scenario EV Load ---
figure('Name', 'EV Load Analysis (Positive Scenario)');
% Plot in MWh (dividing by 1000)
plot(years, total_annual_ev_load_positive / 1000, 'Color', [0.5 0.5 0.5], 'LineStyle', '-.', 'Marker', '^', 'LineWidth', 1.5);
title('Total Annual EV Load (Positive Scenario)');
xlabel('Years');
ylabel('Total Annual Load (MWh)');
grid on;
xlim([min(years), max(years)]);
xticks(years);
xtickangle(45);

