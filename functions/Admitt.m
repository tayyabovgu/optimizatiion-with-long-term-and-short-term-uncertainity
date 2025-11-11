function [NET,indK]=Admitt(BRANCH,ANZ,NOD,LIN,TRA,SWT,mpc)
% This function takes the processed BRANCH struct and calculates
% the network admittance matrix (YKK) and topology (NET).

% create from node and to node vectors
MAT=BRANCH.Ges;
MATNam=BRANCH.GesNam;
MATNam=MATNam(MAT(:,6)==1,:);
MAT=MAT(MAT(:,6)==1,:);
MATNam=MATNam(MAT(:,3)==1,:);
MAT=MAT(MAT(:,3)==1,:);
MATNam((MAT(:,5)==4)&(MAT(:,7)==0),:)=[];
MAT((MAT(:,5)==4)&(MAT(:,7)==0),:)=[];
posL=unique(MAT((MAT(:,5)==1)&(MAT(:,7)==0),1));
for l=1:size(posL,1)
    MATNam((MAT(:,5)==1)&(MAT(:,1)==posL(l,1)),:)=[];
    MAT((MAT(:,5)==1)&(MAT(:,1)==posL(l,1)),:)=[];
end
clear posL l;
posTr=unique(MAT((MAT(:,5)==2)&(MAT(:,7)==0),1));
for tr=1:size(posTr,1)
    MATNam((MAT(:,5)==2)&(MAT(:,1)==posTr(tr,1)),:)=[];
    MAT((MAT(:,5)==2)&(MAT(:,1)==posTr(tr,1)),:)=[];
end
clear posTr tr;
vK=MAT(MAT(:,4)==1,2);
zK=MAT(MAT(:,4)==2,2);
NET.vK=vK;
NET.zK=zK;

%% calculate KKT
KKT=sparse([vK zK]',1:2*size(vK,1),1,ANZ.K,2*size(vK,1));
clear vK zK;

%% calculate Terminal Admittance Matrix
% (This section is complex and specific to your original author's method)
if ANZ.L>0
    posL=unique(MAT(MAT(:,5)==1,1));
    anzL=size(posL,1);
    % Using per-unit values based on mpc.Zbase
    [P,YTL,YTLS]=CalcLtg((LIN.r(posL,1).*LIN.l(posL,1))./mpc.Zbase,...
        (LIN.x(posL,1).*LIN.l(posL,1))./mpc.Zbase,...
        (LIN.c(posL,1).*LIN.l(posL,1)*1e-9)./mpc.Zbase,(zeros(anzL,1))./mpc.Zbase);
    clear posL anzL;
else
    YTL=[];
    YTLS=[];
    P = []; % Ensure P exists
end
if ANZ.Tr>0
    posTr=unique(MAT(MAT(:,5)==2,1));
    anzTr=size(posTr,1);
    YTT=CalcTra(TRA.SrT(posTr,1)*1e6,TRA.UrTOS(posT,1)*1e3/sqrt(3),TRA.UrTUS(posTr,1)*1e3/sqrt(3),TRA.uk(posTr,1),TRA.Pk(posTr,1)/1e3,TRA.P0(posTr,1)/1e3,TRA.I0(posTr,1),zeros(anzTr,1));
    clear posTr anzTr;
else
    YTT=[];
end
if ANZ.S>0
    posS=unique(MAT(MAT(:,5)==3,1));
    anzS=size(posS,1);
    YTSW=CalcLtg(zeros(anzS,1),SWT.X(posS,1),zeros(anzS,1),zeros(anzS,1));
    clear posS anzS;
else
    YTSW=[];
end
YT=blkdiag(YTL,YTT,YTSW);
YTS=blkdiag(YTLS,YTT,YTSW);
clear YTL YTLS YTT YTSW;

%% identify islanded grid parts
% (This also requires helper functions CalcLtg, CalcTra, and TN)
% Assuming they are in your /functions/ folder
tn=TN(-KKT*YTS*KKT');
nn=cellfun(@numel,tn);
nn=find(nn==max(nn),1,'first');
indK=tn{nn};
KKT=KKT(indK,:);
indT=sum(KKT,1)>0;
indL=indT(1:2:end) & indT(2:2:end);
indT(1:2:end)=indL;indT(2:2:end)=indL;
KKT=KKT(:,indT);
YT=YT(:,indT);
YT=YT(indT,:);
clear tn nn;
MAT=MAT(indT,:);
MATNam=MATNam(indT,:);

%% define Node Admittance Matrix
YKK=-KKT*YT*KKT';
NET.KKT=KKT;
NET.KKT1=full(KKT);
NET.YKK=YKK;
NET.YT=YT;
NET.YTS=YTS;
NET.i=indK;
NET.Z=P;
clear KKT YKK YT YTS;
end