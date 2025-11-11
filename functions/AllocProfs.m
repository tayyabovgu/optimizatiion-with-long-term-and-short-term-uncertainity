function [NOD,PROF]=AllocProfs(GEN,LOAD,PROF,ANZ,NOD,EV)

%
% Input: GEN - struct with generation information
%        LOAD - struct with load information
%        PROF - struct with profile information
%        ANZ - struct with number of elements information
%        NOD - struct with node information
%
% Output: NOD - struct with extended node information
%         PROF - struct with extended profile information
%

%% define general variables
NOD.PLoadProf=zeros(ANZ.K,ANZ.tmax);                                        % nodal active power load profiles
NOD.PGenProf=zeros(ANZ.K,ANZ.tmax);                                         % nodal active power generation profiles
NOD.QLoadProf=zeros(ANZ.K,ANZ.tmax);                                        % nodal reactive power load profiles
NOD.QGenProf=zeros(ANZ.K,ANZ.tmax);                                         % nodal reactive power generation profiles
NOD.EV=zeros(ANZ.K,ANZ.tmax); 
NOD.EV1=zeros(ANZ.K,ANZ.tmax);
%% convert variables
PROF.PGenProf1=cell2mat(PROF.PGenProf);                                      % convert active power generation cell --> double
PROF.QGenProf1=cell2mat(PROF.QGenProf);                                      % convert reactive power generation cell --> double

%% generation profiles
if ANZ.E>0                                                                  % IF generation data exists
    for e=1:ANZ.E                                                           % LOOP over all generators
        % general parameters
        ProfNam=GEN.ProfNam{e,1};                                           % extract profile name of the e-th generator 
        Node=GEN.KNam{e,1};                                                 % extract installation node of the e-th generator
        % active power
        pos=find(strcmp(PROF.PGenProfNam,ProfNam));                         % find profile name position in all profiles
        if isempty(pos)~=1                                                  % IF profile name exists
            NOD.PGenProf(strcmp(NOD.KNam,Node)==1,:)=...
                NOD.PGenProf(strcmp(NOD.KNam,Node)==1,:)+...
               GEN.PNenn(e,1)*PROF.PGenProf1(:,pos).';                  % add the generator profile to the corresponding node profile
        else                                                                % ELSE
            disp('Profile name does not exist');                            % error hint
            keyboard                                                        % stop code execution
        end                                                                 % ENDIF
        % reactive power
        pos=find(strcmp(PROF.QGenProfNam,ProfNam));                         % find profile name position in all profiles
        if isempty(pos)~=1                                                  % IF profile name exists
            NOD.QGenProf(strcmp(NOD.KNam,Node)==1,:)=...
                NOD.QGenProf(strcmp(NOD.KNam,Node)==1,:)+...
                GEN.Q(e,1)*PROF.QGenProf1(:,pos).';                      % add the generator profile to the corresponding node profile
        else                                                                % ELSE
            disp('Profile name does not exist');                            % error hint
            keyboard                                                        % stop code execution
        end                                                                 % ENDIF
    end                                                                     % ENDLOOP
end                                                                         % ENDIF

%% load profiles
if ANZ.La>0                                                                 % IF load data exists
    for l=1:ANZ.La                                                          % LOOP over all loads
        % general parameters
        Nam=LOAD.LaNam{l,1};                                                % extract load name of the l-th load
        Node=LOAD.KNam{l,1};                                                % extract installation node of the l-th load
        % active power
        pos=find(strcmp(PROF.PLaNam,Nam));                                  % find load position in the load type vector
        if isempty(pos)~=1                                                  % IF load exists in load type vector
            Profs=PROF.PLaProfInd{1,pos};                                   % extract load type entry
            if isnan(Profs)~=1                                              % IF load type entry exists
                if isa(Profs,'double')==1                                   % IF load type entry is "double" value
                    if Profs==75 || Profs==76                               % IF load type type 75/76 (business/industry)
                        NOD.PLoadProf(strcmp(NOD.KNam,Node)==1,:)=...
                            NOD.PLoadProf(strcmp(NOD.KNam,Node)==1,:)+...
                            LOAD.P(l,1)*PROF.LProfs(:,Profs).'/1e3;         % add load profile to the corresponding node profile
                    else                                                    % ELSE
                        NOD.PLoadProf(strcmp(NOD.KNam,Node)==1,:)=...
                            NOD.PLoadProf(strcmp(NOD.KNam,Node)==1,:)+...
                            LOAD.P(l,1)*PROF.LProfs(:,Profs).'/1e3;              % add load profile to the corresponding node profile
                    end                                                     % END
                else                                                        % ELSE
                    hilf=strfind(Profs,' ');                                % find spaces in the load type entry
                    for p=1:size(hilf,2)                                    % LOOP over all entries 
                        if p==size(hilf,2)                                  % IF p==pend
                            prof=str2double(Profs(hilf(p)+1:end));          % extract the last element of the load type entry
                        else                                                % ELSE
                            prof=str2double(Profs(hilf(p)+1:hilf(p+1)-1));  % extract the element between two spaces
                        end                                                 % ENDIF
                        NOD.PLoadProf(strcmp(NOD.KNam,Node)==1,:)=...
                            NOD.PLoadProf(strcmp(NOD.KNam,Node)==1,:)+...
                            LOAD.P(l,1)*PROF.LProfs(:,prof).'/1e3;              % add load profile to the corresponding node profile
                    end                                                     % ENDLOOP
                end                                                         % ENDIF
            end                                                             % ENDIF
        else                                                                % ELSE
            disp('no correspondig load types exist');                       % error hint
            keyboard;                                                       % stop code execution
        end                                                                 % ENDIF
        % reactive power
        pos=find(strcmp(PROF.QLaNam,Nam));                                  % find load position in the load type vector
        if isempty(pos)~=1                                                  % IF load exists in load type vector
            Profs=PROF.QLaProfInd{1,pos};                                   % extract load type entry
            if isnan(Profs)~=1                                              % IF load type entry exists
                if isa(Profs,'double')==1                                   % IF load type entry is "double" value
                    if Profs==75 || Profs==76                               % IF load type type 75/76 (business/industry)
                        NOD.QLoadProf(strcmp(NOD.KNam,Node)==1,:)=...
                            NOD.QLoadProf(strcmp(NOD.KNam,Node)==1,:)+...
                            LOAD.Q(l,1)*PROF.LProfs(:,Profs).'/1e3;         % add load profile to the corresponding node profile
                    else                                                    % ELSE
                        NOD.QLoadProf(strcmp(NOD.KNam,Node)==1,:)=...
                            NOD.QLoadProf(strcmp(NOD.KNam,Node)==1,:)+...
                            LOAD.Q(l,1)*PROF.LProfs(:,Profs).'/1e3;             % add load profile to the corresponding node profile
                    end                                                     % ENDIF
                else                                                        % ELSE
                    hilf=strfind(Profs,' ');                                % find spaces in the load type entry
                    for p=1:size(hilf,2)                                    % LOOP over all entries
                        if p==size(hilf,2)                                  % IF p==pend
                            prof=str2double(Profs(hilf(p)+1:end));          % extract the last element of the load type entry
                        else                                                % ELSE
                            prof=str2double(Profs(hilf(p)+1:hilf(p+1)-1));  % extract the element between two spaces
                        end                                                 % ENDIF
                        NOD.QLoadProf(strcmp(NOD.KNam,Node)==1,:)=...
                            NOD.QLoadProf(strcmp(NOD.KNam,Node)==1,:)+...
                            LOAD.Q(l,1)*PROF.LProfs(:,prof).'/1e3;              % add load profile to the corresponding node profile
                    end                                                     % ENDLOOP
                end                                                         % ENDIF
            end                                                             % ENDIF
        end                                                                 % ENDIF
    end                                                                     % ENDLOOP
end                                          % ENDIF
% 
% Ev charging station
 %if EV=1
% ii=1;
% for l=1:ANZ.La                                                          % LOOP over all loads
%     Nam=LOAD.LaNam{l,1};                                                % extract load name of the l-th load
%     Node=LOAD.KNam{l,1};                                                % extract installation node of the l-th load
%         % active power
%     pos=find(strcmp(PROF.PLaNam,Nam));                                  % find load position in the load type vector
%     if isempty(pos)~=1                                                  % IF load exists in load type vector
%         Profs=LOAD.EV(pos);                                   % extract load type entry
%         if Profs==1                                              % IF load type entry exists
%          NOD.PLoadProf(strcmp(NOD.KNam,Node)==1,:)= NOD.PLoadProf(strcmp(NOD.KNam,Node)==1,:) + PROF.EVprivate_LP(ii,:);
%          ii=ii+1;
%         end
%     end
% end
% end
end