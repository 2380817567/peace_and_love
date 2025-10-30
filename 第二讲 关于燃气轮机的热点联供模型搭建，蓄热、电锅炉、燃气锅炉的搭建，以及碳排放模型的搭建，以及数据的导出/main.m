% 唉，我也不知道这个代码细节上有什么问题，至
% 少思路上是没什么问题的，但是结果跑的有没有毛病，也说不好
clc
clear

tic
%%%% 这个负荷的参数可以改变一下，看看变化趋势
Hload=1*[252.25 250.75 256.25 256.75 256 277 301.25 324.5 331 356.25 375.25 399.5 406 422.25 426 413.5 386.5 375 355.75 324.5 301 275 255.75 249.5];

%% 约束条件
C = [];
T = 24;

%% 燃机建模
e_pgu = 0.3; %燃气轮机的发电效率
wh_pgu = 0.5; %燃气轮机的余热回收率
h_pgu = 0.45; %燃气轮机余热分流制热
c_pgu = 0.55; %燃气轮机余热分流制冷
l_pgu = 0.2; %燃气轮机热损失率
Hpgu = sdpvar(1,24,'full');
Qpgu = sdpvar(1,24,'full');
Ppgu = sdpvar(1,24,'full');
V_pgu = sdpvar(1,24,'full');
for t = 1:24
    C = [C,Hpgu(t) == Qpgu(t)*wh_pgu*h_pgu]; %燃气轮机热输出
    C = [C,Ppgu(t) == Qpgu(t)*e_pgu]; %燃气轮机电输出
    C = [C,0 <= Qpgu(t)<=500]; %燃气轮机上下限约束，后面会讲燃煤机组，非线性二次耗煤曲线
    C = [C,V_pgu(t) == Qpgu(t)/9.88]; %消耗天然气的体积
end
%% 储热部分，和储能类似
Ubat = 500; % 首先定义储热的最大容量
P_ES1_cha = sdpvar(1,24,'full');  %储能充电功率
P_ES1_dis = sdpvar(1,24,'full');  %储能放电功率
S_1 = sdpvar(1,24,'full');%各储能的实时容量状态SOC
%引入充放标志二进制变量
B_ES1_cha = binvar(1,24,'full');%充电标志
B_ES1_dis = binvar(1,24,'full');%放电标志
C=[C,
   0<=P_ES1_cha<=B_ES1_cha*0.25*Ubat,%储电设备的最大充电电功率约束
   0<=P_ES1_dis<=B_ES1_dis*0.25*Ubat,%储电设备的最大放电电功率约束
   S_1(1) == 0.3*Ubat, %储电设备的初始容量
   S_1(24) == S_1(1),  %首尾状态相同，在一个周期内，实现状态不变
   %充放状态唯一
   B_ES1_cha+B_ES1_dis<=1,
   %储能容量上下限约束
   0.1*Ubat <= S_1 <=0.9*Ubat,
   %储能容量变化约束，从第二时刻起每个时刻的容量
   S_1(2:24) == S_1(1:23)+0.95*P_ES1_cha(2:24)-P_ES1_dis(2:24)/0.9  %0.9是储能效率
   ];

%% 燃气锅炉
P_gb = sdpvar(1,24,'full');
V_gb = sdpvar(1,24,'full');
for i = 1:24
    C = [C,0 <= P_gb(i) <= 150];
    C = [C,V_gb(i) == P_gb(i)/0.9/0.88]; % 0.9是燃气锅炉的效率
end

%% 电锅炉
P_eb = sdpvar(1,24,'full');
E_eb = sdpvar(1,24,'full'); %热电耦合，电锅炉消耗的电，0.95是电锅炉的制热效率
for i = 1:24
    C = [C,0<=P_eb(i)<=150];
    C = [C,E_eb(i) == P_eb(i)/0.95];
end
%% 功率平衡约束
for i = 1:24
    C = [C,Hpgu(i)+P_gb(i)+P_eb(i)+P_ES1_dis(i) == P_ES1_cha(i)+Hload(i)];%热平衡约束
end

%% 碳排放
% 一般来源就两个，一个是电网购电产生的简介碳排放，一个是燃气或者煤气石油等燃料燃烧产生的碳排放
% 两种方法
    % 一个有碳配额
    % 一个没有
    % 是否考虑阶梯式碳排放
% 打个比方，允许你排放0.5kg/m3,但是现在实际排放0.8kg/m3，差值0.3就是你需要额外购买的碳排放额
E = sdpvar(1,24,'full'); %设定为碳排放额 变量
for i = 1:24
    C = [C,E(i) == 0.448.*(V_gb(i) + V_pgu(i))+0.448*E_eb(i)];
end
%% 运行成本目标函数
F_e = 0; % 运行成本
CO2 = 0; % 代表初始碳成本
F_g = 0; % 购气成本
%%%% 这里也可以动一动手脚看看变化趋势
for i = 1:24
    F_e = F_e + 0.05*(P_ES1_cha(1,i)+P_ES1_dis(1,i))+0.6*P_gb(i)+0.8*P_eb(i)+0.8*Hpgu(i);
    CO2 = CO2+1.6.*E(i);
    F_g =F_g + 1.45.*(V_gb(i)+V_pgu(i));
end
F = F_e + CO2 + F_g;
ops = sdpsettings('solver','gurobi','verbose',2);
optimize(C,F,ops)

%% 显示一些变量的取值
F=value(F);
CO2 = value(CO2);
F_g = value(F_g);
P_gb =  value(P_gb);
P_ES1_cha = value(P_ES1_cha);
P_ES1_dis = value(P_ES1_dis);
Hpgu = value(Hpgu);
S_1 = value(S_1);
F_g = value(F_g);

fprintf('总成本: %.2f \n',F);
fprintf('购碳成本: %.2f \n',CO2);
fprintf('购气成本: %.2f \n',F_g);

%% 画图
figure;
bar([P_gb',P_eb',-P_ES1_cha',P_ES1_dis',Hpgu',-Hload'],'stack') %阶梯图
legend('燃气锅炉','电锅炉','储热充热','储热放热','燃机热','热负荷'); %在坐标轴上添加图例
xlabel('时刻（t）');
ylabel('功率（kW）');

figure
ee = value(P_ES1_cha);
bar(ee,1,'stack')
hold on %继续画图
aa = value(P_ES1_dis);
bar(aa,1,'stack')
hold on
s = value(S_1);
plot(s,'b-*','LineWidth',2)
legend('充热','放热','SOC'); %在坐标轴上添加图例
xlabel('时刻（t）');
ylabel('功率（kW）');

figure
a =value(Hload);
plot(a,'r-*','LineWidth',2)
legend('热负荷');
xlabel('时刻（t）');
ylabel('功率（kW）');

toc

%% 写入excel
xlswrite('WIN.xlsx',double(P_gb)',1,'A2'); %第一张表的A2单元格开始输入
xlswrite('WIN.xlsx',double(P_eb)',1,'B2');
xlswrite('WIN.xlsx',double(Hpgu)',1,'C2');
xlswrite('WIN.xlsx',double(Ppgu)',1,'D2');
xlswrite('WIN.xlsx',double(Hload)',1,'E2');
















