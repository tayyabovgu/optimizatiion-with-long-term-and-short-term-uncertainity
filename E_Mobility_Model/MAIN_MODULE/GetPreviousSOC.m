function pre_soc = GetPreviousSOC(ev_id, start_index, behaviours, mc_params)
    % v14 Refactor: Pure function. Accepts behaviours and mc_params.
    if start_index > 1
        pre_soc = behaviours.soc(ev_id, start_index - 1);
    else
        pre_soc = mc_params.eday_soc(ev_id, :);
    end
end