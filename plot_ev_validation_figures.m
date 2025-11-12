
clc;
clear;
close all;

%% --- Parameters ---
ev_data_folder = 'E_Mobility_Data';
SCENARIO_FILE = 'EV_trend_h1.mat'; % File to load
YEAR_TO_PLOT = 10; % Plot the final year (Year 10 = 2031)
EV_TO_PLOT = 1;  % Plot the first EV
WEEK_TO_PLOT = 12; % Plot a sample week (e.g., 12th week)

fprintf('Loading data from: %s, Year: %d\n', SCENARIO_FILE, YEAR_TO_PLOT);

%% Load Data 
try
    load(fullfile(ev_data_folder, SCENARIO_FILE), 'EV_beh');
catch
    error('Could not load %s. Please run MAIN_create_all_scenarios.m first.', SCENARIO_FILE);
end

year_data = EV_beh{YEAR_TO_PLOT};

% Check if debug data exists
if ~isfield(year_data, 'debug_soc_1min')
    error(['The file %s does not contain debug data.' ...
           'Please set DEBUG_SAVE_DETAILS = true in MAIN_create_all_scenarios.m and run it again.'], ...
           SCENARIO_FILE);
end

fprintf('Data loaded. Generating validation plots for Week %d...\n', WEEK_TO_PLOT);

%%  Prepare Data for Plotting (1 Week)

% Hourly data (168 hours)
week_start_hr = (WEEK_TO_PLOT - 1) * 7 * 24 + 1;
week_end_hr = week_start_hr + (7 * 24) - 1;
time_axis_hours = 1:168;

% Minute-level data (10080 minutes)
week_start_min = (WEEK_TO_PLOT - 1) * 7 * 24 * 60 + 1;
week_end_min = week_start_min + (7 * 24 * 60) - 1;
time_axis_mins = 1:(168*60);


% Single EV, 1-minute data
driving_week_1min = year_data.debug_driving_1min(EV_TO_PLOT, week_start_min:week_end_min);
soc_week_1min = year_data.debug_soc_1min(EV_TO_PLOT, week_start_min:week_end_min);
charge_week_1min = year_data.debug_private_charge_1min(EV_TO_PLOT, week_start_min:week_end_min);

% Aggregated, 1-hour data
private_load_week_1hr = year_data.Private_Load_kW(week_start_hr:week_end_hr);
public_load_week_1hr = year_data.Public_Load_kW(week_start_hr:week_end_hr);
public_queue_week_1hr = year_data.Public_Waiting_Time_hrs(week_start_hr:week_end_hr);


%%  Single EV Behavior (1-minute resolution) 
% This figure proves the core logic: driving depletes SOC,
% and low SOC at home triggers charging.
f1 = figure('Name', 'Figure V1: Single EV Logic Validation (1 Week)');
f1.Position = [100, 100, 900, 600];

% Panel 1: Driving Profile
ax1 = subplot(3,1,1);
plot(time_axis_mins, driving_week_1min, 'k');
title(sprintf('Driving Profile (EV %d)', EV_TO_PLOT));
ylabel('Driving (1=Yes)');
ylim([-0.1, 1.1]);
xlim([0, max(time_axis_mins)]);

% Panel 2: State of Charge (SOC)
ax2 = subplot(3,1,2);
plot(time_axis_mins, soc_week_1min, 'b', 'LineWidth', 1.5);
hold on;
% Plot the 85% charging threshold
plot(xlim, [0.85 0.85], 'r--', 'LineWidth', 1);
hold off;
title('State of Charge (SOC)');
ylabel('SOC');
legend('SOC', 'Charge Threshold (85%)', 'Location', 'westoutside');
ylim([0, 1.1]);
xlim([0, max(time_axis_mins)]);

% Panel 3: Private Charging Profile
ax3 = subplot(3,1,3);
plot(time_axis_mins, charge_week_1min, 'Color', [0.8500 0.3250 0.0980]);
title('Private Charging Profile');
ylabel('Charging (1=Yes)');
xlabel('Time (minutes)');
ylim([-0.1, 1.1]);
xlim([0, max(time_axis_mins)]);

% Link axes
linkaxes([ax1, ax2, ax3], 'x');

%% Aggregated Community Load (1-hour resolution) 
% This figure validates the aggregated hourly loads fed into the
% optimization model.
f2 = figure('Name', 'Figure V2: Aggregated Load Validation (1 Week)');
f2.Position = [150, 150, 900, 500];

% Aggregated Private Load
ax4 = subplot(2,1,1);
bar(time_axis_hours, private_load_week_1hr, 'FaceColor', [0 0.4470 0.7410]);
title(sprintf('Aggregated Private Load (All EVs, %s, Year %d)', SCENARIO_FILE, YEAR_TO_PLOT));
ylabel('Power (kW)');
xlim([0, 168]);

% Aggregated Public Load & Queue
ax5 = subplot(2,1,2);
yyaxis left;
bar(time_axis_hours, public_load_week_1hr, 'FaceColor', [0.8500 0.3250 0.0980]);
ylabel('Power (kW)');
ylim_left = max(25, max(public_load_week_1hr) * 1.1);
ylim([0, ylim_left]);

yyaxis right;
plot(time_axis_hours, public_queue_week_1hr, 'k-s', 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
ylabel('EVs in Queue');
ylim_right = max(5, max(public_queue_week_1hr) * 1.2);
ylim([0, ylim_right]);

title('Aggregated Public Load & Waiting Queue');
xlabel('Time (hours)');
legend('Public Load', 'Waiting Queue', 'Location', 'northwest');
xlim([0, 168]);

% Link axes
linkaxes([ax4, ax5], 'x');

fprintf('Validation figures (V1, V2) generated successfully.\n');