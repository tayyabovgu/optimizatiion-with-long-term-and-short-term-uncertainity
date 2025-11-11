vK=NET.vK
zK=NET.zK
KKT=genKKT1(vK,zK)
function KKT=genKKT1(vK,zK)
% Diese Funktion erstellt eine Knoten-Terminal-Inzidenzmatrix
% vK - Vektor mit Knotennummern der beginnenden Knoten
% zK - Vektor mit Knotennummern der Zielknoten

% KKT - Knoten-Terminal-Inzidenzmatrix

%% Bestimmung der Basisparameter
anzK=size(unique([vK;zK]),1);
anzT=size(vK,1);

%% Aufstellen der Knoten-Terminal-Inzidenzmatrix
KKT=zeros(anzK,anzT);                       % Matrix initialisieren

NoG=[vK zK];                                % Knoten (Gesamt) aufstellen
NoG=reshape(NoG',1,anzT);                   % Umformen in Zeilenvektor
NoG=[1:1:anzT;NoG];                         % Ergänzen um Terminalnummer

pos=NoG(1,:)*anzK-anzK+NoG(2,:);            % Umrechnen von Doppelindize (Zeile/Spalte) auf Einfachindize

KKT(pos)=1;                                 % Belegen der Knoten-Terminalinzidenzmatrix
end