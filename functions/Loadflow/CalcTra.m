function [Y]=CalcTra(SrT,UrTOS,UrTUS,uk,Pk,P0,I0,k)

%% Bestimmung der Basisparameter
aTr=size(SrT,1);

%% Berechnung der Tranformatorparameter
IrT=SrT/3./UrTOS;
R=Pk/3./IrT.^2;
X=(uk/100).*(UrTOS.^2)./SrT;
YA=2./(R+1i*X);
YB=YA;
Xh=(UrTOS.^2)./(I0/100.*SrT);
Xh(Xh==Inf,1)=0;
Rfe=UrTOS.^2./P0;
Rfe(Rfe==Inf,1)=0;
YM=(Rfe+1i*Xh)./(Rfe.*1i.*Xh);
YM(isnan(YM),1)=0;
% RL=(ur/100).*UrTOS.^2./SrT;
% ux=sqrt((uk/100).^2-(ur/100).^2);
% XL=ux.*UrTOS.^2./SrT;
% 
% RA=RL/2;
% XA=XL/2;
% 
% YA=1./(RA+1i*XA);
% YB=YA;
% 
Ys=1./(YA+YB+YM);

%% Berücksichtigung des Übersetzungsverhältnis
g=UrTOS./UrTUS.*exp(1i*k*pi/6);

%% Aufstellen der Knotenadmittanzmatrix
Y=zeros(4*aTr,1);

Y(1:4:4*aTr-3,1)=Ys.*(YA.*(YB+YM));
Y(2:4:4*aTr-2,1)=Ys.*(-conj(g).*YA.*YB);
Y(3:4:4*aTr-1,1)=Ys.*(-g.*YA.*YB);
Y(4:4:4*aTr,1)=Ys.*(abs(g).^2.*YB.*(YA+YM));

Y=reshape(Y,2,2,aTr);
Y=num2cell(Y,[1 2]);
Y=squeeze(Y);
Y=sparse(blkdiag(Y{:,1}));