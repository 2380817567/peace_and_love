%这串代码输出的结果还可以了哈
%电、 热、冷、气、氢、储热、储冷、储氢、储气、储电，这应该算多元耦合了吧？其实要是真想让他们收敛还是挺不好调的
%第五讲 冷热电气氢建模  CCHP吸收式制冷，电制冷，蓄热，CCHP热，燃气锅炉，风光，购电,蓄电、CCHP发电
% 电解槽耗电，氢燃料电池，燃气耗电，燃气锅炉耗气，气网购气，气罐，氢罐，电制氢，氢燃料电池
% 有时间还可以让ai再给调调

clc
clear
tic   %%计时器，开始处为tic，结束处为toc
%%导入常数参数
%负荷参数
Pload=1.0*[252.25 250.75 256.25 256.75 256 277 301.25 324.5 331 356.25 375.25 399.5 406 422.25 426 413.5 386.5 375 355.75 324.5 301 275 255.75 249.5];
%风光预测最大出力
P_DG_max = [143.6 145.2 197.2 223.8 243.6 272.8 208.6 133.6 161.8 174.2 220 236.4 228.6 268.8 225.6 208.4 210.6 193.6 179 143.4 173 163.8 166.6 156.2];
P_PV_max = [0 0 0 0 0 0.1 25 53.6 69 91.2 111 117.8 130.8 142.4 137.6 125 113.4 83.6 51 0 0 0 0 0];
% 电价
%买电成本单价
e_p = 1.5*[0.36 0.36 0.36 0.36 0.36 0.36 0.36 0.36 0.64 0.64 0.64 0.78 0.78 0.78 0.78 0.64 0.64 0.64 0.78 0.78 0.78 0.78 0.64 0.64];
%卖电收益单价
%e_s=0.48;   不考虑了
%热力部分
Hload=0.7*[252.25 250.75 256.25 256.75 256 277 301.25 324.5 331 356.25 375.25 399.5 406 422.25 426 413.5 386.5 375 355.75 324.5 301 275 255.75 249.5];
%冷力部分
Cload = [151 148 139 128 135 141 156 167 171 170 174 166 168 157 155 148 141 138 132 140 141 138 136 142];
%气负荷
Gload = 1.1*[106 108 110 98 103 106 109 115 117 118 120 121 117 115 110 107 109 111 108 105 103 101 100 98];
%氢负荷
Qload = 0.5*[38 36 39 40 41 45 44 48 46 39 41 40 37 34  38 33 32 38 40 42 44 46 48 41];
%% 约束条件
C = [];   %%最好先定义好约束，不然容易忘
T = 24;   %定义时间一天24小时

%% 可再生能源约束
Ppv = sdpvar(1,24,'full'); %光伏输出电功率
Pwt = sdpvar(1,24,'full'); %风机输出电功率
for i=1:24
    C = [C,0<=Ppv(i)<=P_PV_max(i)];  %光伏约束
    C = [C,0<=Pwt(i)<=P_DG_max(i)];  %风机约束
end

%% 燃机建模
e_pgu = 0.3; %燃气轮机的发电效率
wh_pgu = 0.5; %燃气轮机的余热回收率
h_pgu = 0.45; %燃气轮机余热分流制热
c_pgu = 0.55; %燃气轮机余热分流制冷
l_pgu = 0.2; %燃气轮机热损失率
Hpgu = sdpvar(1,24,'full');%燃机热
Cpgu = sdpvar(1,24,'full');%燃机冷，吸收式制冷
Qpgu = sdpvar(1,24,'full'); %燃气的热输入
Ppgu = sdpvar(1,24,'full'); %燃机的发电功率
V_pgu = sdpvar(1,24,'full');
for t = 1:24
    C = [C,Hpgu(t) == Qpgu(t)*wh_pgu*h_pgu]; %燃气轮机热输出
    C = [C,Ppgu(t) == Qpgu(t)*e_pgu]; %燃气轮机电输出
    C = [C,0 <= Qpgu(t)<=500]; %燃气轮机上下限约束，后面会讲燃煤机组，非线性二次耗煤曲线
    C = [C,V_pgu(t) == Qpgu(t)/9.88]; %消耗天然气的体积
    C = [C,Cpgu(t) == Qpgu(t)*wh_pgu*c_pgu*0.9];  %0.9是制冷效率，一定不能忘记啊
end

%% 储电部分        为了养成好习惯，还是把'full'都加上吧
Ubat = 800; %首先定义储能的最大容量
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
   S_1(2:24) == S_1(1:23)+0.95*P_ES1_cha(2:24)-P_ES1_dis(2:24)/0.95 %0.95是储能效率
   ];

%% 电网交互
P_buy = sdpvar(1,24,'full'); %从电网购电
P_sell = sdpvar(1,24,'full'); %向电网卖电
for i=1:24
    C = [C,0<=P_buy(i)<=200]; %向运营商买电
 %不考虑这个了   C = [C,0<=P_sell(i)<=200]; %向运营商卖电
end

%% 储热部分，和储能类似      可以直接套用储电模板
Uhs = 500; % 首先定义储热的最大容量
P_hs_cha = sdpvar(1,24,'full');  %储热充电功率
P_hs_dis = sdpvar(1,24,'full');  %储热放电功率
S_hs = sdpvar(1,24,'full');%各储能的实时容量状态SOC
%引入充放标志二进制变量
B_hs_cha = binvar(1,24,'full');%充电标志
B_hs_dis = binvar(1,24,'full');%放电标志
C=[C,
   0<=P_hs_cha<=B_hs_cha*0.25*Uhs,%储电设备的最大充电电功率约束
   0<=P_hs_dis<=B_hs_dis*0.25*Uhs,%储电设备的最大放电电功率约束
   S_hs(1) == 0.3*Uhs, %储电设备的初始容量
   S_hs(24) == S_hs(1),  %首尾状态相同，在一个周期内，实现状态不变
   %充放状态唯一
   B_hs_cha+B_hs_dis<=1,
   %储能容量上下限约束
   0.1*Uhs <= S_hs <=0.9*Uhs,
   %储能容量变化约束，从第二时刻起每个时刻的容量
   S_hs(2:24) == S_hs(1:23)+0.95*P_hs_cha(2:24)-P_hs_dis(2:24)/0.9  %0.9是储能效率
   ];

%% 燃气锅炉
P_gb = sdpvar(1,24,'full');
V_gb = sdpvar(1,24,'full');
for i = 1:24
    C = [C,0 <= P_gb(i) <= 180];
    C = [C,V_gb(i) == P_gb(i)/0.9/0.88]; % 0.9是燃气锅炉的效率
end

%% 电锅炉
P_eb = sdpvar(1,24,'full');
E_eb = sdpvar(1,24,'full'); %热电耦合，电锅炉消耗的电，0.95是电锅炉的制热效率
for i = 1:24
    C = [C,0<=P_eb(i)<=180];
    C = [C,E_eb(i) == P_eb(i)/0.95];
end

%% 储气部分，和储能类似      可以直接套用储电模板
Ugas = 500; % 首先定义储气的最大容量
P_GAS_cha = sdpvar(1,24,'full');  %储能充电功率
P_GAS_dis = sdpvar(1,24,'full');  %储能放电功率
S_GAS = sdpvar(1,24,'full');%各储能的实时容量状态SOC
%引入充放标志二进制变量
B_GAS_cha = binvar(1,24,'full');%充电标志
B_GAS_dis = binvar(1,24,'full');%放电标志
C=[C,
   0<=P_GAS_cha<=B_GAS_cha*0.25*Ugas,%储电设备的最大充电电功率约束
   0<=P_GAS_dis<=B_GAS_dis*0.25*Ugas,%储电设备的最大放电电功率约束
   S_GAS(1) == 0.3*Ugas, %储电设备的初始容量
   S_GAS(24) == S_GAS(1),  %首尾状态相同，在一个周期内，实现状态不变
   %充放状态唯一
   B_GAS_cha+B_GAS_dis<=1,
   %储气容量上下限约束
   0.1*Ugas <= S_GAS <=0.9*Ugas,
   %储能容量变化约束，从第二时刻起每个时刻的容量
   S_GAS(2:24) == S_GAS(1:23)+0.95*P_GAS_cha(2:24)-P_GAS_dis(2:24)/0.9  %0.9是储能效率
   ];
%% 气网
Pbuy_gas = sdpvar(1,24,'full');
for i =1:24
    C = [C,0<=Pbuy_gas(i) <= 150];

end

%% 电制氢
Ph2 = sdpvar(1,24,'full'); % 产氢
Pdj = sdpvar(1,24,'full'); % 电制氢设备功率
Pdj_e = sdpvar(1,24,'full'); % 消耗电量 
for i =1:24
    C = [C,0<=Pdj(i)<=100];
    C = [C,Pdj_e(i) == Pdj(i)/0.8];
    C = [C,Ph2(i) == 0.9*Pdj(i)];
end

%% 燃料电池 fuel cell
Pfc = sdpvar(1,24,'full');   %燃料电池发电量
Pfc_h2 = sdpvar(1,24,'full');%燃料电池耗氢
for i =1:24
     C = [C,0<=Pfc(i)<=5];
    C = [C,Pfc(i) == 0.85*Pfc_h2(i)];  %0.85就是个系数，可以随便改
end
%% 储氢部分，和储能类似      可以直接套用储电模板
Uh2 = 200; % 首先定义储气的最大容量
P_H2_cha = sdpvar(1,24,'full');  %储能充电功率
P_H2_dis = sdpvar(1,24,'full');  %储能放电功率
S_H2 = sdpvar(1,24,'full');%各储能的实时容量状态SOC
%引入充放标志二进制变量
B_H2_cha = binvar(1,24,'full');%充电标志
B_H2_dis = binvar(1,24,'full');%放电标志
C=[C,
   0<=P_H2_cha<=B_H2_cha*0.25*Uh2,%储电设备的最大充电电功率约束
   0<=P_H2_dis<=B_H2_dis*0.25*Uh2,%储电设备的最大放电电功率约束
   S_H2(1) == 0.3*Uh2, %储电设备的初始容量
   S_H2(24) == S_H2(1),  %首尾状态相同，在一个周期内，实现状态不变
   %充放状态唯一
   B_H2_cha+B_H2_dis<=1,
   %储气容量上下限约束
   0.1*Uh2 <= S_H2 <=0.9*Uh2,
   %储能容量变化约束，从第二时刻起每个时刻的容量
   S_H2(2:24) == S_H2(1:23)+0.95*P_H2_cha(2:24)-P_H2_dis(2:24)/0.9  %0.9是储能效率
   ];

%% 电制冷
Pec = sdpvar(1,24,'full');%电制冷
Pec_e = sdpvar(1,24,'full');%电制冷耗电
COP = 3; %COP制冷值
for i =1:24
    C = [C,0<=Pec(i)<=200];
    C = [C,Pec_e(i) == Pec(i)/3];
end

%% 功率平衡约束
for i =1:24
    C = [C,Ppv(i)+Pwt(i)+P_buy(i)+Ppgu(i)+P_ES1_dis(i)+Pfc(i) == P_ES1_cha(i)+Pload(i)+Pdj_e(i)]; %电平衡约束  ES及electric store
    C = [C,Hpgu(i)+P_gb(i)+P_eb(i)+P_hs_dis(i) == P_hs_cha(i)+Hload(i)];%热平衡约束
    C = [C,P_GAS_dis(i)+Pbuy_gas(i) == Gload(i)+P_GAS_cha(i)+V_gb(i)+V_pgu(i)];%气平衡约束
    C = [C,P_H2_dis(i)+Ph2(i) == Qload(i)+P_H2_cha(i)+Pfc_h2(i)];%氢平衡约束
    C = [C,Pec(i)+Cpgu(i) == Cload(i)];  %冷衡约束
end

%% 运行成本目标函数 运行成本减去卖电收益
F_e = 0; %运行成本
F_buy_e = 0; %购电成本
F_buy_g = 0;%购气成本
for i = 1:24
    F_buy_g = F_buy_g+1.45*Pbuy_gas(i);
    F_buy_e = F_buy_e+ e_p(i)*P_buy(i);
    F_e = F_e +0.8*Pec(i)+ 0.8*Pfc(i) + 0.05*(P_H2_cha(1,i)+P_H2_dis(1,i))+0.8*Pdj(i)+0.06*(P_ES1_cha(1,i)+P_ES1_dis(1,i))+0.6*Ppv(i)*P_buy(i)+0.05*(P_ES1_cha(1,i)+P_ES1_dis(1,i))+0.6*P_gb(i)+0.8*P_eb(i)+0.8*Qpgu(i)+0.01*(P_GAS_cha(1,i)+P_GAS_dis(1,i));  %这里使用点乘，因为是常数乘数组想得到常数
end
F = F_e+F_buy_e+F_buy_g;
ops = sdpsettings('solver','gurobi','verbose',2);   %参数指定程序使用gurobi求解器
optimize(C,F,ops)

%% 显示一些变量的取值
Ppv = value(Ppv);
Pwt = value(Pwt);
P_ES1_cha = value(P_ES1_cha);
P_ES1_dis = value(P_ES1_dis);
P_buy = value(P_buy);
P_sell = value(P_sell);
S_1 = value(S_1);
F = value(F);
S_H2 = value(S_H2);
Pfc  = value(Pfc);

%% 画图
figure;
bar([Ppgu',Pwt',Ppv',-P_ES1_cha',P_ES1_dis',P_buy',Pfc',-Pdj_e',-( P_eb/0.9)',-Pload'],'stack')%阶梯图
legend('燃机出力','风实际出力','光伏实际出力','储能充电','储能放电','购电','燃料电池','电解槽耗电','电锅炉耗电','电负荷');
xlabel('时刻（t）');
ylabel('功率（kW）');

figure;
bar([P_gb',P_eb',-P_hs_cha',P_hs_dis',Hpgu',-Hload'],'stack') %阶梯图
legend('燃气锅炉','电锅炉','储热充热','储热放热','燃机热','热负荷'); %在坐标轴上添加图例
xlabel('时刻（t）');
ylabel('功率（kW）');

figure;
bar([Pec',Cpgu',-Cload'],'stack') %阶梯图
legend('电制冷','燃机吸收式制冷','冷负荷'); %在坐标轴上添加图例
xlabel('时刻（t）');
ylabel('功率（kW）');

figure;
bar([Pbuy_gas',-P_GAS_cha',P_GAS_dis',-V_gb',-V_pgu',-Gload'],'stack') %阶梯图
legend('购气','储气','放气','燃气锅炉耗气','燃气轮机耗气','气负荷'); %在坐标轴上添加图例
xlabel('时刻（t）');
ylabel('功率（kW）');

figure;
bar([Ph2',-P_H2_cha',P_H2_dis',-Pfc_h2',-Qload'],'stack') %阶梯图
legend('电解槽制氢','储氢','放氢','燃气锅炉耗氢','氢负荷'); %在坐标轴上添加图例
xlabel('时刻（t）');
ylabel('功率（kW）');

figure;
ee = value([P_ES1_cha]);
bar(ee,1,'stack')
hold on
aa = value([P_ES1_dis]);
bar(aa,1,'stack')
hold on
s = value([S_1]);
plot(s,'g*-','LineWidth',2)   %plot是曲线
legend('充电','放电','SOC'); %在坐标轴上添加图例
xlabel('时刻（t）');
ylabel('功率（kW）');

figure;
ee = value(P_hs_cha);
bar(ee,1,'stack')
hold on %继续画图
aa = value(P_hs_dis);
bar(aa,1,'stack')
hold on
s = value(S_hs);
plot(s,'b-*','LineWidth',2)
legend('充热','放热','SOC'); %在坐标轴上添加图例
xlabel('时刻（t）');
ylabel('功率（kW）');

figure;
ee = value(P_GAS_cha);
bar(ee,1,'stack')
hold on %继续画图
aa = value(P_GAS_dis);
bar(aa,1,'stack')
hold on
s = value(S_GAS);
plot(s,'b-*','LineWidth',2)
legend('充气','放气','SOC'); %在坐标轴上添加图例
xlabel('时刻（t）');
ylabel('功率（kW）');

figure;
ee = value(P_H2_cha);
bar(ee,1,'stack')
hold on %继续画图
aa = value(P_H2_dis);
bar(aa,1,'stack')
hold on
s = value(S_H2);
plot(s,'b-*','LineWidth',2)
legend('充氢','放氢','SOC'); %在坐标轴上添加图例
xlabel('时刻（t）');
ylabel('功率（kW）');


toc



