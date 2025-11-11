function [out,Zhlr,J,erf,Pi,Qi]=LF_NR(YKK,S,uKn,KTyp,eps,varargin)

% YKK: Knotenadmittanzmatrix
% S: Knotenleistung
% KTyp: Knotentyp (0:PQ, 1:dQ, 2:PU 3:slack)
% uKn:Knotenspg (LE, in V)
% eps:Genauigkeit
% varargin{} 1: Qmin
%            2: Qmax
%            3: Pmin
%            4: Pmax

    erf=true;
    n=size(YKK,1);                                                          % Knotenanzahl
    qmin=-Inf(n,1);                                                         % Grenzwert Qmin
    qmax=-qmin;                                                             % Grenzwert Qmax

    if nargin>5,qmin=varargin{1};end;                                       % prüfen ob Qmin definiert
    if nargin>6,qmax=varargin{2};end;                                       % prüfen ob Qmax definiert
    %if nargin>7,pmin=varargin{3};end;
    %if nargin>8,pmax=varargin{4};end;
    
    pist=real(S);                                                           % Wirkleistung (Vektor)
    Pist=diag(sparse(pist));                                                % Wirkleistung (Matrix)
    qist=imag(S);                                                           % Blindleistung (Vektor)
    Qist=diag(sparse(qist));                                                % Blindleistung (Matrix)                   
    x=[angle(uKn);ones(n,1)];                                               % Hilfsvariable (Spannungswinkel und Diagonalmatrix entsprechend Knotenanzahl)
    uK=uKn;                                                                 % Knotenspannung (Vektor)
    uKn=abs(uKn);                                                           % Knotenspannung (Betrag)
    dxmax=2*eps;                                                            % Genauigkeit
    Zhlr=0;                                                                 % Zähler
    slack=KTyp==3;                                                          % Slackknoten
    gen=KTyp==2;                                                            % Generatorknoten
    dQ=KTyp==1;                                                             % dQ Knoten 
    RemL=[slack|dQ;slack|gen];                                              % Aufschlüsseln nach const. phi und const u
    J2=sparse(2*n,1);                                                       % Initialisierung Jacobimatrix (Vektor)
    J2(RemL)=1;                                                             % 1 Setzen der entsprechenden Knoten
    J2=diag(J2);                                                            % initiale Jacobimatrix (Matrix)
    YKK=conj(YKK);                                                          % konjugiert komplexe Knotenadmittanzmatrix
    K=diag(sparse([~(slack|dQ);~(slack|gen)]));                             % finden aller PQ Knoten 
    %limr=false;
    while dxmax>eps
        Zhlr=Zhlr+1;                                                        % Zähler erhöhen
        if Zhlr>10                                      
            disp('max. Iter.');
            erf=false;
            break;
        end;
        UKS=diag(sparse(uK));                                               % Knotenspannungen (matrix)
        SK= 3*(UKS*YKK*conj(UKS));                                          % Knotenscheinleistung (Matrix)
        sK= 3*UKS*YKK*conj(uK);                                             % Knotenscheinleistung (Vektor)
        checkLims();
        pber=real(sK);                                                      % Wirkleistung (Vektor)
        qber=imag(sK);                                                      % Blindleistung (Vektor)
        Pber=real(SK);                                                      % Wirkleistung (Matrix)
        Qber=imag(SK);                                                      % Blindleistung (Matrix)
        dpK=pber-pist;                                                      % Differenz aus Pist und Psoll (Vektor)
        dqK=qber-qist;                                                      % Differenz aus Qist und Qsoll (Vektor)
        y=-[dpK;dqK];                                                       % Differenzen als gemeinsamer Vektor)
        DpK=diag(sparse(dpK));                                              % Differenzen aus Pist und Psoll (Matrix)
        DqK=diag(sparse(dqK));                                              % Differenzen aus Qist und Qsoll (Matrix)
        J=J2+K*[(Qber-DqK-Qist)  (Pber+DpK+Pist);                           % (?)
                (-Pber+DpK+Pist) (Qber+DqK+Qist)];                          % (?)
        y(RemL)=0;                                                          % Nullsetzen der Elemente mit konstanten Spannungen/Winkeln (?)
        dx=J\y;                                                             % Berechnung der neuen Spannungsdifferenzen
        dxmax=max(abs(dx));                                                 % Bestimmung der maximalen Abweichung (Abbruchkriterium)
        x = [x(1:n)+dx(1:n);1+dx(n+1:n+n)];                                 % Berechnen der neuen Spannungswinkel und Spannungsbeträge
        uK = abs(uK).*x(n+1:n+n).*exp(1j*x(1:n));                           % Berechnen der neuen absoluten Spannung
        uK(slack)=uKn(slack);                                               % Umschreiben Slack
        uK(gen)=uKn(gen).*exp(1j*x(gen));                                   % Umschreiben Generatorknoten
    end %of while
    
    %disp(Zhlr);
    iK=conj(YKK)*uK;
    
    if sum(isnan(uK))>0
        disp('nicht konvergiert');
        erf=false;
    end;
    out=[uK iK sK];
    
    function o=checkLims()                                                  % Umwandlung in PQ Knoten
        gen=gen & (imag(sK)<qmax | imag(sK)>qmin);
        qist(gen)=min(qmax(gen),max(qmin(gen),imag(sK(gen))));
        Qist=diag(sparse(qist));
        RemL=[slack | dQ;slack | gen];
        J2=sparse(2*n,1);
        J2(RemL)=1;
        J2=diag(J2);
        K=diag(sparse([~(slack|dQ);~(slack|gen)]));
        o=false;
    end
Pi=pber;
Qi=qber;
end

