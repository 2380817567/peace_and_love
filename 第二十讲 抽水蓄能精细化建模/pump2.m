%扩展后的抽水蓄能与光伏耦合调度模型，包含启停逻辑、弃光，适用于gurobi求解

clc;clear;

%% 基本参数设置
T = 24;   %时间步（小时）
dt = 3600;%每步秒数(1小时）

rho = 1000;  %水密度（kg/立方米）
g = 9.81;    %重力加速度（m/平方秒）
eta_t = 0.9;    %水轮机效率,还可以考虑变工况
eta_p = 0.85;   %水泵效率

% 水库参数
S_up = 1e5;     %上水库水平面积（平方米）
S_down = 1e5;   %下水库水平面积（平方米）
V_up_max = 1e6;   V_up_min = 0.2e6;
V_down_max = 1e6; V_down_min = 0.2e6;
Q_max = 50;     %最大抽水/发电流量（立方米/s）
V0_up = 0.5e6;V0_down = 0.5e6;
H_nom = 50;    %名义水头

% 光伏与负荷（示例数据）
P_PV_raw = [0 0 0 0 0 0 10 30 60 70 75 80 78 65 45 25 10 0 0 0 0 0 0 0]'; %MW
P_load = [50 48 45 44 43 42 45 50 60 75 85 90 92 90 85 80 70 65 60 55 52 50 48 46]'; %MW
price = [0.4*ones(6,1); 0.6*ones(6,1);1.0*ones(6,1);0.5*ones(6,1)];   % 元/kWh

%% 决策变量定义
Q_ch = sdpvar(T,1);         % 抽水流量（立方米/秒）
Q_dis = sdpvar(T,1);        % 防水流量（立方米/秒）
V_up = sdpvar(T,1);         % 上水库容积（立方米）
V_down = sdpvar(T,1);       % 下水库容积（立方米）
P_gen = sdpvar(T,1);        % 发电功率（MW）
P_pump = sdpvar(T,1);       % 抽水功率（MW）
P_grid = sdpvar(T,1);       % 电网购电
P_curt = sdpvar(T,1); 
u_pump = binvar(T,1);   u_gen = binvar(T,1);   %启停状态
P_PV_use = sdpvar(T,1);                        %实际利用的光伏功率
%% 约束构建
constraints = [];
for t = 1:T

    % 水库体积更新，类似于储能SOC
    if t==1
        constraints = [constraints,
            V_up(t) == V0_up + dt*(Q_ch(t) - Q_dis(t)),
            V_down(t) == V0_down + dt*(Q_dis(t) - Q_ch(t))];
    else
        constraints = [constraints,
            V_up(t) == V_up(t-1) + dt*(Q_ch(t) - Q_dis(t)),
            V_down(t) == V_down(t-1) + dt*(Q_dis(t) - Q_ch(t))];
    end

        %水库体积限制
        constraints = [constraints,
        V_up_min <= V_up(t) <= V_up_max,
        V_down_min <= V_down(t) <= V_down_max];

        %水流量限制
        constraints = [constraints,
                        0 <= Q_ch(t) <= Q_max * u_pump(t),
                        0 <= Q_dis(t) <= Q_max * u_gen(t)];

        % 近似线性功率表达
        constraints = [constraints,
            P_gen(t) == eta_t * rho * g * Q_dis(t) * H_nom / 1e6,
            P_pump(t) == rho * g * Q_ch(t) * H_nom / (eta_p * 1e6)];

        %光伏利用于弃电
        constraints = [constraints,
            0 <= P_PV_use(t) <=P_PV_raw(t),
            P_curt(t) == P_PV_raw(t) - P_PV_use(t),
            P_curt(t) >= 0];

    % 电力平衡
    constraints = [constraints,
        P_PV_use(t) + P_gen(t) + P_grid(t) == P_load(t) + P_pump(t)];
end

%% 目标函数：最小购电成本+弃光惩罚
alpha = 1;       % 电网购电成本权重
beta = 0.1;      % 弃光惩罚权重
Objective = sum(price .* P_grid) + beta * sum(P_curt);

%% 求解设置：gurobi
options = sdpsettings('solver','gurobi','verbose',1);

sol = optimize(constraints,Objective,options);

%% 结果输出
if sol.problem == 0
    disp("求解成功！");
    fprintf("总购电费用：%.2f 元\n",value(sum(price .* P_grid)));
    figure;
    subplot(3,1,1);
    plot(1:T,value(P_grid),'-o');hold on;
    plot(1:T,value(P_PV_use),'--');
    legend('购电','光伏'); ylabel('功率（MW）');
    title('光伏与购电');

    subplot(3,1,2);
    plot(1:T,value(P_gen),'-s');hold on;
    plot(1:T,value(P_pump),'-x');
    legend('发电','抽水'); ylabel('功率（MW）');
    title('抽水蓄能运行');

    subplot(3,1,3);
    plot(1:T,value(V_up)/1e6,'-^'); hold on;
    plot(1:T,value(V_down)/1e6,'v-');
    legend('上库水','下库水');ylabel('水库容积（百万m³）');
    xlabel('时间（h）'); title('水库状态');
else
    disp("求解失败！");
    disp(sol.info);
end