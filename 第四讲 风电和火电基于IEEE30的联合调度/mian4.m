%%我抄的这个代码跑不了，但是ai改的那个输出结果基本是对的
%%少了一个getConsAgl和getMbpMatrix
%%就先这样吧，那个ai就挺好的

clc;clear;
close all
tic
%% 导入ieee30节点网络
caseName = ieee30;
%% 系统参数
iw = 3;   %风电接入节点
idg = [1;2;5;8;11];  %DG接入节点
igd = [1]; %DG接入节点
Horizon = 24;
nbus = 30;   %节点数量
ngen = 5; %发电机数量
nw = 1;  %风电数量
%% 成本参数
prg = 375;  % 发电机上网价格
qw = 336;   % 弃风价格
qv = 366;   %弃光价格
%% 负荷
r_base = 0.55;  % 负荷曲线基准，控制负荷曲线在y轴上下平移
r_fluc = 0.55;  % 负荷全部下面NPDP买个，控制负荷曲线的波动范围大小
L_base = caseName.bus(:,3);
L_profile = [4252,3916,3698,3589,3481,3481,3484,3589,3807,4351,4786,4895,4950,4895,4786,4732,4722,4950,5438,5385,5276,5112,5003,4990];
L_profile = L_profile./max(L_profile);
L_Horizon = r_base.*repmat(L_base,1,Horizon) + r_fluc.*repmat(L_base,1,Horizon).*repmat(L_profile,nbus,1);  %IEEE30节点的电荷
plt =1.3*[715 711 705 703 723 728 745 767  786 798  806 819 832 845 858 769 775 789 791 741 732 723 716 719];
L_Horizon = repmat(L_base./sum(L_base),1,Horizon).*repmat(plt,30,1);
ru = plt.*0.1;
%% 决策变量
x_theta = sdpvar(nbus,Horizon,'full'); %直角坐标角度
x_P_g = sdpvar(ngen,Horizon,'full');   %发电机
x_P_w = sdpvar(nw,Horizon,'full');     %风电
x_u_g = binvar(ngen,Horizon,'full');   %发电机状态
%% 分段函数线性化，下同
gn = 5;
x_pf = sdpvar(ngen,Horizon,'full');
gw1 = sdpvar(gn+1,Horizon,'full');
gw2 = sdpvar(gn+1,Horizon,'full');
gw3 = sdpvar(gn+1,Horizon,'full');
gw4 = sdpvar(gn+1,Horizon,'full');
gw5 = sdpvar(gn+1,Horizon,'full');
gw6 = sdpvar(gn+1,Horizon,'full');
gw1 = sdpvar(gn+1,Horizon,'full');
gz1 = binvar(gn,Horizon,'full');
gz2 = binvar(gn,Horizon,'full');
gz3 = binvar(gn,Horizon,'full');
gz4 = binvar(gn,Horizon,'full');
gz5 = binvar(gn,Horizon,'full');
%% 约束条件生成
cons = [];
%% 发电机组约束
Pmax = [260;320;260;220;240];  %最大发电功率
Pmin = 0.5.*Pmax;   % 最小发电功率
rg = 0.5.*Pmax;  %爬坡
Pa = 0.45.*Pmax; 
Pb = 0.3.*Pmax;
cons_gen = getConsGen1(x_P_g,x_u_g,Pmax,Pb,rg,ru,Horizon);  %发电机约束
cons = [cons,cons_gen];
%% 风光约束
Wind = 0.2*[320,323,313,377,372,371,385,379,368,365,368,361,372,380,382,379,386,362,350,345,345,338,329,324];
PW = Wind./max(Wind)*100;  %归一化的处理
cons_re = getConsRE(x_P_w,PW);
cons = [cons,cons_re];
%% 潮流约束
cnos_eq = getConsEQ(x_P_g,x_P_w,L_Horizon,caseName,x_theta,igd,idg,iw);  %直流潮流模式
cons = [cons,cnos_eq];
%% 线路传输约束
[cons_pf,pf] = getConsPF(caseName,x_theta,Horizon);
cons = [cons,cons_pf];
cons = [cons,getConsAgl(x_theta)];
%% 火电机组分段线性化
gl1 = (Pmax-Pmin)./gn;
gl2 = zeros(5,gn+1);
for i = 1:5
    gl2(i,:) = Pmin(i):gl1(i):Pmax(i);
end
cons = [cons,x_pf(1,:) == gl2(1,:).^2*gw1];
cons = [cons,x_pf(2,:) == gl2(2,:).^2*gw2];
cons = [cons,x_pf(3,:) == gl2(3,:).^2*gw3];
cons = [cons,x_pf(4,:) == gl2(4,:).^2*gw4];
cons = [cons,x_pf(5,:) == gl2(5,:).^2*gw5];
cons = [cons,gw1(1,:)<=gz1(1,:)];
for i = 2:gn
    cons = [cons,gw1(i,:)<=gz1(i-1,:)+gz1(i,:)];
end
cons = [cons,gw1(gn+1,:)<=gz1(gn,:)];
cons = [cons,sum(gz1) == ones(1,Horizon)];
cons = [cons,gw2(1,:)<=gz2(1,:)];
for i = 2:gn
    cons = [cons,gw2(i,:)<=gz2(i-1,:)+gz2(i,:)];
end
cons = [cons,gw2(gn+1,:)<=gz2(gn,:)];
cons = [cons,sum(gz2) == ones(1,Horizon)];
cons = [cons,gw3(1,:)<=gz3(1,:)];
for i = 2:gn
    cons = [cons,gw3(i,:)<=gz3(i-1,:)+gz3(i,:)];
end
cons = [cons,gw2(gn+1,:)<=gz2(gn,:)];
cons = [cons,sum(gz3) == ones(1,Horizon)];
cons = [cons,gw4(1,:)<=gz4(1,:)];
for i = 2:gn
    cons = [cons,gw4(i,:)<=gz4(i-1,:)+gz4(i,:)];
end
cons = [cons,gw4(gn+1,:)<=gz4(gn,:)];
cons = [cons,sum(gz4) == ones(1,Horizon)];
cons = [cons,gw5(1,:)<=gz5(1,:)];
for i = 2:gn
    cons = [cons,gw5(i,:)<=gz5(i-1,:)+gz5(i,:)];
end
cons = [cons,gw5(gn+1,:)<=gz5(gn,:)];
cons = [cons,sum(gz5) == ones(1,Horizon)];
cons = [cons,x_P_g(1,:) == gl2(1,:)*gw1];
cons = [cons,x_P_g(2,:) == gl2(2,:)*gw2];
cons = [cons,x_P_g(3,:) == gl2(3,:)*gw3];
cons = [cons,x_P_g(4,:) == gl2(4,:)*gw4];
cons = [cons,x_P_g(5,:) == gl2(5,:)*gw5];
cons = [cons,gw1>=0,gw2>=0,gw3>=0,gw4>=0,gw5>=0];
%% 火电机组成本计算
abc = [0.0211,32.05,1313.6;
       0.07,23.9,471;
       0.079,21.62,480.29;
       0.048,23.23,639.4;
       0.063,16.51,502.7];
sit = 7.*[650 450 450 550 550]; %启停成本系数
f11 = sum(sum(repmat(abc(:,1),1,Horizon).*x_pf+repmat(abc(:,2),1,Horizon).*x_P_g+repmat(abc(:,3),1,Horizon)));
f12 = sum(sum([x_u_g(:,2:end),x_u_g(:,1)].*(1 - x_u_g),2).*sit');
f1 = f11 + f12;
fsy1 = sdpvar(5,Horizon,'full'); %投油成本
fsl = sdpvar(5,Horizon-1,'full');%机组损耗成本
amp = 0:5:80;  %变负荷幅度
csl = [0 0.0002 0.0004 0.0004 0.0005 0.0005 0.0006 0.0006 0.0006 0.0008 0.0010 0.0013 0.0016 0.0017 0.0019 0.0022 0.0024];%寿命损耗概率
beta = 1.3; %火电机组影响系数
for ki = 1:5
    for kj = 2:Horizon
        cons = [cons,
                implies(amp(1)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(2)/100*Pmax(ki),fsl(ki,kj-1)==csl(2)*beta*439.4*Pmax(ki));
                implies(amp(2)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(3)/100*Pmax(ki),fsl(ki,kj-1)==csl(3)*beta*439.4*Pmax(ki));
                implies(amp(3)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(4)/100*Pmax(ki),fsl(ki,kj-1)==csl(4)*beta*439.4*Pmax(ki));
                implies(amp(4)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(5)/100*Pmax(ki),fsl(ki,kj-1)==csl(5)*beta*439.4*Pmax(ki));
                implies(amp(5)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(6)/100*Pmax(ki),fsl(ki,kj-1)==csl(6)*beta*439.4*Pmax(ki));
                implies(amp(6)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(7)/100*Pmax(ki),fsl(ki,kj-1)==csl(7)*beta*439.4*Pmax(ki));
                implies(amp(7)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(8)/100*Pmax(ki),fsl(ki,kj-1)==csl(8)*beta*439.4*Pmax(ki));
                implies(amp(8)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(9)/100*Pmax(ki),fsl(ki,kj-1)==csl(9)*beta*439.4*Pmax(ki));
                implies(amp(9)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(10)/100*Pmax(ki),fsl(ki,kj-1)==csl(10)*beta*439.4*Pmax(ki));
                implies(amp(10)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(11)/100*Pmax(ki),fsl(ki,kj-1)==csl(11)*beta*439.4*Pmax(ki));
                implies(amp(11)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(12)/100*Pmax(ki),fsl(ki,kj-1)==csl(12)*beta*439.4*Pmax(ki));
                implies(amp(12)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(13)/100*Pmax(ki),fsl(ki,kj-1)==csl(13)*beta*439.4*Pmax(ki));
                implies(amp(13)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(14)/100*Pmax(ki),fsl(ki,kj-1)==csl(14)*beta*439.4*Pmax(ki));
                implies(amp(14)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(15)/100*Pmax(ki),fsl(ki,kj-1)==csl(15)*beta*439.4*Pmax(ki));
                implies(amp(15)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(16)/100*Pmax(ki),fsl(ki,kj-1)==csl(16)*beta*439.4*Pmax(ki));
                implies(amp(16)/100*Pmax(ki)<=x_P_g(ki,kj)-x_P_g(ki,kj-1)<=amp(17)/100*Pmax(ki),fsl(ki,kj-1)==csl(17)*beta*439.4*Pmax(ki));%439.4表示机组成本万元/MW
        ];
    end
end
cons = [cons,0<=fsy1<=1000000];
cons = [cons,0<=fsl<=100];
for ki = 1:5
    for kj = 1:Horizon
        cons = [cons,implies(x_P_g(ki,kj)<=Pa(ki),fsy1(ki,kj)==48/4)];
        cons = [cons,implies(x_P_g(ki,kj)>=Pa(ki),fsy(ki,kj)==0)];
    end
end

%% 目标函数生成
f2 = f1 +sum(sum(fs1))+sum(sum(fsy1)); %火电机组总成本，包含启停成本，损耗成本，投油成本
f3 = 280*sum(x_P_w); %风电机组运行成本
f4 = getObjqf(x_P_w,PW,Horizon); %弃风弃光成本
%% 预优化
options =sdpsettings('verbose',2,'solver','gurobi');
sol = optimize(cons,f2+f3+f4,options);
if sol.problem ~= 0 
    error("1求解失败");
end

%% 变量数值显示
f1 = value(f1);
f2 = value(f2);
f3 = value(f3);
x_theta = value(x_theta);
x_P_g = value(x_P_g);
x_u_g = value(x_u_g);
x_P_w = value(x_P_w);
%% 弃风率
fprintf('弃风率')
sum(PW-x_P_w)/sum(PW)
%% 总成本
fprintf('总成本')
f2+f3
%% 画图
figure;
sum(PW,'b-','LineWidth',1.5)
hold on
plot(sum(L-Horizon),'r-','LineWidth',1.5)
legend('风电预测','负荷');
xlabel('时间');
ylabel('功率');

figure;
yy = [x_P_g;x_P_w]';
bar(yy,'stack');
hold on
plot(sum(L-Horizon),'r-','LineWidth',1.5)
legend('发电机1','发电机2','发电机3','发电机4','发电机5','风电','负荷');
xlabel('时间');
ylabel('功率');
















