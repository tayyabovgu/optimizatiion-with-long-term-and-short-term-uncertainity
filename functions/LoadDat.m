%% LoadDat.m
% Matlab-Script to load grid data
% output variables:
% NOD - struct with node information
% LIN - struct with line information
% TRA - struct with transformer information
% SWT - struct with switch information
% GEN - struct with generation information
% PROF - struct with profile data
% ANZ - struct with information regarding number of elements
if exist(path.dat_mat,'file')==0                                  % IF *.mat is not existing  
    %% load grid data
         %% load grid data
        % Nodes
        [~,~,Gesamt]=xlsread(path.net_xlsx,'Knoten');                       
        if size(Gesamt,1)>1                                                 
            NOD.StatL=Gesamt(2:end,1);                                     % station long name
            NOD.StatB=Gesamt(2:end,2);                                     % station description
            NOD.KNam=Gesamt(2:end,3);                                      % node name
            NOD.KTyp=cell2mat(Gesamt(2:end,4));                            % node type
            NOD.uKn=cell2mat(Gesamt(2:end,5));                             % nominal voltage in V
            ANZ.K=size(NOD.KNam,1);                                        % number of nodes
        else                                                                
            ANZ.K=0;                                                       % number of nodes is equal to 0
            NOD=struct;
        end                                                                 
        % Lines
        [~,~,Gesamt]=xlsread(path.net_xlsx,'Leitungen');                    
        if size(Gesamt,1)>1                                                
            LIN.LtgNam=Gesamt(2:end,1);                                    % line name
            LIN.vKNamHilf=Gesamt(2:end,2);                                 % name from node
            LIN.zKNamHilf=Gesamt(2:end,3);                                 % name to node
            LIN.vKStatHilf=Gesamt(2:end,4);                                % status from node (disconnector)
            LIN.zKStatHilf=Gesamt(2:end,5);                                % status to node (disconnector)
            LIN.StatLS=Gesamt(2:end,6);                                    % status of circuit breakers
            LIN.StatE=Gesamt(2:end,7);                                     % status of earth connection
            LIN.l=cell2mat(Gesamt(2:end,8));                               % line length in km
            LIN.r=cell2mat(Gesamt(2:end,9));                               % resistance in Ohm/km
            LIN.x=cell2mat(Gesamt(2:end,10));                              % reactance in Ohm/km
            LIN.c=cell2mat(Gesamt(2:end,11));                              % capacitance in nF/km
            LIN.Imax=cell2mat(Gesamt(2:end,13));                           % maximum current in kA
            ANZ.L=size(LIN.LtgNam,1);                                      % number of lines
        else                                                                
            ANZ.L=0;                                                       % number of lines is equal to 0
            LIN=struct;
        end                                                                 
        % Transformers
        [~,~,Gesamt]=xlsread(path.net_xlsx,'Trafos');                       
        if size(Gesamt,1)>1                                                 
            TRA.TrNam=Gesamt(2:end,1);                                     % transformer name
            TRA.vKNamHilf=Gesamt(2:end,2);                                 % name from node
            TRA.zKNamHilf=Gesamt(2:end,3);                                 % name to node
            TRA.vKStatHilf=Gesamt(2:end,4);                                % status from node (disconnector)
            TRA.zKStatHilf=Gesamt(2:end,5);                                % status to node (disconnector)
            TRA.StatLS=Gesamt(2:end,6);                                    % status of circuit breakers
            TRA.StatE=Gesamt(2:end,7);                                     % status of earth connection
            TRA.UrTOS=cell2mat(Gesamt(2:end,8));                           % primary voltage in kV
            TRA.UrTUS=cell2mat(Gesamt(2:end,9));                           % secondary voltage in kV
            TRA.SrT=cell2mat(Gesamt(2:end,10));                            % nominal apparent power in MVA
            TRA.uk=cell2mat(Gesamt(2:end,11));                             % relative short circuit voltage in %
            TRA.Pk=cell2mat(Gesamt(2:end,12));                             % short circuit losses in kW
            TRA.P0=cell2mat(Gesamt(2:end,13));                             % no-load losses in kW
            TRA.I0=cell2mat(Gesamt(2:end,14));                             % no-load current in %
            ANZ.Tr=size(TRA.TrNam,1);                                      % number of transformers
        else                                                                   
            ANZ.Tr=0;                                                      % number of transformers is equal to 0
            TRA=struct;
        end                                                                     
        % Switches
        [~,~,Gesamt]=xlsread(path.net_xlsx,'Schalter');                     
        if size(Gesamt,1)>1                                                
            SWT.SwNam=Gesamt(2:end,1);                                     % switch name
            SWT.vKNamHilf=Gesamt(2:end,2);                                 % name from node
            SWT.zKNamHilf=Gesamt(2:end,3);                                 % name to node
            SWT.vKStatHilf=Gesamt(2:end,4);                                % status from node
            SWT.zKStatHilf=Gesamt(2:end,5);                                % status to node
            SWT.X=cell2mat(Gesamt(2:end,6));                               % reactance in Ohm
            SWT.Stat=cell2mat(Gesamt(2:end,7));                            % switching state
            ANZ.S=size(SWT.SwNam,1);                                       % number of switches
        else                                                                
            ANZ.S=0;                                                       % number of switches is equal to 0
            SWT=struct;
        end                                                                 
        % Generation
        if Scenario==1
            [~,~,Gesamt]=xlsread(path.net_xlsx,'Erzeugung');               % read generation data
        elseif Scenario==2||Scenario==3||Scenario==4
            [~,~,Gesamt]=xlsread(path.net_xlsx,'Erzeugung_25');    
        else
             [~,~,Gesamt]=xlsread(path.net_xlsx,'Erzeugung_30'); 
        end
        if size(Gesamt,1)>1                                                % IF generation data exists
        GEN.GenNam=Gesamt(2:end,1);                                        % generation name
        GEN.KNam=Gesamt(2:end,2);                                          % node name
        GEN.PNenn=cell2mat(Gesamt(2:end,3));                               % active power in MW
        GEN.Q=cell2mat(Gesamt(2:end,4));                                   % reactive power in Mvar
        GEN.ProfNam=Gesamt(2:end,5);                                       % Profile Name
        ANZ.E=size(GEN.GenNam,1);                                          % number of generations
        else                                                               
            ANZ.E=0;                                                       % number of generations is equal to 0
            GEN=struct;
        end                                                                 
                                                                   
        % Loads
        [~,~,Gesamt]=xlsread(path.net_xlsx,'Last');                             
        if size(Gesamt,1)>1                                                     
            LOAD.LaNam=Gesamt(2:end,1);                                    % load name
            LOAD.KNam=Gesamt(2:end,2);                                     % node name
            LOAD.P=cell2mat(Gesamt(2:end,3));                              % active power in W
            LOAD.Q=cell2mat(Gesamt(2:end,4));
            ANZ.La=size(LOAD.LaNam,1);  
            % reactive power in var
            LOAD.EV=cell2mat(Gesamt(2:end,12));
            %LOAD.HP=cell2mat(Gesamt(2:end,22));
            ANZ.EV=sum(LOAD.EV);
        else                                                                
            ANZ.La=0;                                                      % number of loads is equal to 0
            LOAD=struct;
        end
       %% load profile data
    % generation (P)
    [~,~,Gesamt]=xlsread(path.prof_xlsx,'GEN_P');                           % active power generation
    PROF.PGenProfNam=Gesamt(1,1:end);                                       % generation names
    PROF.PGenProf=Gesamt(2:end,1:end);                                      % generation profiles
    % generation (Q)
    [~,~,Gesamt]=xlsread(path.prof_xlsx,'GEN_Q');                           % reactive power generation
    PROF.QGenProfNam=Gesamt(1,1:end);                                       % generation names
    PROF.QGenProf=Gesamt(2:end,1:end);                                      % generation profiles
    % load (P)
    [~,~,Gesamt]=xlsread(path.prof_xlsx,'LOAD_P');                          % active power load
    PROF.PLaNam=Gesamt(1,1:end);                                            % load names
    PROF.PLaProfInd=Gesamt(2,1:end);% load profiles
    % load (Q)
    [~,~,Gesamt]=xlsread(path.prof_xlsx,'LOAD_Q');                          % reactive power load
    PROF.QLaNam=Gesamt(1,1:end);                                            % load names
    PROF.QLaProfInd=Gesamt(2,1:end);                                        % load profiles
    profile=load('LoadProfiles.mat');                                       % load profile file
    PROF.LProfsInit=profile.profile;% resave load profiles
        %LP=EV_load;
        %PROF.LProfsInitEV=LP;
    clearvars Gesamt;                                                       % load not necessary variables
        %% Allgemeine Parameter bestimmen
        ANZ.Te=ANZ.L+ANZ.Tr+ANZ.S;                                          % number of terminals
        ANZ.tmax=size(PROF.PGenProf,1);                                     % number of time steps
        %% Datei speichern
        save(path.dat_mat,'ANZ','GEN','LIN','LOAD','NOD','PROF','TRA','SWT'); % save *.mat
    else                                                                    
        load(path.dat_mat);                                                 % load *.mat
    end
