clc;clear;
close all
disp('开始执行联合调度程序...');
tic
%% 导入ieee30节点网络
caseName = ieee30;
%% 系统参数
iw = 3;   %风电接入节点
idg = [1;2;5;8;11];  %DG接入节点
igd = [1]; %DG接入节点
Horizon = 24;
ngen = 5; %发电机数量
nw = 1;  %风电数量
nbus = size(caseName.bus,1);  %节点数量
%nbus=30
disp(['节点数量:', num2str(nbus)]);
%% 成本参数
prg = 375;  % 发电机上网价格
qw = 336;   % 弃风价格
qv = 366;   %弃光价格
%% 负荷
disp('计算负荷曲线...');
L_base = caseName.bus(:,3); % 基础负荷
plt = 1.3*[715 711 705 703 723 728 745 767 786 798 806 819 832 845 858 769 775 789 791 741 732 723 716 719]; % 系统总负荷
% 按节点基础负荷比例分配系统总负荷
L_Horizon = repmat(L_base./sum(L_base),1,Horizon) .* repmat(plt, nbus, 1);
ru = plt.*0.1; % 旋转备用需求
disp(['负荷曲线计算完成，最大系统负荷:', num2str(max(plt))]);
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
gz1 = binvar(gn,Horizon,'full');
gz2 = binvar(gn,Horizon,'full');
gz3 = binvar(gn,Horizon,'full');
gz4 = binvar(gn,Horizon,'full');
gz5 = binvar(gn,Horizon,'full');
%% 约束条件生成
disp('开始生成约束条件...');
cons = [];
%% 发电机组约束
disp('设置发电机组参数...');
Pmax = [260;320;260;220;240];  %最大发电功率
Pmin = 0.5.*Pmax;   % 最小发电功率
rg = 0.5.*Pmax;  %爬坡
Pa = 0.45.*Pmax; 
Pb = 0.3.*Pmax;
%% 风光约束
disp('设置风光约束...');
Wind = 0.2*[320,323,313,377,372,371,385,379,368,365,368,361,372,380,382,379,386,362,350,345,345,338,329,324];
PW = Wind./max(Wind)*100;  %归一化的处理
disp(['风电最大出力:', num2str(max(PW))]);
cons_re = getConsRE(x_P_w,PW);
cons = [cons,cons_re];
disp('添加发电机约束...');
cons_gen = getConsGen1(x_P_g,x_u_g,Pmax,Pb,rg,ru,Horizon);  %发电机约束
cons = [cons,cons_gen];
%% 潮流约束
disp('添加潮流约束...');
try
    cnos_eq = getConsEQ(x_P_g,x_P_w, L_Horizon, caseName,x_theta,igd,idg,iw);  %直流潮流模式
    cons = [cons,cnos_eq];
    disp('潮流约束添加成功');
catch ME
    disp('添加潮流约束失败:');
    disp(ME.message);
end
%% 线路传输约束
disp('添加线路传输约束...');
[cons_pf,pf] = getConsPF(caseName,x_theta,Horizon);
cons = [cons,cons_pf];
% 相角约束（简化处理）
disp('添加相角约束...');
cons = [cons, -pi <= x_theta <= pi];
%% 火电机组分段线性化
disp('设置火电机组分段线性化参数...');
gl1 = (Pmax-Pmin)./gn;
gl2 = zeros(5,gn+1);
for i = 1:5
    gl2(i,:) = Pmin(i):gl1(i):Pmax(i);
end
cons = [cons, gw1 >= 0, gw2 >= 0, gw3 >= 0, gw4 >= 0, gw5 >= 0, gw6 >= 0];
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
cons = [cons,gw3(gn+1,:)<=gz3(gn,:)];
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
disp('初始化成本计算变量...');
abc = [0.0211,32.05,1313.6;
       0.07,23.9,471;
       0.079,21.62,480.29;
       0.048,23.23,639.4;
       0.063,16.51,502.7];
sit = 7.*[650 450 450 550 550]; %启停成本系数
% 初始化损耗成本和投油成本变量
fsl = sdpvar(5,Horizon-1,'full');
fsy1 = sdpvar(5,Horizon,'full'); %投油成本
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
        cons = [cons,implies(x_P_g(ki,kj)>=Pa(ki),fsy1(ki,kj)==0)];
    end
end

%% 目标函数生成
f2 = f1 + sum(sum(fsl)) + sum(sum(fsy1)); %火电机组总成本，包含启停成本，损耗成本，投油成本
f3 = 280*sum(x_P_w); %风电机组运行成本
f4 = getObjqf(x_P_w,PW,Horizon); %弃风弃光成本
%% 预优化
disp('开始优化求解...');
options = sdpsettings('verbose', 2, 'solver', 'gurobi');
sol = optimize(cons, f2 + f3 + f4, options);
if sol.problem ~= 0 
    disp('优化求解失败，查看错误信息:');
    disp(sol.info);
    error('优化求解失败');
else
    disp('优化求解成功!');
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
plot(sum(PW),'b-','LineWidth',1.5)
hold on
plot(sum(L_Horizon),'r-','LineWidth',1.5)
legend('风电预测','负荷');
xlabel('时间');
ylabel('功率');

figure;
yy = [x_P_g;x_P_w]';
bar(yy,'stack');
hold on
plot(sum(L_Horizon),'r-','LineWidth',1.5)
legend('发电机1','发电机2','发电机3','发电机4','发电机5','风电','负荷');
xlabel('时间');
ylabel('功率');
ylabel('功率');
















