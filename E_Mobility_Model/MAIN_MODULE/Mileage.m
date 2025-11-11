function [v_driving_km_pp] = Mileage(v_is_driving, pdf_travel)
    % v14 Refactor: Pure function. Accepts pdf_travel as an argument.
    
    % Check if v_is_driving is empty or all false
    if isempty(v_is_driving) || ~any(v_is_driving)
        v_driving_km_pp = zeros(size(v_is_driving), 'single');
        return;
    end

    fitness = pdf_travel.mins_per_trip.fitness;
    trv_minutes = int32(RandByPDF(fitness, 1, length(v_is_driving)));
    % Prevent division by zero
    trv_minutes(trv_minutes == 0) = 1; 
    
    fitness = pdf_travel.km_per_trip.fitness;
    trv_km = RandByPDF(fitness, 1, length(v_is_driving));
    
    trv_km_per_min = trv_km ./ single(trv_minutes);
    v_driving_km_pp = trv_km_per_min .* single(v_is_driving);
end