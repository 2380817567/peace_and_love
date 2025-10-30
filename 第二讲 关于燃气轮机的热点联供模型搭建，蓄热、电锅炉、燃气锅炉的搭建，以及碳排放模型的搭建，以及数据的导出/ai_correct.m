% 这ai整的小图是真好看啊

clc
clear

tic

% 热负荷数据
Hload=[252.25 250.75 256.25 256.75 256 277 301.25 324.5 331 356.25 375.25 399.5 406 422.25 426 413.5 386.5 375 355.75 324.5 301 275 255.75 249.5];

%% 系统参数设置
T = 24; % 时间周期
Ubat = 500; % 储热装置容量上限 (kWh)

% 燃机参数
e_pgu = 0.3;   % 燃气轮机的发电效率
wh_pgu = 0.5;  % 燃气轮机的余热回收率
h_pgu = 0.45;  % 燃气轮机余热分流制热
c_pgu = 0.55;  % 燃气轮机余热分流制冷
l_pgu = 0.2;   % 燃气轮机热损失率

% 储热参数
eta_cha = 0.95; % 充电效率
eta_dis = 0.9;  % 放电效率
SOC_min = 0.1;  % 最小SOC
SOC_max = 0.9;  % 最大SOC
P_ES_max = 0.25; % 最大充放电功率比例

% 成本参数
cost_ES = 0.05;  % 储热系统运行成本系数
cost_gb = 0.6;   % 燃气锅炉运行成本系数
cost_eb = 0.8;   % 电锅炉运行成本系数
cost_hpgu = 0.8; % 燃机热成本系数
cost_CO2 = 1.6;  % 碳排放成本系数
cost_gas = 1.45; % 天然气成本系数

%% 定义优化变量
% 燃机相关变量
Hpgu = sdpvar(1,T,'full');  % 燃气轮机热输出
Qpgu = sdpvar(1,T,'full');  % 燃气轮机燃料输入
Ppgu = sdpvar(1,T,'full');  % 燃气轮机电输出
V_pgu = sdpvar(1,T,'full'); % 消耗天然气的体积

% 储热系统变量
P_ES1_cha = sdpvar(1,T,'full');  % 储能充电功率
P_ES1_dis = sdpvar(1,T,'full');  % 储能放电功率
S_1 = sdpvar(1,T,'full');        % 储能SOC
B_ES1_cha = binvar(1,T,'full');  % 充电标志
B_ES1_dis = binvar(1,T,'full');  % 放电标志

% 燃气锅炉变量
P_gb = sdpvar(1,T,'full');
V_gb = sdpvar(1,T,'full');

% 电锅炉变量
P_eb = sdpvar(1,T,'full');
E_eb = sdpvar(1,T,'full');

% 碳排放变量
E = sdpvar(1,T,'full');

%% 构建约束条件
C = [];

% 燃机约束
for t = 1:T
    C = [C, Hpgu(t) == Qpgu(t)*wh_pgu*h_pgu]; % 燃气轮机热输出
    C = [C, Ppgu(t) == Qpgu(t)*e_pgu];       % 燃气轮机电输出
    C = [C, 0 <= Qpgu(t) <= 500];            % 燃气轮机燃料输入上下限
    C = [C, V_pgu(t) == Qpgu(t)/9.88];       % 消耗天然气的体积
end

% 储热系统约束
for t = 1:T
    C = [C, 0 <= P_ES1_cha(t) <= B_ES1_cha(t)*P_ES_max*Ubat]; % 最大充电功率约束
    C = [C, 0 <= P_ES1_dis(t) <= B_ES1_dis(t)*P_ES_max*Ubat]; % 最大放电功率约束
end
C = [C, S_1(1) == 0.3*Ubat];                         % 初始SOC
C = [C, S_1(T) == S_1(1)];                           % 首尾SOC相同
C = [C, B_ES1_cha + B_ES1_dis <= 1];                 % 充放电互斥
C = [C, SOC_min*Ubat <= S_1 <= SOC_max*Ubat];        % SOC上下限
% 储能容量变化约束
for t = 2:T
    C = [C, S_1(t) == S_1(t-1) + eta_cha*P_ES1_cha(t) - P_ES1_dis(t)/eta_dis];
end

% 燃气锅炉约束
for i = 1:T
    C = [C, 0 <= P_gb(i) <= 150];
    C = [C, V_gb(i) == P_gb(i)/0.9/0.88]; % 燃气锅炉效率
end

% 电锅炉约束
for i = 1:T
    C = [C, 0 <= P_eb(i) <= 150];
    C = [C, E_eb(i) == P_eb(i)/0.95]; % 电锅炉制热效率
end

% 热功率平衡约束
for i = 1:T
    C = [C, Hpgu(i) + P_gb(i) + P_eb(i) + P_ES1_dis(i) == P_ES1_cha(i) + Hload(i)];
end

% 碳排放约束
for i = 1:T
    C = [C, E(i) == 0.448*(V_gb(i) + V_pgu(i)) + 0.448*E_eb(i)];
end

%% 目标函数
F_e = 0; % 运行成本
CO2 = 0; % 碳排放成本
F_g = 0; % 购气成本

for i = 1:T
    F_e = F_e + cost_ES*(P_ES1_cha(i) + P_ES1_dis(i)) + ...
          cost_gb*P_gb(i) + cost_eb*P_eb(i) + cost_hpgu*Hpgu(i);
    CO2 = CO2 + cost_CO2*E(i);
    F_g = F_g + cost_gas*(V_gb(i) + V_pgu(i));
end
F = F_e + CO2 + F_g;

%% 求解优化问题
ops = sdpsettings('solver','gurobi','verbose',2);
sol = optimize(C, F, ops);

%% 结果分析和可视化
if sol.problem == 0 % 求解成功
    fprintf('优化求解成功！\n');
    
    % 获取变量值
    F_val = value(F);
    P_gb_val = value(P_gb);
    P_ES1_cha_val = value(P_ES1_cha);
    P_ES1_dis_val = value(P_ES1_dis);
    Hpgu_val = value(Hpgu);
    S_1_val = value(S_1);
    F_g_val = value(F_g);
    P_eb_val = value(P_eb);
    Hload_val = Hload;
    Ppgu_val = value(Ppgu);
    V_gb_val = value(V_gb);
    V_pgu_val = value(V_pgu);
    E_val = value(E);
    
    % 计算各项成本
    F_e_val = sum(cost_ES*(P_ES1_cha_val + P_ES1_dis_val) + ...
                  cost_gb*P_gb_val + cost_eb*P_eb_val + cost_hpgu*Hpgu_val);
    CO2_val = sum(cost_CO2*E_val);
    F_g_val = sum(cost_gas*(V_gb_val + V_pgu_val));
    
    fprintf('总成本: %.2f 元\n', F_val);
    fprintf('运行成本: %.2f 元\n', F_e_val);
    fprintf('碳排放成本: %.2f 元\n', CO2_val);
    fprintf('购气成本: %.2f 元\n', F_g_val);
    fprintf('总碳排放量: %.2f kg\n', sum(E_val));
    
    %% 可视化结果
    figure('Position', [100, 100, 1400, 900]);
    
    % 子图1：热功率平衡
    subplot(2,3,1);
    data = [P_gb_val', P_eb_val', -P_ES1_cha_val', P_ES1_dis_val', Hpgu_val', -Hload_val'];
    bar(data, 'stacked');
    legend('燃气锅炉', '电锅炉', '储热充热', '储热放热', '燃机热', '热负荷', 'Location', 'best');
    xlabel('时刻（t）');
    ylabel('功率（kW）');
    title('热功率平衡');
    grid on;
    
    % 子图2：储热系统状态
    subplot(2,3,2);
    bar(1:T, P_ES1_cha_val, 'b', 'FaceAlpha', 0.6);
    hold on;
    bar(1:T, -P_ES1_dis_val, 'r', 'FaceAlpha', 0.6);
    plot(1:T, S_1_val, 'g-o', 'LineWidth', 2, 'MarkerSize', 6);
    legend('充热功率', '放热功率', 'SOC', 'Location', 'best');
    xlabel('时刻（t）');
    ylabel('功率（kW）/ 容量（kWh）');
    title('储热系统状态');
    grid on;
    
    % 子图3：热负荷曲线
    subplot(2,3,3);
    plot(1:T, Hload_val, 'r-o', 'LineWidth', 2, 'MarkerSize', 6);
    xlabel('时刻（t）');
    ylabel('功率（kW）');
    title('热负荷曲线');
    grid on;
    
    % 子图4：各热源出力对比
    subplot(2,3,4);
    plot(1:T, P_gb_val, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 4);
    hold on;
    plot(1:T, P_eb_val, 'c-s', 'LineWidth', 1.5, 'MarkerSize', 4);
    plot(1:T, Hpgu_val, 'm-^', 'LineWidth', 1.5, 'MarkerSize', 4);
    plot(1:T, Hload_val, 'r--', 'LineWidth', 2, 'MarkerSize', 4);
    legend('燃气锅炉', '电锅炉', '燃机热', '热负荷', 'Location', 'best');
    xlabel('时刻（t）');
    ylabel('功率（kW）');
    title('各热源出力对比');
    grid on;
    
    % 子图5：碳排放分布
    subplot(2,3,5);
    bar(1:T, E_val, 'FaceColor', [0.8 0.2 0.2]);
    xlabel('时刻（t）');
    ylabel('碳排放量（kg）');
    title('各时刻碳排放量');
    grid on;
    
    % 子图6：成本构成分析
    subplot(2,3,6);
    costs = [F_e_val, CO2_val, F_g_val];
    cost_names = {'运行成本', '碳排放成本', '购气成本'};
    pie(costs, cost_names);
    title('成本构成分析');
    
    %% 详细结果输出
    fprintf('\n=== 详细结果 ===\n');
    fprintf('各时段燃气锅炉出力 (kW): \n');
    fprintf('%.2f ', P_gb_val); fprintf('\n');
    fprintf('各时段电锅炉出力 (kW): \n');
    fprintf('%.2f ', P_eb_val); fprintf('\n');
    fprintf('各时段燃机热出力 (kW): \n');
    fprintf('%.2f ', Hpgu_val); fprintf('\n');
    fprintf('各时段储能充电功率 (kW): \n');
    fprintf('%.2f ', P_ES1_cha_val); fprintf('\n');
    fprintf('各时段储能放电功率 (kW): \n');
    fprintf('%.2f ', P_ES1_dis_val); fprintf('\n');
    fprintf('各时段储能SOC (kWh): \n');
    fprintf('%.2f ', S_1_val); fprintf('\n');
    
    %% 能源效率分析
    total_heat_supply = sum(P_gb_val + P_eb_val + Hpgu_val);
    total_heat_demand = sum(Hload_val);
    heat_balance_error = abs(total_heat_supply - total_heat_demand) / total_heat_demand * 100;
    
    fprintf('\n=== 能源平衡分析 ===\n');
    fprintf('总热供应: %.2f kW\n', total_heat_supply);
    fprintf('总热需求: %.2f kW\n', total_heat_demand);
    fprintf('热平衡误差: %.2f%%\n', heat_balance_error);
    
    %% 储能利用率分析
    charge_energy = sum(P_ES1_cha_val);
    discharge_energy = sum(P_ES1_dis_val);
    efficiency = discharge_energy / charge_energy * 100;
    
    fprintf('=== 储能系统分析 ===\n');
    fprintf('总充电量: %.2f kWh\n', charge_energy);
    fprintf('总放电量: %.2f kWh\n', discharge_energy);
    fprintf('储能系统效率: %.2f%%\n', efficiency);
    
else
    fprintf('优化求解失败！\n');
    fprintf('错误代码: %d\n', sol.problem);
    fprintf('错误信息: %s\n', sol.info);
end

toc



