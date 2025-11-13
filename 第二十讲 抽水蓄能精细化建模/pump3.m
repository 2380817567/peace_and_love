%抽水蓄能+光伏调度模型，采用非线性建模+连续启停逻辑近似 + 弃光，IPOPT求解
%我发现pump3.m中的主要问题是：模型包含非线性约束（功率计算中Q_dis(t)*H(t)和Q_ch(t)*H(t)项），
% 但却使用了Gurobi求解器，而Gurobi主要适用于线性规划问题。
% 需要将求解器改为支持非线性优化的IPOPT。
%求解器的问题，gurobi解决不了非线性的问题

clc;clear;

%% 时间与参数设置
T = 24;   %时间步（小时）
dt = 3600;%每步秒数(1小时）

rho = 1000;  %水密度（kg/立方米）
g = 9.81;    %重力加速度（m/平方秒）
eta_t = 0.9;    %水轮机效率
eta_p = 0.85;   %水泵效率

% 水库参数
S_up = 1e5;     %上水库水平面积（平方米）
S_down = 1e5;   %下水库水平面积（平方米）
V_up_max = 1e6;   V_up_min = 0.2e6;
V_down_max = 1e6; V_down_min = 0.2e6;
Q_max = 50;     %最大抽水/发电流量（立方米/s）

% 初始水位
V0_up = 0.5e6;
V0_down = 0.5e6;

% 光伏与负荷（示例数据）
P_PV_raw = [0 0 0 0 0 0 10 30 60 70 75 80 78 65 45 25 10 0 0 0 0 0 0 0]'; %MW
P_load = [50 48 45 44 43 42 45 50 60 75 85 90 92 90 85 80 70 65 60 55 52 50 48 46]'; %MW
price = [0.4*ones(6,1); 0.6*ones(6,1);1.0*ones(6,1);0.5*ones(6,1)];   % 元/kWh
%% 决策变量定义
Q_ch = sdpvar(T,1);         % 抽水流量（立方米/秒）
Q_dis = sdpvar(T,1);        % 防水流量（立方米/秒）
V_up = sdpvar(T,1);         % 上水库容积（立方米）
V_down = sdpvar(T,1);       % 下水库容积（立方米）
H = sdpvar(T,1);            % 水头（m）
P_gen = sdpvar(T,1);        % 发电功率（MW）
P_pump = sdpvar(T,1);       % 抽水功率（MW）
P_grid = sdpvar(T,1);       % 电网购电
P_curt = sdpvar(T,1); 
P_PV_use = sdpvar(T,1); 
z = sdpvar(T,1);        %连续启停控制：0~1之间

%% 非线性约束
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
    
    %有效水头（动态计算）
    H_up = V_up(t)/S_up;
    H_down = V_down(t)/S_down;
    constraints = [constraints,H(t) == H_up - H_down];

    % 功率计算（非线性）
        constraints = [constraints,
            P_gen(t) == eta_t * rho * g * Q_dis(t) * H(t) / 1e6,
            P_pump(t) == rho * g * Q_ch(t) * H(t) / (eta_p * 1e6)];

        %水库和流量限制
        constraints = [constraints,
        V_up_min <= V_up(t) <= V_up_max,
        V_down_min <= V_down(t) <= V_down_max,
        0 <= Q_ch(t) <= Q_max * z(t),
        0 <= Q_dis(t) <= Q_max * (1 - z(t)),
        0 <= z(t) <= 1];

      
        %光伏利用+弃电
        constraints = [constraints,
            0 <= P_PV_use(t) <=P_PV_raw(t),
            P_curt(t) == P_PV_raw(t) - P_PV_use(t),
            P_curt(t) >= 0];

    % 电力平衡
    constraints = [constraints,
        P_PV_use(t) + P_gen(t) + P_grid(t) == P_load(t) + P_pump(t),
        P_grid(t) >= 0];
end

%% 目标函数：购电+弃光惩罚
alpha = 1;       % 电网购电成本权重
beta = 0.1;      % 弃光惩罚权重
Objective = sum(price .* P_grid) + beta * sum(P_curt);
%% 初始值设置（可选）
assign(Q_ch, 10*ones(T,1));
assign(Q_dis, 10*ones(T,1));
assign(V_up, V0_up*ones(T,1));
assign(V_down, V0_down*ones(T,1));
assign(H,10*ones(T,1));
assign(z,0.5*ones(T,1));

%% 求解器设置：（非线性+连续变量）
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