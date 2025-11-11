function Results_Grid = Deterministic_main1(y, cost, Grid, Bat, heat, CHP, opt, ANZ, NET, mpc, NOD, PROF, LIN, H2)
    % STAGE 1: Deterministic Optimization (Sec 2.2.1)
    % v13: Fixes 'bat_loss' H2 bug, 'LIN.Imax' bug, and all other flaws.
    
    SpConstraints = [];
    
    % --- Define Constraints for all assets ---
    SpConstraints = [SpConstraints,0<=Grid.Pshed_cap(1,y)<=10000];
    SpConstraints = [SpConstraints,0<=Bat.battCapa(1,y)<=10000];
    SpConstraints = [SpConstraints,0<=Grid.pv_cap(1,y)<=3000];
    SpConstraints = [SpConstraints,0<=Grid.wind_cap(1,y)<=1000];
    SpConstraints = [SpConstraints,0<=heat.hp_cap(1,y)<=5000];
    SpConstraints = [SpConstraints,0<=heat.th_Capa(1,y)<=5000];
    SpConstraints = [SpConstraints,Grid.fc_cap(1,y)>=0, Grid.fc_cap(1,y)<=2500];
    SpConstraints = [SpConstraints,Grid.ELEZ_cap(1,y)>=0, Grid.ELEZ_cap(1,y)<=5000];
    SpConstraints = [SpConstraints,Grid.H2_Capa(1,y)>=0, Grid.H2_Capa(1,y)<=5000];
    SpConstraints = [SpConstraints,CHP.P_CHP_cap(1,y) == 0];

    % --- Grid Constraints ---
    SpConstraints = [SpConstraints,(0.9*400)^2 <= Grid.V(2:end,:) <= (1.1*400)^2]; 
    SpConstraints = [SpConstraints,Grid.V(1,:) == 400^2]; 
    % *** LIN.Imax FIX ***
    SpConstraints = [SpConstraints, Grid.L <= repmat( (LIN.Imax(1:ANZ.L).^2), 1, opt.Horizon )]; 

    % --- Asset Operation Constraints ---
    SpConstraints = [SpConstraints,0<=Bat.Pbatt_ch<=Bat.battChargeOrNot(1,:)*1000000];
    SpConstraints = [SpConstraints,0<=Bat.Pbatt_dis<=Bat.battChargeOrNot(2,:)*100000];
    SpConstraints = [SpConstraints,Bat.battChargeOrNot(1,:)+Bat.battChargeOrNot(2,:)<=1 ]; 
    SpConstraints = [SpConstraints,0<=Bat.bat_store<=Bat.battCapa(1,y)]; 
    SpConstraints = [SpConstraints,0<=Grid.PV<=(Grid.PV_irr.*50000000)];
    SpConstraints = [SpConstraints,0<=Grid.PV<=(Grid.pv_cap(1,y))]; 
    SpConstraints = [SpConstraints,0<=Grid.wind_p<=(Grid.wind.*5000000)];
    SpConstraints = [SpConstraints,0<=Grid.wind_p<=Grid.wind_cap(1,y)]; 
    SpConstraints = [SpConstraints,CHP.P_CHP == 0]; 
    SpConstraints = [SpConstraints,0<=heat.th_store<=heat.th_Capa(1,y)];
    SpConstraints = [SpConstraints,0<=heat.th_in<=heat.thChargeOrNot(1,:)*1000];
    SpConstraints = [SpConstraints,0<=heat.th_out<=heat.thChargeOrNot(2,:)*1000];
    SpConstraints = [SpConstraints,heat.thChargeOrNot(1,:)+heat.thChargeOrNot(2,:)<=1 ];
    SpConstraints = [SpConstraints,0<=Grid.Pelez<=Grid.ELEZ_cap(1,y)];
    SpConstraints = [SpConstraints,0<=Grid.Pfc<=Grid.fc_cap(1,y)];
    SpConstraints = [SpConstraints,0<=Grid.h1];
    % *** ELECTROLYZER FIX (FLAW 2) ***
    SpConstraints = [SpConstraints,Grid.Helz==(1/Grid.hLHV).*Grid.Pelez * 0.70]; 
    SpConstraints = [SpConstraints,Grid.Pfc==Grid.hLHV*Grid.h1*Grid.Pemeff]; 
    SpConstraints = [SpConstraints,Grid.Qfc==Grid.Pfc*((1-Grid.Pemeff-Grid.phloss)/Grid.Pemeff)]; 
    SpConstraints = [SpConstraints, Grid.Helz-Grid.h1-Grid.h2ch+Grid.h2dch==0]; 
    SpConstraints = [SpConstraints,0<=Grid.Pshed<=Grid.Pshed_cap(1,y)];
    SpConstraints = [SpConstraints,0<=Grid.h2ch<=Grid.H2ChargeOrNot(1,:)*1000];
    SpConstraints = [SpConstraints,0<=Grid.h2dch<=Grid.H2ChargeOrNot(2,:)*1000];
    SpConstraints = [SpConstraints,Grid.H2ChargeOrNot(1,:)+Grid.H2ChargeOrNot(2,:)<=1 ];
    SpConstraints = [SpConstraints, 0<=Grid.H2_store<=Grid.H2_Capa(1,y)];
    SpConstraints = [SpConstraints,heat.hp_out==heat.hp_in*heat.hp_eff]; 
    SpConstraints = [SpConstraints,0<=heat.hp_in<=heat.hp_cap(1,y)];

    % --- Power Flow and Heat Flow (Loop over Horizon) ---
    for k = 1:opt.Horizon
         % --- SOCP Power Flow (FLAW 4) ---
         SpConstraints = [SpConstraints, Grid.P_in(:,k) == -Grid.finc*Grid.P_br(:,k) + Grid.inc*Grid.P_br(:,k)]; 
         SpConstraints = [SpConstraints, Grid.Q_in(:,k) == -Grid.finc*Grid.Q_br(:,k) + Grid.inc*Grid.Q_br(:,k)]; 
         
         SpConstraints = [SpConstraints, Grid.P_in(:,k) + ...
             Grid.PV_PIncMatrix.*(Grid.PV(:,k)) + ...
             Grid.windIncMatrix.*(Grid.wind_p(:,k)) + ...
             Bat.batIncMatrix.*(Bat.Pbatt_dis(:,k)) + ...
             Grid.powerfcIncMatrix.*(Grid.Pfc(:,k)) + ...
             CHP.CHPIncMatrix.*(Grid.Pshed(:,k)) ... % Slack bus
             == Grid.Pload(:,k) + ...
             heat.powerHeatpumpIncMatrix.*(heat.hp_in(:,k)) + ...
             Bat.batIncMatrix.*(Bat.Pbatt_ch(:,k)) + ...
             Grid.powerelezIncMatrix.*(Grid.Pelez(:,k)) + ...
             Grid.EVCSIncMatrix.*Grid.EV_load(1,k)]; 
         
         SpConstraints = [SpConstraints, Grid.Q_in(:,k) + CHP.CHPIncMatrix.*(Grid.Qshed(:,k)) ...
             == Grid.Qload(:,k)];
         
         SpConstraints = [SpConstraints, Grid.V(NET.zK,k) == Grid.V(NET.vK,k) ...
             - 2*(Grid.R_Line.*Grid.P_br(:,k) + Grid.X_Line.*Grid.Q_br(:,k)) ...
             + (Grid.R_Line.^2 + Grid.X_Line.^2).*Grid.L(:,k)]; 
             
         for l = 1:ANZ.L
             SpConstraints = [SpConstraints, ...
                 cone([2*Grid.P_br(l,k); 2*Grid.Q_br(l,k); Grid.L(l,k)-Grid.V(NET.zK(l),k)], ...
                      (Grid.L(l,k)+Grid.V(NET.zK(l),k)))];
         end
         
         % --- Heat Network Constraints ---
         SpConstraints = [SpConstraints,heat.HeatFlowInBus.*heat.TmprtrBusDir(:,k)==heat.HeatFlowInMatrix*heat.TmprtrToDir(:,k)];
         SpConstraints = [SpConstraints,heat.HeatFlowOutIncMatrix*heat.TmprtrBusDir(:,k)==heat.TmprtrFromDir(:,k)];
         SpConstraints = [SpConstraints,heat.HeatFlowOutBus.*heat.TmprtrBusRev(:,k)==heat.HeatFlowOutMatrix*heat.TmprtrToRev(:,k),];
         SpConstraints = [SpConstraints,heat.HeatFlowInIncMatrix*heat.TmprtrBusRev(:,k)==heat.TmprtrFromRev(:,k)];
         SpConstraints = [SpConstraints,heat.HeatD(4:35,k)==heat.Cp.*heat.HeatFlowInBus(4:35,:).*(heat.TmprtrBusDir(4:35,k)-heat.TmprtrBusRev(4:35,k))];
         SpConstraints = [SpConstraints,heat.HeatSource(1,k)==heat.Cp.*heat.HeatFlowOutBus(1,:).*(heat.TmprtrBusDir(1,k)-heat.TmprtrBusRev(1,k))];
         SpConstraints = [SpConstraints,heat.HeatSource(:,k)==heat.SourceHeatpumpIncMatrix.*heat.hp_out(:,k)+heat.thIncMatrix.*heat.th_out(:,k)+Grid.SourceHeatfcIncMatrix.*Grid.Qfc(:,k)];
    end
    
    SpConstraints = [SpConstraints,heat.HeatD==heat.Heat_load+heat.thoutMatrix*heat.th_in];
    SpConstraints = [SpConstraints, 110<=heat.TmprtrToDir<=140];
    SpConstraints = [SpConstraints, 110<=heat.TmprtrFromDir<=140];
    SpConstraints = [SpConstraints,40<=heat.TmprtrToRev ];
    SpConstraints = [SpConstraints, 40<=heat.TmprtrFromRev];
    for i=1:heat.n_HeatBranch
        % *** DEBUG FIX: Index SituationTempreture ***
        SpConstraints = [SpConstraints,heat.TmprtrToRev(i,:) == heat.coefficient(i).*(heat.TmprtrFromRev(i,:)+heat.SituationTempreture)-heat.SituationTempreture];
        SpConstraints = [SpConstraints,heat.TmprtrToDir(i,:) == heat.coefficient(i).*(heat.TmprtrFromDir(i,:)+heat.SituationTempreture)-heat.SituationTempreture];
    end

    % --- Storage Constraints (Inter-temporal) ---
    for k=2:opt.Horizon
        % *** BATTERY FIX (FLAW 3) ***
        SpConstraints = [SpConstraints,Bat.bat_store(:,k)==(1-Bat.bat_decay)*Bat.bat_store(:,k-1)...
            + Bat.eta*(Bat.Pbatt_ch(:,k)) - (1/Bat.eta)*Bat.Pbatt_dis(:,k)]; 
        SpConstraints = [SpConstraints,heat.th_store(:,k)==(1-heat.th_decay)*heat.th_store(:,k-1)+(1-heat.th_loss)*(heat.th_in(:,k))-1/(1-heat.th_loss)*heat.th_out(:,k)];    
        % *** H2 BUG FIX ***
        SpConstraints = [SpConstraints,Grid.H2_store(:,k)==(1-H2.decay)*Grid.H2_store(:,k-1)+(1-H2.loss)*(Grid.h2ch(:,k))-1/(1-H2.loss)*Grid.h2dch(:,k)];          
    end            
    SpConstraints = [SpConstraints,sum(Bat.Pbatt_dis)-sum(Bat.Pbatt_ch)==0];
    SpConstraints = [SpConstraints,sum(heat.th_in)-sum(heat.th_out)==0];
    SpConstraints = [SpConstraints,sum(Grid.h2ch)-sum(Grid.h2dch)==0];

    %% --- Objective Function (Eq 2.5) ---
    % Investment Cost (C_inv)
    bat_inv  = Bat.battCapa(1,y).*cost.bat_capital_ann;
    hp_inv   = heat.hp_cap(1,y).*cost.hp_capital_ann;
    PV_inv   = Grid.pv_cap(1,y).*cost.pv_capital_ann;
    TH_inv   = heat.th_Capa(1,y).*cost.th_capital_ann;
    ELEZ_inv = Grid.ELEZ_cap(1,y).*cost.ELEZ_capital_ann;
    fc_inv   = Grid.fc_cap(1,y).*cost.fc_capital_ann;
    H2_inv  =  Grid.H2_Capa(1,y).*cost.H2_capital_ann;
    wind_inv   = Grid.wind_cap(1,y).*cost.wind_capital_ann;
    Inv = bat_inv+PV_inv+hp_inv+TH_inv+fc_inv+ELEZ_inv+wind_inv+H2_inv;

    % Operational Cost (C_op) (Eq 2.7)
    Grid_ope= sum(Grid.Pshed(1,:).*cost.price);
    
    % *** O&M FIX (FLAW 1) ***
    Op_cost_DERs = (Bat.battCapa(1,y)*cost.bat_op_cost) + ...
                   (heat.hp_cap(1,y)*cost.hp_op_cost) + ...
                   (Grid.pv_cap(1,y)*cost.pv_op_cost) + ...
                   (heat.th_Capa(1,y)*cost.th_op_cost) + ...
                   (Grid.ELEZ_cap(1,y)*cost.ELEZ_op_cost) + ...
                   (Grid.fc_cap(1,y)*cost.fc_op_cost) + ...
                   (Grid.H2_Capa(1,y)*cost.H2_op_cost) + ...
                   (Grid.wind_cap(1,y)*cost.wind_op_cost);
    
    sub_pro = Grid_ope + Op_cost_DERs;

    % CO2 Penalty Cost (C_penalty,co2) (Eq 2.8)
    CO2_all_year = (sum(Grid.Pshed(1,:)) * cost.CO2grid_kg_per_kWh) * cost.cCO2_per_kg; 

    % Total Objective (Eq 2.5)
    Objective = Inv + sub_pro + CO2_all_year; 

    %% --- Solve Optimization ---
    ops = sdpsettings('solver','gurobi', 'verbose', 0);
    diagnostics = optimize(SpConstraints,Objective,ops);
    
    if diagnostics.problem ~= 0
        warning('Year %d (Deterministic) failed to solve: %s', y, diagnostics.info);
    end

    % --- Store Results ---
    Results_Grid.obj = value(Objective);
    Results_Grid.cap = value([Grid.pv_cap(1,y); Grid.wind_cap(1,y); ...
                              Bat.battCapa(1,y); heat.hp_cap(1,y); ...
                              heat.th_Capa(1,y) ;Grid.fc_cap(1,y); ...
                              Grid.ELEZ_cap(1,y); Grid.H2_Capa(1,y)]);
    Results_Grid.shed = value(Grid.Pshed);
    Results_Grid.pv = value(Grid.PV);
    Results_Grid.wind = value(Grid.wind_p); 
    Results_Grid.Pbatt_ch = value(Bat.Pbatt_ch);
    Results_Grid.Pbatt_dis = value(Bat.Pbatt_dis);
    Results_Grid.voltage = sqrt(value(Grid.V));
    Results_Grid.inv = value(Inv);
    Results_Grid.ope = value(sub_pro);
    Results_Grid.co2 = value(CO2_all_year);
end