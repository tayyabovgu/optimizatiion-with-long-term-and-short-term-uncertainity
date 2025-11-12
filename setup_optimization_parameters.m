function [cost, Grid, Bat, heat, CHP, opt, ANZ, NET, mpc, NOD, PROF, LIN, H2] = setup_optimization_parameters(opt, path, SetC, Scenario, EV)
    %% Load Data
    assignin('base', 'Scenario', Scenario);
    assignin('base', 'EV', EV); 
    run(fullfile(path.dat1, 'LoadDat.m'));
    %% Interpolate Profiles
    PROF = InterpDat(PROF, ANZ, SetC); 
    %% Allocate Profiles
    [NOD, PROF] = AllocProfs(GEN, LOAD, PROF, ANZ, NOD, EV);
    
    %% PARAMET
    opt.scenarios = 1;
    mpc.Vbase=0.4*1e3;
    mpc.baseMVA=0.630*1e6;
    mpc.Zbase=mpc.Vbase.^2 /mpc.baseMVA;
    mpc.Ibase=mpc.Vbase /mpc.Zbase;
    %% Create Network Topology
    BRANCH = EditBranch(ANZ,NOD,LIN,TRA,SWT);
    [NET,indK] = Admitt(BRANCH,ANZ,NOD,LIN,TRA,SWT,mpc);
    
    %% tariff
    cost.penalty1 =0.11;
    cost.choose_tarrif=2;
    cost.WT = wtarrifs(NOD.PLoadProf, 8760); % Always load full 8760 tariff
    cost.price_8760 = cost.WT(1,1:8760)./100;  
    %% wind system
    load(fullfile(path.wind, 'wind.mat'), 'wind');
    Grid.wind_8760 = wind(1:8760)'.*0.5; % [1 x 8760]
    Grid.N_wind=1;
    Grid.windIncMatrix= zeros(ANZ.K,Grid.N_wind);
    wind_C = [1];
    Grid.windIncMatrix(wind_C (1,1),1) = 1;
    Grid.wind_p=sdpvar(1,opt.Horizon);
    Grid.wind_q=sdpvar(1,opt.Horizon); 
    Grid.wind_cap=sdpvar(1,opt.Period);
    %% PV syastem
    Grid.pv_irradiation_8760 = PROF.PGenProf1(1:8760)'; % [1 x 8760]
    Grid.N_PV=1;
    Grid.PV_PIncMatrix= zeros(ANZ.K,Grid.N_PV);
    Grid.PV_P = [1];
    Grid.PV_PIncMatrix(Grid.PV_P(1,1),1) = 1;
    Grid.PV=sdpvar(1,opt.Horizon);
    Grid.PV_q=sdpvar(1,opt.Horizon); 
    Grid.pv_cap=sdpvar(1,opt.Period);
    %% grid model
    Grid.Pload_8760  = ((NOD.PLoadProf(:,1:8760))); % [35 x 8760]
    Grid.Qload_8760  = (NOD.QLoadProf(:,1:8760)); % [35 x 8760]
    Grid.V      = sdpvar(ANZ.K,opt.Horizon); 
    Grid.L      = sdpvar(ANZ.L,opt.Horizon); 
    Grid.P_br   = sdpvar(ANZ.L, opt.Horizon); 
    Grid.Q_br   = sdpvar(ANZ.L, opt.Horizon); 
    Grid.R_Line      = (LIN.l(1:ANZ.L).*LIN.r(1:ANZ.L)); 
    Grid.X_Line      = (LIN.l(1:ANZ.L).*LIN.x(1:ANZ.L)); 
    Grid.P_in=sdpvar(ANZ.K,opt.Horizon); 
    Grid.Q_in=sdpvar(ANZ.K,opt.Horizon); 
    Grid.P_import = sdpvar(1,opt.Horizon); 
    Grid.Q_import = sdpvar(1,opt.Horizon); 
    Grid.P_import_cap = sdpvar(1,opt.Period); 
    Grid.inc=full(sparse(NET.vK',1:size(NET.vK,1),1,ANZ.K,size(NET.vK,1)));
    Grid.finc=full(sparse(NET.zK',1:size(NET.zK,1),1,ANZ.K,size(NET.zK,1)));
    Grid.slack_bus_idx = 1; 
    Grid.P_import_IncMatrix = zeros(ANZ.K, 1);
    Grid.Q_import_IncMatrix = zeros(ANZ.K, 1);
    Grid.P_import_IncMatrix(Grid.slack_bus_idx) = 1;
    Grid.Q_import_IncMatrix(Grid.slack_bus_idx) = 1;
    %%  Battery 
    N_bat=1;
    Bat.bat_decay=0.001;
    Bat.eta = 0.95; 
    Bat.battCapa =sdpvar(N_bat,opt.Period);
    Bat.battChargeOrNot = binvar(2,opt.Horizon);
    Bat.Pbatt_ch = sdpvar(N_bat,opt.Horizon);  
    Bat.Pbatt_dis = sdpvar(N_bat,opt.Horizon);  
    Bat.Qbatt = sdpvar(N_bat,opt.Horizon); 
    Bat.bat_store = sdpvar(N_bat,opt.Horizon);
    Bat.bat_store(N_bat,1)=0;
    Bat.batIncMatrix = zeros(ANZ.K,N_bat);
    bat_gen = [1];
    Bat.batIncMatrix(bat_gen(1,1),1) = 1;
    %% heating netwrok modelling
    load(path.space_heating, 'space_heat_minute');
    load(path.water_heating, 'water_heat_minute');
    heat.heat_load=((space_heat_minute).*4);
    PROF.Hload=InterpDat_heat(heat.heat_load,ANZ,SetC);
    
    % *** HEAT LOAD FIX (v23) ***
    heat.Hload_8760=PROF.Hload(1:8760); % [1 x 8760] row vector
    
    N_th=1;
    heat.th_decay=0.01;
    heat.th_loss=0.1;
    heat.th_Capa =sdpvar(N_th,opt.Period);
    heat.th_in=sdpvar(N_th,opt.Horizon);
    heat.th_out=sdpvar(N_th,opt.Horizon);
    heat.th_store=sdpvar(N_th,opt.Horizon);
    heat.thChargeOrNot=binvar(2,opt.Horizon);
    heat.th_store(N_th,1)=0;
    n_T=opt.Horizon;
    heat.HeatBranch=xlsread(path.heat_xlsx,'Branch');
    heat.HeatBus=xlsread(path.heat_xlsx,'Bus');
    heat.HeatBranch(:,4) =heat.HeatBranch(:,4);
    heat.n_HeatBranch = size(heat.HeatBranch,1);
    heat.n_HeatBus = size(heat.HeatBus,1);
    heat.TmprtrFromDir = sdpvar(heat.n_HeatBranch, n_T);  
    heat.TmprtrToDir = sdpvar(heat.n_HeatBranch, n_T);   
    heat.TmprtrFromRev = sdpvar(heat.n_HeatBranch, n_T);  
    heat.TmprtrToRev = sdpvar(heat.n_HeatBranch, n_T);    
    heat.TmprtrBusDir = sdpvar(heat.n_HeatBus,n_T);      
    heat.TmprtrBusRev = sdpvar(heat.n_HeatBus,n_T);      
    heat.Cp = 4200/3600000;
    heat.SituationTempreture_daily = [-10 -10 -8.84 -9.42 -9.42 -9.42 -8.84 -8.26 -7.10 -6.52 -5.94 -5.35 -4.77 -4.77 -4.77 -5.35 -5.94 -6.52 -6.52 -6.52 -7.10 -7.68 -8.26 -8.26];
    heat.HeatD=sdpvar(heat.n_HeatBus,opt.Horizon);
    heat.N_HP=1;
    heat.HeatSource = sdpvar(heat.n_HeatBus,opt.Horizon);
    heat.hp_in=sdpvar(heat.N_HP,opt.Horizon);
    heat.hp_out=sdpvar(heat.N_HP,opt.Horizon);
    heat.hp_eff=3.2; 
    heat.HP_life_time=20; 
    heat.hp_cap=sdpvar(heat.N_HP,opt.Period);
    heat.powerHeatpumpIncMatrix= zeros(ANZ.K,heat.N_HP);
    heat.SourceHeatpumpIncMatrix=zeros(heat.n_HeatBus,heat.N_HP);
    heat.E_HP = [1 3]; 
    heat.SourceHeatpumpIncMatrix(heat.E_HP(1,1),1) = 1;
    heat.powerHeatpumpIncMatrix(heat.E_HP(1,2),1)=1;
    heat.thIncMatrix = zeros(heat.n_HeatBus,N_th);
    heat.thoutMatrix = zeros(heat.n_HeatBus,N_th);
    heat.th_gen = [3 1];
    heat.thIncMatrix(heat.th_gen(1,1),1) = 1;
    heat.thoutMatrix(heat.th_gen(1,2),1)=1;
    
    % *** HEAT LOAD FIX (v24) ***
    heat.Heat_load_Full=zeros(heat.n_HeatBus, 8760); 
    % Get the number of rows we need to fill
    n_heat_buses = sum(heat.HeatBus(:,2)==2); 
    % Repeat the [1 x 8760] vector 'n_heat_buses' times
    heat.Heat_load_Full((heat.HeatBus(:,2)==2),:)=repmat(heat.Hload_8760, n_heat_buses, 1);
    
    heat.HeatFlowInMatrix = zeros(heat.n_HeatBus,heat.n_HeatBranch);       
    heat.HeatFlowInIncMatrix = zeros(heat.n_HeatBranch,heat.n_HeatBus);    
    for i=1:heat.n_HeatBranch
        heat.HeatFlowInMatrix(heat.HeatBranch(i,3),i) = 1*heat.HeatBranch(i,4);
        heat.HeatFlowInIncMatrix(i,heat.HeatBranch(i,3)) = 1;
    end
    heat.HeatFlowInBus = heat.HeatFlowInMatrix*ones(heat.n_HeatBranch,1);   
    heat.HeatFlowOutMatrix = zeros(heat.n_HeatBus,heat.n_HeatBranch);       
    heat.HeatFlowOutIncMatrix = zeros(heat.n_HeatBranch,heat.n_HeatBus);    
    for i=1:heat.n_HeatBranch
        heat.HeatFlowOutMatrix(heat.HeatBranch(i,2),i) = 1*heat.HeatBranch(i,4);
        heat.HeatFlowOutIncMatrix(i,heat.HeatBranch(i,2)) = 1;
    end
    heat.HeatFlowOutBus = heat.HeatFlowOutMatrix*ones(heat.n_HeatBranch,1);
    heat.coefficient = zeros(heat.n_HeatBranch,1);
    for i = 1: heat.n_HeatBranch
       heat.coefficient(i) = exp(-heat.HeatBranch(i,8)*heat.HeatBranch(i,5)/heat.Cp/heat.HeatBranch(i,4)/100000);
    end
    %% Electrolyzer and fuel cell
    Grid.N_elez=1;
    elc_fc_lif_time=60000; 
    Grid.eleyr=elc_fc_lif_time/8760;
    Grid.elzcost=238; 
    Grid.Pelez=sdpvar(Grid.N_elez,opt.Horizon);
    Grid.ELEZ_cap=sdpvar(1,opt.Period);
    Grid.hLHV= 33.3; 
    Grid.Helz=sdpvar(Grid.N_elez,opt.Horizon);
    Grid.Pemeff= 0.60; 
    Grid.phloss=0.14; 
    Grid.pemyr=elc_fc_lif_time/8760;
    Grid.pemcost=5738; 
    Grid.h1=sdpvar(Grid.N_elez,opt.Horizon); 
    Grid.Pfc=sdpvar(Grid.N_elez,opt.Horizon);
    Grid.Qfc=sdpvar(Grid.N_elez,opt.Horizon); 
    Grid.fc_cap=sdpvar(1,opt.Period);
    Grid.Qfc_heat=sdpvar(Grid.N_elez,opt.Horizon); 
    Grid.powerelezIncMatrix= zeros(ANZ.K,Grid.N_elez);
    Grid.SourceHeatfcIncMatrix= zeros(heat.n_HeatBus,heat.N_HP);
    Grid.powerfcIncMatrix= zeros(ANZ.K,Grid.N_elez);
    E__elez = [4 1 1]; 
    Grid.powerelezIncMatrix(E__elez(1,1),1) = 1;
    Grid.powerfcIncMatrix(E__elez(1,2),1) = 1;
    Grid.SourceHeatfcIncMatrix(E__elez(1,3),1) = 1;
    %% hydrogen storage
    cost.H2_capital=150; 
    cost.HSyr=10; 
    H2.loss = 0.02; 
    H2.decay = 0.01; 
    Grid.H2ChargeOrNot = binvar(2,opt.Horizon);        
    Grid.H2_store=sdpvar(N_th,opt.Horizon);     
    Grid.h2ch=sdpvar(N_th,opt.Horizon);   
    Grid.h2dch=sdpvar(N_th,opt.Horizon);
    Grid.H2_Capa =sdpvar(N_th,opt.Period);
    Grid.H2_store(1,1)=0;
    %% CHP (REMOVED from paper's model)
    CHP.n_CHP=0; 
    CHP.P_CHP= sdpvar(1,opt.Horizon);
    CHP.Heat_CHP= sdpvar(1,opt.Horizon);
    CHP.SourceCHPheatIncMatrix = zeros(heat.n_HeatBus,1);
    CHP.P_CHP_cap=sdpvar(1,opt.Period);
    CHP.CHPIncMatrix = zeros(ANZ.K,1);
    %% EVCS
    Grid.EVCS_max=4; 
    Grid.EVCS_inc = [3]; 
    Grid.N_EVCS=1;
    Grid.EVCSIncMatrix= zeros(ANZ.K,Grid.N_EVCS);
    Grid.EVCSIncMatrix(Grid.EVCS_inc(1,1),1) = 1;
    Grid.alpha = sdpvar(1,opt.Period);   
    %% cost model (Annualized costs)
    cost.C_gas = 0.054; 
    cost.wind_capital_ann = 1460 / 20; 
    cost.pv_capital_ann = 800 / 20; 
    cost.bat_capital_ann = 528 / 8; 
    cost.th_capital_ann = 200 / 20; 
    cost.hp_capital_ann = 700 / 20; 
    cost.ELEZ_capital_ann = 238 / Grid.eleyr; 
    cost.EVCS_capital_ann = 10000 / 10; 
    cost.fc_capital_ann = 5738 / Grid.pemyr; 
    cost.H2_capital_ann = 150 / 10; 
    
    % *** O&M FIX (FLAW 1) ***
    cost.wind_op_cost = 1460 * 0.01;
    cost.pv_op_cost = 800 * 0.01;
    cost.bat_op_cost = 528 * 0.01;
    cost.th_op_cost = 200 * 0.01;
    cost.hp_op_cost = 700 * 0.01;
    cost.ELEZ_op_cost = 238 * 0.01;
    cost.fc_op_cost = 5738 * 0.01;
    cost.H2_op_cost = 150 * 0.01;
    cost.EVCS_op_cost = 10000 * 0.01;
    %% CO2 emission metrics (Eq 2.8)
    cost.CO2grid_kg_per_kWh = 0.325; 
    cost.cCO2_per_kg = 0.025; % Base price for 2021
    
    
    %% *** "REPRESENTATIVE DAY" AVERAGING FIX ***
    % This is the core logic that makes the model runnable
    if opt.Horizon == 24
        fprintf('   *** 24-HOUR MODE: Averaging all profiles... ***\n');
        
        avg_profile = @(data) mean(reshape(data, 24, 365), 2)';
        avg_profile_matrix = @(data) mean(reshape(data, size(data,1), 24, 365), 3);
        
        Grid.wind = avg_profile(Grid.wind_8760);
        Grid.pv_irradiation = avg_profile(Grid.pv_irradiation_8760);
        cost.price = avg_profile(cost.price_8760);
        
        Grid.Pload = avg_profile_matrix(Grid.Pload_8760);
        Grid.Qload = avg_profile_matrix(Grid.Qload_8760);
        heat.Hload = avg_profile_matrix(heat.Hload_8760); % This variable is not used, but good to have
        heat.Heat_load = avg_profile_matrix(heat.Heat_load_Full);
        
        heat.SituationTempreture = heat.SituationTempreture_daily;
        
        % Rename for consistency in the main function
        Grid.PV_irr = Grid.pv_irradiation; 
        
    else
        % This branch should not be used, as it leads to Out of Memory
        fprintf('   *** FULL 8760 MODE: Using 8760-hour data... ***\n');
        Grid.wind = Grid.wind_8760;
        Grid.pv_irradiation = Grid.pv_irradiation_8760;
        cost.price = cost.price_8760;
        Grid.Pload = Grid.Pload_8760;
        Grid.Qload = Grid.Qload_8760;
        heat.Hload = heat.Hload_8760;
        heat.Heat_load = heat.Heat_load_Full;
        
        heat.SituationTempreture = repmat(heat.SituationTempreture_daily, 1, 365);
        
        % Rename for consistency in the main function
        Grid.PV_irr = Grid.pv_irradiation;
    end
end
