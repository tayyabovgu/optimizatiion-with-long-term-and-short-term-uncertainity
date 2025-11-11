function BRANCH=EditBranch(ANZ,NOD,LIN,TRA,SWT)
% This function processes raw line, transformer, and switch data
% from LoadDat.m into a unified BRANCH struct.

flag=1; % Initialize the row counter

%% Leitungsdaten
if ANZ.L>0
    for l=1:ANZ.L
        % von Knoten (Status 1)
        hilf1=LIN.vKNamHilf{l,:};
        if isa(hilf1,'double')==1
            hilf2={{num2str(hilf1)}};
        else
            hilf2=textscan(hilf1,'%s','delimiter',';');
        end
        hilf3=LIN.vKStatHilf{l,:};
        if isa(hilf3,'double')==1
            hilf4={{num2str(hilf3)}};
        else
            hilf4=textscan(hilf3,'%s','delimiter',';');
        end
        
        hilf5=size(hilf2{1,1},1)-1;
        
        hilf6=LIN.StatLS{l,:};
        if isa(hilf6,'double')==1
            hilf7=hilf6;
        else
            hilf7=textscan(hilf6,'%s','delimiter',';');
            hilf7=str2double(hilf7{1,1}{1,1});
        end
        
        hilf8=LIN.StatE{l,:};
        if isa(hilf8,'double')==1
            hilf9=hilf8;
        else
            hilf9=textscan(hilf8,'%s','delimiter',';');
            hilf9=str2double(hilf9{1,1}{1,1});
        end
        BRANCH.GesNam(flag:flag+hilf5,1)=repmat(LIN.LtgNam(l,1),hilf5+1,1);
        BRANCH.GesNam(flag:flag+hilf5,2)=hilf2{1,1};
        BRANCH.GesNam(flag:flag+hilf5,3)=hilf4{1,1};
        BRANCH.GesNam(flag:flag+hilf5,4)=num2cell(ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,5)=num2cell(ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,6)=num2cell(ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,7)=num2cell(ones(hilf5+1,1)*hilf7);
        BRANCH.GesNam(flag:flag+hilf5,8)=num2cell(ones(hilf5+1,1)*hilf9);
        posN=zeros(hilf5+1,1);
        for n=1:hilf5+1
            txt=hilf2{1,1}{n,1};
            posN(n,1)=find(strcmp(txt,NOD.KNam));
        end
        BRANCH.Ges(flag:flag+hilf5,1)=l*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,2)=posN;
        BRANCH.Ges(flag:flag+hilf5,3)=str2double(cellstr(hilf4{1,1}));
        BRANCH.Ges(flag:flag+hilf5,4)=ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,5)=ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,6)=ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,7)=ones(hilf5+1,1)*hilf7;
        BRANCH.Ges(flag:flag+hilf5,8)=ones(hilf5+1,1)*hilf9;
        flag=flag+hilf5+1;
        % zu Knoten (Status 2)
        hilf1=LIN.zKNamHilf{l,:};
        if isa(hilf1,'double')==1
            hilf2={{num2str(hilf1)}};
        else
            hilf2=textscan(hilf1,'%s','delimiter',';');
        end
        hilf3=LIN.zKStatHilf{l,:};
        if isa(hilf3,'double')==1
            hilf4={{num2str(hilf3)}};
        else
            hilf4=textscan(hilf3,'%s','delimiter',';');
        end
        hilf5=size(hilf2{1,1},1)-1;
        
        hilf6=LIN.StatLS{l,:};
        if isa(hilf6,'double')==1
            hilf7=hilf6;
        else
            hilf7=textscan(hilf6,'%s','delimiter',';');
            hilf7=str2double(hilf7{1,1}{2,1});
        end
        
        hilf8=LIN.StatE{l,:};
        if isa(hilf8,'double')==1
            hilf9=hilf8;
        else
            hilf9=textscan(hilf8,'%s','delimiter',';');
            hilf9=str2double(hilf9{1,1}{2,1});
        end
        BRANCH.GesNam(flag:flag+hilf5,1)=repmat(LIN.LtgNam(l,1),hilf5+1,1);
        BRANCH.GesNam(flag:flag+hilf5,2)=hilf2{1,1};
        BRANCH.GesNam(flag:flag+hilf5,3)=hilf4{1,1};
        BRANCH.GesNam(flag:flag+hilf5,4)=num2cell(2*ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,5)=num2cell(ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,6)=num2cell(ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,7)=num2cell(ones(hilf5+1,1)*hilf7);
        BRANCH.GesNam(flag:flag+hilf5,8)=num2cell(ones(hilf5+1,1)*hilf9);
        posN=zeros(hilf5+1,1);
        for n=1:hilf5+1
            txt=hilf2{1,1}{n,1};
            posN(n,1)=find(strcmp(txt,NOD.KNam));
        end
        BRANCH.Ges(flag:flag+hilf5,1)=l*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,2)=posN;
        BRANCH.Ges(flag:flag+hilf5,3)=str2double(cellstr(hilf4{1,1}));
        BRANCH.Ges(flag:flag+hilf5,4)=2*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,5)=ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,6)=ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,7)=ones(hilf5+1,1)*hilf7;
        BRANCH.Ges(flag:flag+hilf5,8)=ones(hilf5+1,1)*hilf9;
        flag=flag+hilf5+1;
    end
end
clearvars hilf1 hilf2 hilf3 hilf4 hilf5 hilf6 hilf7 hilf8 hilf9 l n posN txt;

%% Transformatordaten
if ANZ.Tr>0
    for t=1:ANZ.Tr
        % von Knoten (Status 1)
        hilf1=TRA.vKNamHilf{t,:};
        if isa(hilf1,'double')==1
            hilf2={{num2str(hilf1)}};
        else
            hilf2=textscan(hilf1,'%s','delimiter',';');
        end
        hilf3=TRA.vKStatHilf{t,:};
        if isa(hilf3,'double')==1
            hilf4={{num2str(hilf3)}};
        else
            hilf4=textscan(hilf3,'%s','delimiter',';');
        end
        hilf5=size(hilf2{1,1},1)-1;
        
        hilf6=TRA.StatLS{t,:};
        if isa(hilf6,'double')==1
            hilf7=hilf6;
        else
            hilf7=textscan(hilf6,'%s','delimiter',';');
            hilf7=str2double(hilf7{1,1}{1,1});
        end
        
        hilf8=TRA.StatE{t,:};
        if isa(hilf8,'double')==1
            hilf9=hilf8;
        else
            hilf9=textscan(hilf8,'%s','delimiter',';');
            hilf9=str2double(hilf9{1,1}{1,1});
        end
        BRANCH.GesNam(flag:flag+hilf5,1)=repmat(TRA.TrNam(t,1),hilf5+1,1);
        BRANCH.GesNam(flag:flag+hilf5,2)=hilf2{1,1};
        BRANCH.GesNam(flag:flag+hilf5,3)=hilf4{1,1};
        BRANCH.GesNam(flag:flag+hilf5,4)=num2cell(ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,5)=num2cell(2*ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,6)=num2cell(ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,7)=num2cell(ones(hilf5+1,1)*hilf7);
        BRANCH.GesNam(flag:flag+hilf5,8)=num2cell(ones(hilf5+1,1)*hilf9);
        posN=zeros(hilf5+1,1);
        for n=1:hilf5+1
            txt=hilf2{1,1}{n,1};
            posN(n,1)=find(strcmp(txt,NOD.KNam));
        end
        BRANCH.Ges(flag:flag+hilf5,1)=t*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,2)=posN;
        BRANCH.Ges(flag:flag+hilf5,3)=str2double(cellstr(hilf4{1,1}));
        BRANCH.Ges(flag:flag+hilf5,4)=ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,5)=2*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,6)=ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,7)=ones(hilf5+1,1)*hilf7;
        BRANCH.Ges(flag:flag+hilf5,8)=ones(hilf5+1,1)*hilf9;
        flag=flag+hilf5+1;
        % zu Knoten (Status 2)
        hilf1=TRA.zKNamHilf{t,:};
        if isa(hilf1,'double')==1
            hilf2={{num2str(hilf1)}};
        else
            hilf2=textscan(hilf1,'%s','delimiter',';');
        end
        hilf3=TRA.zKStatHilf{t,:};
        if isa(hilf3,'double')==1
            hilf4={{num2str(hilf3)}};
        else
            hilf4=textscan(hilf3,'%s','delimiter',';');
        end
        hilf5=size(hilf2{1,1},1)-1;
        
        hilf6=TRA.StatLS{t,:};
        if isa(hilf6,'double')==1
            hilf7=hilf6;
        else
            hilf7=textscan(hilf6,'%s','delimiter',';');
            hilf7=str2double(hilf7{1,1}{2,1});
        end
        
        hilf8=TRA.StatE{t,:};
        if isa(hilf8,'double')==1
            hilf9=hilf8;
        else
            hilf9=textscan(hilf8,'%s','delimiter',';');
            hilf9=str2double(hilf9{1,1}{2,1});
        end
        BRANCH.GesNam(flag:flag+hilf5,1)=repmat(TRA.TrNam(t,1),hilf5+1,1);
        BRANCH.GesNam(flag:flag+hilf5,2)=hilf2{1,1};
        BRANCH.GesNam(flag:flag+hilf5,3)=hilf4{1,1};
        BRANCH.GesNam(flag:flag+hilf5,4)=num2cell(2*ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,5)=num2cell(2*ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,6)=num2cell(ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,7)=num2cell(ones(hilf5+1,1)*hilf7);
        BRANCH.GesNam(flag:flag+hilf5,8)=num2cell(ones(hilf5+1,1)*hilf9);
        posN=zeros(hilf5+1,1);
        for n=1:hilf5+1
            txt=hilf2{1,1}{n,1};
            posN(n,1)=find(strcmp(txt,NOD.KNam));
        end
        BRANCH.Ges(flag:flag+hilf5,1)=t*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,2)=posN;
        BRANCH.Ges(flag:flag+hilf5,3)=str2double(cellstr(hilf4{1,1}));
        BRANCH.Ges(flag:flag+hilf5,4)=2*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,5)=2*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,6)=ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,7)=ones(hilf5+1,1)*hilf7;
        BRANCH.Ges(flag:flag+hilf5,8)=ones(hilf5+1,1)*hilf9;
        flag=flag+hilf5+1;
    end
end
clearvars hilf1 hilf2 hilf3 hilf4 hilf5 hilf6 hilf7 hilf8 hilf9 n posN t txt;

%% Schalterdaten
if ANZ.S>0
    for s=1:ANZ.S
        % von Knoten (Status 1)
        hilf1=SWT.vKNamHilf{s,:};
        if isa(hilf1,'double')==1
            hilf2={{num2str(hilf1)}};
        else
            hilf2=textscan(hilf1,'%s','delimiter',';');
        end
        hilf3=SWT.vKStatHilf{s,:};
        if isa(hilf3,'double')==1
            hilf4={{num2str(hilf3)}};
        else
            hilf4=textscan(hilf3,'%s','delimiter',';');
        end
        hilf5=size(hilf2{1,1},1)-1;
        BRANCH.GesNam(flag:flag+hilf5,1)=repmat(SWT.SwNam(s,1),hilf5+1,1);
        BRANCH.GesNam(flag:flag+hilf5,2)=hilf2{1,1};
        BRANCH.GesNam(flag:flag+hilf5,3)=hilf4{1,1};
        BRANCH.GesNam(flag:flag+hilf5,4)=num2cell(ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,5)=num2cell(3*ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,6)=num2cell(SWT.Stat(s,1)*ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,7)=num2cell(ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,8)=num2cell(zeros(hilf5+1,1));        
        posN=zeros(hilf5+1,1);
        for n=1:hilf5+1
            txt=hilf2{1,1}{n,1};
            posN(n,1)=find(strcmp(txt,NOD.KNam));
        end
        BRANCH.Ges(flag:flag+hilf5,1)=s*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,2)=posN;
        BRANCH.Ges(flag:flag+hilf5,3)=str2double(cellstr(hilf4{1,1}));
        BRANCH.Ges(flag:flag+hilf5,4)=ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,5)=3*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,6)=SWT.Stat(s,1)*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,7)=ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,8)=zeros(hilf5+1,1);
        flag=flag+hilf5+1;
        % zu Knoten (Status 2)
        hilf1=SWT.zKNamHilf{s,:};
        if isa(hilf1,'double')==1
            hilf2={{num2str(hilf1)}};
        else
            hilf2=textscan(hilf1,'%s','delimiter',';');
        end
        hilf3=SWT.zKStatHilf{s,:};
        if isa(hilf3,'double')==1
            hilf4={{num2str(hilf3)}};
        else
            hilf4=textscan(hilf3,'%s','delimiter',';');
        end
        hilf5=size(hilf2{1,1},1)-1;
        BRANCH.GesNam(flag:flag+hilf5,1)=repmat(SWT.SwNam(s,1),hilf5+1,1);
        BRANCH.GesNam(flag:flag+hilf5,2)=hilf2{1,1};
        BRANCH.GesNam(flag:flag+hilf5,3)=hilf4{1,1};
        BRANCH.GesNam(flag:flag+hilf5,4)=num2cell(2*ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,5)=num2cell(3*ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,6)=num2cell(SWT.Stat(s,1)*ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,7)=num2cell(ones(hilf5+1,1));
        BRANCH.GesNam(flag:flag+hilf5,8)=num2cell(zeros(hilf5+1,1));  
        posN=zeros(hilf5+1,1);
        for n=1:hilf5+1
            txt=hilf2{1,1}{n,1};
            posN(n,1)=find(strcmp(txt,NOD.KNam));
        end
        BRANCH.Ges(flag:flag+hilf5,1)=s*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,2)=posN;
        BRANCH.Ges(flag:flag+hilf5,3)=str2double(cellstr(hilf4{1,1}));
        BRANCH.Ges(flag:flag+hilf5,4)=2*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,5)=3*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,6)=SWT.Stat(s,1)*ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,7)=ones(hilf5+1,1);
        BRANCH.Ges(flag:flag+hilf5,8)=zeros(hilf5+1,1);
        flag=flag+hilf5+1;
    end
end
clearvars hilf1 hilf2 hilf3 hilf4 hilf5 n posN s txt;
BRANCH.GesNam=BRANCH.GesNam(1:flag-1,:);
BRANCH.Ges=BRANCH.Ges(1:flag-1,:);
clear flag;
end