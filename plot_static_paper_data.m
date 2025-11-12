
clc; clear; close all;

fprintf('Generating plots from static paper data...\n');

%% Trend for the cost of CO2 per ton ---
%
figure('Name', 'Figure 2.7: CO2 Cost Trend');
years_co2 = 2021:2:2031;
cost_co2 = [25, 30, 35, 45, 55, 65]; % Data estimated from Fig 2.7
bar(years_co2, cost_co2);
grid on;
title('Trend for the cost of CO_2 per ton');
xlabel('Years');
ylabel('Cost in €/ton');
ylim([0, 100]);

%%GHG emission by electricity grid 
%
figure('Name', 'Figure 2.8: GHG Emission Trend');
% Data estimated from Fig 2.8
years_ghg = [1990, 1994, 1998, 2002, 2006, 2010, 2014, 2018, 2022, 2026, 2030];
emissions_ghg = [680, 620, 560, 540, 520, 480, 490, 400, 320, 250, 180];
plot(years_ghg, emissions_ghg, 'b-s', 'LineWidth', 2, 'MarkerFaceColor', 'b');
grid on;
title('GHG emission by electricity grid');
ylabel('CO2 emission in g/kWh');
ylim([0, 800]);
xlim([1990, 2030]);

%% Number of newly registered EVs 
%
figure('Name', 'Figure 3.1: Newly Registered EVs');
try
    % This data is from your E-Mobility data generation step
    load(fullfile('functions', '1_Files', 'EV', 'EVS.mat'), 'EVSS1');
catch
    error('Could not find EVS.mat. Please ensure it is in /functions/1_Files/EV/');
end

years_ev = 2022:2031;
% Data from EVSS1, assuming 10 years
ev_negative = EVSS1(1:10, 1);
ev_trend = EVSS1(1:10, 2);
ev_positive = EVSS1(1:10, 3);

% The paper's plot shows cumulative EVs
bar_data = [cumsum(ev_negative), cumsum(ev_trend), cumsum(ev_positive)];
b = bar(years_ev, bar_data, 'grouped');
b(1).FaceColor = [0 0.4470 0.7410]; % Blue
b(2).FaceColor = [0.8500 0.3250 0.0980]; % Orange
b(3).FaceColor = [0.9290 0.6940 0.1250]; % Yellow (using gray from paper [0.5 0.5 0.5])
b(3).FaceColor = [0.5 0.5 0.5]; % Gray

grid on;
title('Cumulative EVs in the investigated settlement area');
ylabel('Number of EVs');
legend('Negative', 'Trend', 'Positive', 'Location', 'northwest');
ylim([0, 200]);
xlim([2021, 2032]);

fprintf('Static data figures (2.7, 2.8, 3.1) generated.\n');