function [behaviours] = run_ev_simulation(PCS, nEV, chargetime, pdf_travel)
    % v14 Refactor: This is a pure function.
    % It accepts pdf_travel as an argument and returns behaviours.
    % It no longer uses ANY global variables.

    %% 1. Initialize Local Parameters
    mc_params.days = 365;
    mc_params.periods_per_day = 1440;
    mc_params.mins_per_period = (24 * 60) / mc_params.periods_per_day;
    mc_params.total_periods = (24 * 60);
    mc_params.total_periods_year = mc_params.total_periods * mc_params.days;
    mc_params.total_EVs = nEV;
    mc_params.eday_soc = ones(mc_params.total_EVs, 1, 'single');
    
    power_consume_per_km = 0.192; % kwhr per kilometer
    
    battery_EV.capacity = 100;
    battery_EV.voltage = 230;
    battery_EV.power = (battery_EV.capacity * battery_EV.voltage) / 1e3; % kWhr
    battery_EV.fcharge_duration = chargetime;
    battery_EV.fcharge_minutes = battery_EV.fcharge_duration * 60;
    battery_EV.fcharge_periods = ceil(battery_EV.fcharge_minutes);
    battery_EV.full_soc = 0.9;
    battery_EV.lowest_soc = 0.85;

    %% 2. Initialize Behavior Struct
    behaviours.v_is_driving = false(mc_params.total_EVs, mc_params.total_periods_year);
    behaviours.v_is_charging = false(mc_params.total_EVs, mc_params.total_periods_year);
    behaviours.v_driving_km_pp = zeros(mc_params.total_EVs, mc_params.total_periods_year);
    behaviours.v_driving_cost_power = zeros(mc_params.total_EVs, mc_params.total_periods_year);
    behaviours.ev_w_charged = mc_params.mins_per_period / 60 * PCS;
    behaviours.soc = repmat(mc_params.eday_soc, 1, mc_params.total_periods_year); % Pre-fill SOC
    
    %% 3. Start the Simulation
    for d = 1:mc_params.days
        start_mins = 24 * 60 * (d - 1) + 1;
        end_mins = 24 * 60 * (d - 1) + mc_params.total_periods;
        
        % how many num,ber of trip made by total EV
        fitness = pdf_travel.freq_per_day.fitness;
        driving.num = int32(RandByPDF(fitness, mc_params.total_EVs, 1));
        max_num = max(driving.num);
        if max_num == 0; continue; end % Skip day if no one drives

        % how many minutes for all cars.
        fitness = pdf_travel.mins_per_trip.fitness;
        driving.minutes = int32(RandByPDF(fitness, mc_params.total_EVs, max_num));
        
        % KM/all cars
        fitness = pdf_travel.km_per_trip.fitness;
        driving.km_per_trv = RandByPDF(fitness, mc_params.total_EVs, max_num);
        
        % driving start and end time
        fitness_am = pdf_travel.departure_am.fitness;
        fitness_pm = pdf_travel.departure_pm.fitness;
        departure_am = RandByPDF(fitness_am, mc_params.total_EVs, floor(single(max_num) / 2));
        departure_pm = RandByPDF(fitness_pm, mc_params.total_EVs, ceil(single(max_num) / 2));
        time_start = [departure_am, departure_pm];
        
        driving.time_start = int32(time_start * 60);
        driving.time_end = driving.time_start + driving.minutes;
        
        for EV = 1:mc_params.total_EVs
            driving_freq = driving.num(EV);
            if driving_freq == 0; continue; end % Skip EV if it doesn't drive

            driving_start = driving.time_start(EV, 1:driving_freq);
            driving_end = driving.time_end(EV, 1:driving_freq);
            [driving_start, order_index] = sort(driving_start);
            driving_end = driving_end(order_index);
            
            v_start_mins = repmat(driving_start', 1, mc_params.total_periods);
            v_end_mins = repmat(driving_end', 1, mc_params.total_periods);
            v_tperiods = repmat(1:mc_params.total_periods, driving_freq, 1);
            
            isDriving1 = (v_start_mins <= v_tperiods);
            isDriving2 = (v_tperiods <= v_end_mins);
            isDriving = logical(isDriving1 .* isDriving2);
            
            Driving_profile_day = logical(sum(isDriving, 1));
            
            % Call our new pure helper functions
            v_driving_km_pp_day = Mileage(Driving_profile_day, pdf_travel);
            v_driving_cost_power_day = v_driving_km_pp_day .* power_consume_per_km;
            
            % Assign day's profile to the annual 'behaviours' struct
            behaviours.v_is_driving(EV, start_mins:end_mins) = Driving_profile_day;
            behaviours.v_driving_km_pp(EV, start_mins:end_mins) = v_driving_km_pp_day;
            behaviours.v_driving_cost_power(EV, start_mins:end_mins) = v_driving_cost_power_day;
        end
    end
    
    %% 4. Calculate Charging and SOC
    v_able_charge = ~behaviours.v_is_driving;
    behaviours.ev_charged = single(behaviours.v_is_charging * behaviours.ev_w_charged);

    for EV = 1:mc_params.total_EVs
        arr_ev_state = int8((v_able_charge(EV, :) * 2) + behaviours.v_is_driving(EV, :));
        k = Int32_Find([true, diff(arr_ev_state) ~= 0, true]);
        r = k(1:end-1);
        q = diff(k);
        
        driving_pi = r(find(arr_ev_state(r) == 1));
        charge_pi = r(find(arr_ev_state(r) == 2));
        
        for i = 1:length(r)
            index = r(i);
            p_len = q(i);
            start_index = index;
            end_index = index + p_len - 1;
            
            % Get previous SOC, passing 'behaviours' struct
            soc_start = GetPreviousSOC(EV, start_index, behaviours, mc_params);
            
            if ismember(index, driving_pi)
                ev_cost_power = behaviours.v_driving_cost_power(EV, start_index:end_index);
                new_is_driving = behaviours.v_is_driving(EV, start_index:end_index);
                
                soc_cost = cumsum(ev_cost_power, 2) / battery_EV.power;
                soc_remain = soc_start - soc_cost;
                
                no_power_index = find(soc_remain < 0.0);
                new_is_driving(no_power_index) = 0;
                behaviours.v_is_driving(EV, start_index:end_index) = new_is_driving;
                
                % Recalculate cost/km based on updated driving status
                behaviours.v_driving_km_pp(EV, start_index:end_index) = Mileage(new_is_driving, pdf_travel);
                behaviours.v_driving_cost_power(EV, start_index:end_index) = behaviours.v_driving_km_pp(EV, start_index:end_index) .* power_consume_per_km;

            elseif ismember(index, charge_pi)
                if soc_start < battery_EV.lowest_soc
                    % Only charge if necessary
                    start_cperiod = start_index;
                    end_cperiod = min(start_cperiod + battery_EV.fcharge_periods - 1, end_index); % Don't charge past end of park
                    
                    behaviours.v_is_charging(EV, start_cperiod:end_cperiod) = 1;
                    
                    % Check for over-charging
                    new_is_charging = behaviours.v_is_charging(EV, start_index:end_index);
                    add_soc = behaviours.ev_w_charged / battery_EV.power * new_is_charging;
                    p_soc = soc_start + cumsum(add_soc); % Use soc_start
                    
                    ev_fcharged = find(p_soc > battery_EV.full_soc);
                    new_is_charging(ev_fcharged) = 0;
                    behaviours.v_is_charging(EV, start_index:end_index) = new_is_charging;
                end
            end
            
            % Final SOC calculation for this block
            behaviours.ev_charged(EV, start_index:end_index) = single(behaviours.v_is_charging(EV, start_index:end_index) * behaviours.ev_w_charged);
            add_soc = behaviours.ev_charged(EV, start_index:end_index) / battery_EV.power;
            lost_soc = behaviours.v_driving_cost_power(EV, start_index:end_index) / battery_EV.power;
            
            behaviours.soc(EV, start_index:end_index) = soc_start + cumsum(add_soc - lost_soc, 2);
            
            % Propagate the final SOC to the end of the simulation
            if end_index < mc_params.total_periods_year
                behaviours.soc(EV, (end_index+1):end) = behaviours.soc(EV, end_index);
            end
        end
    end
end