function [p,YT_bm, YTS_bm] = CalcLtg(R, X, C, G)
% Diese Funktion dient der Berechnung von YT mehrerer Leitungen
% R - Widerstand einer Leitung
% X - Reaktanz einer Leitung
% C - Kapazität einer Leitung
% G - Ableitwiderstand einer Leitung
% YT_bm - Betriebsmitteladmittanzmatrix

%% Berechnung der Leitungsparameter
ya=0.5*(G+1j*2*pi*50*C);
yb=ya;
ym=1./(R+1j*X);
p=(ya+ym);
%P=(R+1j*X);
%% Bestimmung der Indizierung
n=2*numel(R);
indx1=[1:2:n 2:2:n];
indy1=indx1;
indx2=1:n;
indy2=2*ceil(.5:.5:n/2)+(mod(1:n,2)-1);

%% Aufstellen der Terminaladmittanzmatrizen
YT_bm=sparse([indx1 indx2],[indy1 indy2],[p;yb+ym;-ym(ceil(.5:.5:n/2))],n,n);
YTS_bm=sparse([indx1 indx2],[indy1 indy2],[ym;ym;-ym(ceil(.5:.5:n/2))],n,n);
