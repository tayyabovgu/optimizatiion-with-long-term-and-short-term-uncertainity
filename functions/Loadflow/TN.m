function out=TN(YKKs)
    A=real(abs(YKKs)~=0); 
    k=size(A,1);
    cntr=1;
    lst=1:k;
    out=cell(k,1);
    ind=sum(A,1)>0;
    lst=lst(ind);
    A=A(ind,ind);
    k=size(A,1);
    einzel=~ind;
    while k>0
         b=zeros(k,1);b(1)=1;
         balt=real((A*b)~=0);
        while ~all(b==balt)%b~=balt
            balt=b;
            b=real((A*balt)~=0);
        end;
        b=logical(b);
        out{cntr}=lst(b);
        lst=lst(~b);
        A=A(~b,~b);
        k=size(A,1);
        cntr=cntr+1;
    end;
    out(cntr:cntr+sum(einzel)-1)=num2cell(find(einzel));
    out=out(1:cntr-1+sum(einzel),1);