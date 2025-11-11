function WT1= wtarrifs(PLoadProf,Horizon)
%%%%%%%%%%%%%%%%%%%%%%%%White tarrif%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%WTwd=wighted total demand
%DP=demand in peak
%Dn=demand in intermediatery
%Dop= demand in off peak
%WT=white terrif
%WT=Cta*(sum(WTwdi)+sum(kz*Dsj)+sum(kz*Ddk)...i=1 to p...  j=1 to q...k=1
%to r
%p: Number of working days in the month.
%q: Number of Saturdays in the month.
%r: Number of Sundays in the month.
%Ds: Demand in Saturday.
%Dd: Demand in Sunday.
%Cta =conventional tarrif defined by utility
%clear all;
kz=0.18;
%x=xlsread('last.xlsx');
el= sum(PLoadProf)';
%el=x(:,2);
%hl=x(:,3);
time=(1:Horizon);
a=reshape(el,24,365);
W_work=a;
W_work(:, 7:7:end) = [];
W_weekend=a;
W_weekend=W_weekend(:,7:7:end);
Din=zeros(24,1);
Dop=zeros(24,1);
DP=zeros(24,1);
%{
    for i=1:292
        for j=1:24
            if W_work(j,i)>0.9
                DP(j)=W_work(j,i);
                 Dop(j)=0;
                 Din(j)=0;
            else if W_work(j,i)>0.700 & W_work(j,i)<=0.9 
                    Din(j)=W_work(j,i);
                     Dop(j)=0;
                     DP(j)=0;
                else
                    Dop(j)=W_work(j,i);
                    DP(j)=0;
                   Din(j)=0; 
                end
            end
        end
    end
        WTwd=kz*(5*DP+3*Din+Dop);
        WT=0.3*WTwd;
        %}

    for i=1:313
        for j=1:24
            if j==18 | j==19 | j==20 |j==21
                DP(j)=W_work(j,i);
                 Dop(j)=0;
                 Din(j)=0;
            else if j==17 | j==22
                    Din(j)=W_work(j,i);
                     Dop(j)=0;
                     DP(j)=0;
                else
                    Dop(j)=W_work(j,i);
                    DP(j)=0;
                   Din(j)=0; 
                end
            end
        end
        WTwd(:,i)=kz*(5*DP+3*Din+Dop);
        WT.WT_work(:,i)=3*WTwd(:,i);
    end
    %for k=1:length(W_weekend(1,:))
        WT.WT_weekend=30*ones(24,length(W_weekend(1,:)));
    %end
%a=reshape (WT_work, [], 1);
%b=reshape (WT_weekend, [], 1);
%WT=[a;b];
A=WT.WT_work(:,1:312);
AAA=WT.WT_work(:,313);
AA=WT.WT_weekend(:,1:52);

%{
while kk<=72
    BB=AA(:,kk:kk+1)
    kk=kk+2
    CC(:,kkk)=reshape(BB,[],1)
    kkk=kkk+1;
end
%}
kkk=1;
kk=1;
while kk<=312
    B=A(:,kk:kk+5);
    kk=kk+6;
    C(:,kkk)=reshape(B,[],1);
    kkk=kkk+1;
end
kkkk=1;
while kkkk<=52  
r(:,kkkk)=[C(:,kkkk); AA(:,kkkk)];
kkkk=kkkk+1;
end
WT1=reshape(r,[],1);
WT1=([WT1;AAA])';

end      
        
   