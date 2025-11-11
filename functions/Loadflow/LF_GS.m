function [result,z] = LF_GS(YKK,S,uKn,Slack,eps)
% Eingangsvariablen:
% YKK 	- Knotenadmittanzmatrix 	(Dimension: Knotenanzahl x Knotenanzahl)
% S 	- Scheinleistung der Knoten (Verbraucherzählpfeilsystem, Dimension: Knotenanzahl x Zeitschritte)
% uKn 	- initiale Knotenspannungen (Dimension: Knotenanzahl x Zeitschritte)
% Slack - Knotennummer Slack 		(Dimension: 1x1)
% eps 	- Abbruchkriterium			(Dimension: 1x1)

K=size(uKn,1);

s=true(K,1);
s(Slack)=false;
YRR=YKK(s,s);
YSR=YKK(s,~s);

z=0;
dx=2*eps;

while dx>eps && z<500
    iK=conj(S(s,:)./uKn(s,:))/3;
    uR=YRR\(iK-YSR*uKn(Slack,:));
    dx=max(max(abs(uR-uKn(s,:))));
    uKn(s,:)=uR;
    z=z+1;
end;

iK=YKK*uKn;
sK=3*uKn.*conj(iK);

% beschreiben der Ausgangsvariablen
result.uK=uKn.'; 
result.iK=iK.';
result.sK=sK.';