function path=Allp(SetC)
%% Define Filepaths
path.dat1=fullfile(pwd,'functions');
path.dat=fullfile(path.dat1,'1_Files');                                           
path.netdat=fullfile(path.dat,'1_NetData');
path.profdat=fullfile(path.dat,'load_profiles');
path.matdat=fullfile(path.dat,'3_Matlab');
path.EV=fullfile(path.dat,'EV');
path.heating=fullfile(path.dat,'Heating');
path.MGrid=fullfile(path.dat,'MGrid');
path.tarrif=fullfile(path.dat,'tarrif');
path.tarrif=fullfile(path.dat,'powerflow');
path.EV=fullfile(path.dat,'EV');
path.wind=fullfile(path.dat,'wind');
    path.net_xlsx=fullfile(path.netdat,[SetC.netcase,'.xlsx']);
    path.prof_xlsx=fullfile(path.profdat,[SetC.netcase,'_prof.xlsx']);
    path.dat_mat=fullfile(path.matdat,[SetC.netcase,'.mat']);
    path.heat_xlsx=fullfile(path.heating,[SetC.netcase,'_heatgrid.xlsx']);
    path.loadprofiles=fullfile(path.profdat,'LoadProfiles.mat');
    path.space_heating=fullfile(path.heating,'space_heating.mat'); 
    path.water_heating=fullfile(path.heating,'water_heating.mat');
    path.turbinechars=fullfile(path.wind,'turbinechars.xlsx');
    path.windspeeds=fullfile(path.wind,'windspeeds.xlsx');
end