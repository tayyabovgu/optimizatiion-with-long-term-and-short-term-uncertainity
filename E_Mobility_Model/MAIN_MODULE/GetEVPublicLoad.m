function [waiting_time, EV_public_load, EVCS_state_log, EV_state_log] = GetEVPublicLoad(EV_Profile, Horizon, nEVs, nEVCS)

if nEVs == 1 && size(EV_Profile, 1) > 1
    EV_Profile = EV_Profile';
end
EV_Profile = int16(EV_Profile(1:nEVs, 1:Horizon));
% List of EV indices currently waiting (FIFO queue)
waiting_list = []; 
% Tracks which EV is at which charger. 0 = free.
% We assume a 1-hour charge time, so this just tracks EV ID.
evcs_slots = zeros(nEVCS, 1); 
% Tracks the state of each EV (-1 = charging, 1 = waiting, 0 = idle)
EV_state = zeros(nEVs, Horizon); 
EVCS_state_log = cell(1, Horizon); % Log of which EVs are charging
EV_public_load = zeros(1, Horizon);
waiting_time = zeros(1, Horizon); % Log of queue length

% --- Main Simulation Loop ---
for h = 1:Horizon
       evcs_slots(:) = 0; % All slots are now free
   new_arrivals = find(EV_Profile(:, h) == 1)';
    waiting_list = [waiting_list, new_arrivals];
    free_slots_idx = 1:nEVCS;
    
    num_to_assign = min(length(waiting_list), length(free_slots_idx));
    
    if num_to_assign > 0
        evs_to_charge = waiting_list(1:num_to_assign);
        
        waiting_list(1:num_to_assign) = [];
        
        evcs_slots(free_slots_idx(1:num_to_assign)) = evs_to_charge;
    end
    
    
    currently_charging_evs = evcs_slots(evcs_slots > 0);
    EVCS_state_log{h} = currently_charging_evs;
    
    % The load is (number of busy chargers) * 22 kW
    num_busy_chargers = length(currently_charging_evs);
    EV_public_load(h) = num_busy_chargers * 22.0; 
    
    % Log the number of EVs still waiting in the queue
    waiting_time(h) = length(waiting_list);
    
    % Log the state of all EVs for this hour
    if ~isempty(currently_charging_evs)
        EV_state(currently_charging_evs, h) = -1; % Charging
    end
    if ~isempty(waiting_list)
        EV_state(waiting_list, h) = 1; % Waiting
    end
end

EV_state_log = EV_state;

end