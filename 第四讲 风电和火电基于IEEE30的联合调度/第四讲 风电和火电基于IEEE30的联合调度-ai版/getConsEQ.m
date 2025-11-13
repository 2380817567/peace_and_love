function  cons = getConsEQ(x_P_g,x_P_w, L_Horizon , caseName,x_theta,igd,idg,iw)
cons = [];
baseMVA = 100;

    bus = caseName.bus;
    brch = caseName.branch;
    f = brch(:,1);
    t = brch(:,2);
    x = brch(:,4);
    nbus = size(bus,1);
    nbrch = size(brch,1);
    Horizon = size(x_P_g,2);
    Cft = zeros(nbrch,nbus);
    for ii = 1:nbrch
        Cft(ii,f(ii)) = 1;
        Cft(ii,t(ii)) = -1;
    end
    Bf = zeros(nbrch,nbus);
    for ii = 1:nbrch
        Bf(ii,f(ii)) = 1./x(ii);
        Bf(ii,t(ii)) = -1./x(ii);
    end
    Bbus = Cft.'*Bf;  %Cf转置
    %Bbus(ib_prm,:) = [];
    %% 生成Pbus
    Mbg = getMbdMatrix(idg,bus);
    Mbw = getMbdMatrix(iw,bus);
    %MbL = getMbdMatrix(iL,bus);%Mbgrid*x_P_grid(:,ii)+   可以理解为每条线路允许通过的最大容量
    Pbus = []; %净出力
    for ii = 1:Horizon
        Pbus = [Pbus,Mbg*x_P_g(:,ii)+Mbw*x_P_w(:,ii)-L_Horizon(:,ii)];
    end
    %Pbus(ib_prm,:) = [];
    %% 潮流平衡约束，弧度制，有名值
    for ii = 1:Horizon
        cons = [cons,Pbus(:,ii) == Bbus * x_theta(:,ii) * baseMVA];
    end
    %end























