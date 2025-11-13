%电网-省级电网排放因子/区域电网
%燃机-天然气排放因子

clc
clear
tic   %%计时器，开始处为tic，结束处为toc
%%导入常数参数
%负荷参数
Pload=[252.25 250.75 256.25 256.75 256 277 301.25 324.5 331 356.25 375.25 399.5 406 422.25 426 413.5 386.5 375 355.75 324.5 301 275 255.75 249.5];
%风光预测最大出力
P_DG_max = [143.6 145.2 197.2 223.8 243.6 272.8 208.6 133.6 161.8 174.2 220 236.4 228.6 268.8 225.6 208.4 210.6 193.6 179 143.4 173 163.8 166.6 156.2];
P_PV_max = [0 0 0 0 0 0.1 25 53.6 69 91.2 111 117.8 130.8 142.4 137.6 125 113.4 83.6 51 0 0 0 0 0];
% 电价
%买电成本单价
e_p = [0.36 0.36 0.36 0.36 0.36 0.36 0.36 0.36 0.64 0.64 0.64 0.78 0.78 0.78 0.78 0.64 0.64 0.64 0.78 0.78 0.78 0.78 0.64 0.64];
%卖电收益单价
e_s=0.48;

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

%% 燃机约束
Pg  =  sdpvar(1,24,'full');
for i=1:24
    C = [C,0<=Pg(i)<=150];  
end

%% 储电部分        为了养成好习惯，还是把'full'都加上吧
Ubat = 500; %首先定义储能的最大容量
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
    C = [C,0<=P_sell(i)<=200]; %向运营商卖电
end

%% 功率平衡约束
for i =1:24
    C = [C,Ppv(i)+Pwt(i)+P_buy(i)+P_ES1_dis(i)+Pg(i) == P_sell(i)+P_ES1_cha(i)+Pload(i)]; %电平衡约束
end

%% 碳排放约束
E1 =  sdpvar(1,24,'full');
E2 =  sdpvar(1,24,'full');
Ebuy = sdpvar(1,24,'full');
Eg = sdpvar(1,24,'full');


% %零基准线
% for i=1:24 
%     C = [C,Ebuy(i) == P_buy(i)*0.9029]; 
%     C = [C,Eg(i) ==Pg(i)*0.45];
%     C = [C,E1(i) == Ebuy(i)+Eg(i)];
% end


%有初始碳配额
for i=1:24 
    C = [C,Ebuy(i) == P_buy(i)*(0.9029-0.5)]; 
    C = [C,Eg(i) ==Pg(i)*(0.45-0.2)];
    C = [C,E2(i) == Ebuy(i)+Eg(i)];
end
TotalE = sum(E2);
%% 运行成本目标函数 运行成本减去卖电收益
F_e = 0;
CO2 = 0;
for i = 1:24
    CO2 = CO2 + 0.2*100 + 0.24*200 + 0.288*(TotalE-300);   %阶梯碳价
    F_e = F_e + 0.1*(P_ES1_cha(1,i)+P_ES1_dis(1,i))+0.6*Ppv(i)+0.5*Pg(i)+0.5*Pwt(i)+e_p(i)*P_buy(i)-e_s.*P_sell(i);  %这里使用点乘，因为是常数乘数组想得到常数
end
F = F_e + CO2;
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
CO2 = value(CO2);

fprintf('碳排放成本')
CO2

%% 画图
figure;
bar([Pg',Pwt',Ppv',-P_ES1_cha',P_ES1_dis',P_buy',-P_sell',-Pload'],'stack')%阶梯图
legend('燃机出力','风实际出力','光伏实际出力','储能充电','储能放电','购电','卖电','电负荷'); %
xlabel('时刻（t）');
ylabel('功率（kW）');

figure
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

figure
s = value([Ppv]);
plot(s,'g-*','LineWidth',2)
hold on
a = value([P_PV_max]);
plot(a,'r-*','LineWidth',2)
legend('光伏预测最大出力','光伏预测最大出力'); % 在坐标轴上添加图例
xlabel('时刻（t）');
ylabel('功率（kW）');

figure
s = value([Pwt]);
plot(s,'g-*','LineWidth',2)
hold on
a = value([P_DG_max]);
plot(a,'r-*','LineWidth',2)
legend('风机实际消纳','风机预测最大出力');
xlabel('时刻（t）');
ylabel('功率（kW）');


figure
s = value([P_PV_max]);
plot(s,'r-*','LineWidth',2)
hold on
a = value([P_DG_max]);
plot(a,'g-*','LineWidth',2)
legend('光伏预测最大出力','风机预测最大出力'); 
xlabel('时刻（t）');
ylabel('功率（kW）');

figure
s = value([Pload]);
plot(a,'r-*','LineWidth',2)
legend('电负荷');
xlabel('时刻（t）');
ylabel('功率（kW）');

toc 