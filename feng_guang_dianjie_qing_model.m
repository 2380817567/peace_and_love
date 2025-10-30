%   第三讲的最后一个代码吧
% 风+光+制氢+储电 + 弃风弃光成本
clc;
clear;
%% 决策变量初始化
P_DG = sdpvar(1,24); %风电消纳功率
P_PV = sdpvar(1,24); %光伏消纳功率
P_PEM_E = sdpvar(1,24); %PEM的用电功率
P_PEM_H2 = sdpvar(1,24); %PEM的产氢功率
I = binvar(1,24);%停机
S = binvar(1,24);%冷待机
L = binvar(1,24);%变载运行
R = binvar(1,24);%过载运行
V = binvar(1,24);%低载运行
Y = binvar(1,24);%启动间隔
W = binvar(1,24);%制氢惩罚

%% 导入常数参数
%负荷参数
Pload=1.6*[252.25 250.75 256.25 256.75 256 277 301.25 324.5 331 356.25 375.25 399.5 406 422.25 426 413.5 386.5 375 355.75 324.5 301 275 255.75 249.5];
% 氢负荷
Hload = [244.5 247.5 228 243.5 256.6 262 278 300.5 311 337.5 334.5 361.5 372.5 356 349 336 300 294 277 264.5 256 251.5 249.5 244];
%风光预测出力
P_DG_max = [574.4 580.8 788.8 895.2 974.4 1091.2 834.4 534.4 647.2 696.8 880 900 914.4 1075.2 902.4 833.6 842.4 774.4 716 573.6 692 655.2 666.4 624.4];
P_PV_max = [0 0 0 0 0 0.4 100 214.4 276 364.8 444 471.2 523.2 569.6 550.4 500 453.6 334.4 204 0 0 0 0 0];
%% 导入约束条件
T = 24;
P_PEM_max = 300;
P_PEM_b = 8;
e = 0.9;  %制氢效率
%% 初始化目标函数和约束
Cost = 0;
C = []; %st约束初始化

%% 电解槽制氢约束
C = C+[P_PEM_H2 == e.*(P_PEM_E-P_PEM_b*S)]; %电氢转换关系

C = C+[P_PEM_b*S + 0.1*P_PEM_max*L + P_PEM_max*R+0.2*P_PEM_max*V<=P_PEM_E ];
%这串代码有点长，up只展示了PEM（制氢机器）的功率下限，没有展示功率上限，那我就来自己补写一下功率上限
% C = C+[P_PEM_b*S + 0.1*P_PEM_max*L + P_PEM_max*R+0.2*P_PEM_max*V<=P_PEM_E<=0.1*P_PEM_max*V   ];   %未抄全


% 这一块的选择一定要慎之又慎，不然很容易就不收敛
% 建议添加的上限约束
C = C+[P_PEM_E <= P_PEM_b*S + P_PEM_max*L + 1.2*P_PEM_max*R + 0.3*P_PEM_max*V];
% 或者更严格的设置（推荐）
%C = C+[P_PEM_E <= P_PEM_b*S + 0.9*P_PEM_max*L + 1.1*P_PEM_max*R + 0.25*P_PEM_max*V];
% 同时确保各状态变量的功率范围
% C = C+[
%     P_PEM_b*S <= P_PEM_E,           % 冷待机状态功率下限
%     0.1*P_PEM_max*L <= P_PEM_E,     % 变载运行功率下限  
%     P_PEM_max*R <= P_PEM_E,         % 过载运行功率下限
%     0.2*P_PEM_max*V <= P_PEM_E,     % 低载运行功率下限
%     
%     P_PEM_E <= P_PEM_b*S + eps,     % 冷待机状态下限（如果S=1）
%     P_PEM_E <= P_PEM_max*L + P_PEM_b, % 变载运行上限
%     P_PEM_E <= 1.1*P_PEM_max*R,     % 过载运行上限（可适当超载）
%     P_PEM_E <= 0.3*P_PEM_max*V      % 低载运行上限
% ];


C = C+[-I(:,1:T-2)+I(:,2:T-1)-I(:,3:T)<=0]; %停机时间约束
C = C+[L+S+I+R+V == 1];  %状态互斥约束
C = C+[V(:,2:T)+R(:,2:T)+L(:,2:T)+S(:,2:T)+I(:,1:T-1)<=Y(:,2:T)];%启停间隔约束
C = C+[W(:,2:T)<=S(:,1:T-1)];
C = C+[W<=L+R+V];
C = C+[W(:,2:T)>=S(:,1:T-1)+L(:,2:T)+R(:,2:T)+V(:,2:T)-1];
%过载低载时间限制
for i = 1:T-2
    C = C+[R(:,i)+R(:,i+1)+R(:,i+2)<=2];
end
for i = 1:T-2
    C=C+[V(:,i)+V(:,i+1)+V(:,i+2)<=2];
end

P_PEM_H2_N = sum(P_PEM_H2);
P_PEM_E_N = sum(P_PEM_E);

%% 风光约束出力
C = [C,
    0<=P_DG<=P_DG_max,    %风光出力约束
    0<=P_PV<=P_PV_max,
    ];

%% 储能约束
Ubat = 1000;
P_ES1_cha = sdpvar(1,24);  %充放功率
P_ES1_dis = sdpvar(1,24);
S_1 = sdpvar(1,24); %储能的实时容量状态
% 引入充放标志二进制变量
B_ES1_cha = binvar(1,24); %充标志
B_ES1_dis = binvar(1,24); %放标志
C = [C,
    0<=P_ES1_cha<=B_ES1_cha*0.5*Ubat, %储电设备的最大充电功率约束
    0<=P_ES1_dis<=B_ES1_dis*0.5*Ubat, %储电设备的最大放电功率约束
    S_1(1) == 0.3*Ubat, %储电设备的初始容量
    %始末状态守恒约束
    S_1(24) == S_1(1),
    %充放状态唯一
    B_ES1_cha+B_ES1_dis<=1,
    %储能容量上下限约束
    0.2*Ubat<=S_1<=0.9*Ubat,
    %储能容量变化约束
    S_1(2:24)==S_1(1:23)+0.95*P_ES1_cha(2:24)-P_ES1_dis(2:24)/0.95
    ];
%% 储氢约束
UH2 = 1500;
P_H2_cha = sdpvar(1,24); %充放功率
P_H2_dis = sdpvar(1,24);
S_1_H2 = sdpvar(1,24); %储能的实时容量状态
% 引入充放标志二进制变量
B_H2_cha = binvar(1,24); %充标志
B_H2_dis = binvar(1,24); %放标志
C = [C,
    0<=P_H2_cha<=B_H2_cha*0.5*UH2, %储氢设备的最大充电功率约束
    0<=P_H2_dis<=B_H2_dis*0.5*UH2, %储氢设备的最大放电功率约束
    S_1_H2(1) == 0.3*UH2, %储氢设备的初始容量
    %始末状态守恒约束
    S_1_H2(24) == S_1_H2(1),
    %充放电状态唯一
    B_H2_cha+B_H2_dis<=1,
    %储能容量上下限约束
    0.2*UH2<=S_1_H2<=0.8*UH2,
    %储能容量变化约束
    S_1_H2(2:24)==S_1_H2(1:23)+0.95*P_H2_cha(2:24)-P_H2_dis(2:24)/0.95,
    ];
%% 功率平衡约束
C = [C,
    P_DG+P_PV == Pload+P_PEM_E+P_ES1_cha-P_ES1_dis, %电功率平衡约束
    P_PEM_H2 == Hload+P_H2_cha - P_H2_dis %氢功率平衡
    ];
%% 弃风弃光量计算
qf = sdpvar(1,24);  %弃风
qg = sdpvar(1,24);  %弃光

C = [C,
    qf == P_DG_max - P_DG,    %弃风量约束
    qg == P_PV_max - P_PV     %弃光量约束
    ];

%总目标函数
Cost = 0;
qfg = 0; %弃风弃光量初始化
for t = 1:24
    Cost = Cost+10*P_DG(t)+10*P_PV(t)+212*P_PEM_E-300*P_PEM_H2+40*(P_ES1_cha(t)+P_ES1_dis(t))+60*(P_H2_cha(t)+P_H2_dis(t));   %未完待续
    qfg = qfg + 20*qf(t)+20*qg(t);
end
Tcost = Cost + qfg;
%% 求解
ops = sdpsettings('solver','gurobi','verbose',4,'debug',1);
optimize(C,Tcost,ops);
double(Tcost)
%Cost = value(sum(Cost));
Tcost = value(Tcost);
fprintf('总成本')
sum(Tcost)

%% 画图输出运行结果
figure;
bar([-P_PEM_E',P_DG',P_PV',-P_ES1_cha',P_ES1_dis',-Pload'],'stack') % 阶梯图
legend('电解槽耗电','风实际出力','光伏实际出力','储能充电','储能放电','电负荷');
xlabel('时刻（t）');
ylabel('功率（kW）');

figure;
bar([P_PEM_H2',-P_H2_cha',P_H2_dis',-Hload'],'stack')  %阶梯图
legend('电解槽制氢','储氢存氢','储氢放氢','氢负荷') 
xlabel('时刻（t）');
ylabel('功率（kW）');

figure
aa = value([P_DG]);
bar(aa',1,'stack')
legend('风实际出力');
xlabel('时刻（t）');
ylabel('功率（kW）');

figure
aa = value([P_PV]);
bar(aa',1,'stack')
legend('光实际出力');
xlabel('时刻（t）');
ylabel('功率（kW）');

figure
ee = value([S_1]);
bar(ee',1,'stack')
legend('储电容量');
xlabel('时刻（t）');
ylabel('功率（kW）');

figure
ee = value([S_1_H2]);
bar(ee',1,'stack')
legend('储氢容量');
xlabel('时刻（t）');
ylabel('功率（kW）');

figure
s = value([P_DG./P_DG_max]);
plot(s,'g-*','LineWidth',2)
legend('风电利用率');  %在坐标轴上添加图例
xlabel('时刻（t）');
ylabel('功率(kW)');


figure
s = value([(P_DG_max-P_DG)./P_DG_max]);
plot(s,'g-*','LineWidth',2)
legend('弃风率');
xlabel('时刻（t）');
ylabel('功率（kW）');

figure
s = value([P_PV./P_PV_max]);
plot(s,'g-*','LineWidth',2)
legend('光伏利用率');
xlabel('时刻（t）');
ylabel('功率（kW）');

figure
s = value([(P_PV_max-P_PV)./P_PV_max]);
plot(s,'g-*','LineWidth',2)
legend('弃光率');
xlabel('时刻（t）');
ylabel('功率（kW）');



L = value(L);
S = value(S);
I = value(I);
R = value(R);
V = value(V);
Y = value(Y);
W = value(W);
P_DG = value(P_DG);
%未完待续


 %  total_elements = numel(P_PV_max);    用来查询数组中的元素个数
