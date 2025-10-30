clc;
clear;

times = 5000; %蒙特卡洛仿真次数
baseMVA = 100000;

% 光伏有功服从Beta分布
% Beta分布的两个形状参数
a_pv = 0.6869;
b_pv = 2.1320;
% 光伏发电相关参数：组件总面积S_pv、光电转化率prey_pv、最大光强rmax（MW/m2）
S_pv = 10;
prey_pv = 0.14;
rmax = 700;
% 光伏有功出力样本
pv_samp = betarnd(a_pv, b_pv, 1, times);
Ppv_samp = pv_samp * rmax * S_pv * prey_pv / baseMVA;

% Weibull分布的两个形状参数
k_wt = 1.637;
c_wt = 5.218;
wt_samp = wblrnd(c_wt, k_wt, 1, times); %产生服从weibull分布的样本
PN_wt = 1000;
vci = 3;
vN = 13;
vco = 25;

% 预先初始化风电出力样本
Pwt_samp = zeros(1, times);
for i = 1:times  %得到风电出力的样本
    if wt_samp(i) < vci
        Pwt_samp(i) = 0;
    elseif wt_samp(i) > vci && wt_samp(i) < vN
        Pwt_samp(i) = (wt_samp(i) - vci) / (vN - vci) * PN_wt;
        if Pwt_samp(i) > PN_wt
            Pwt_samp(i) = PN_wt;
        end
    elseif wt_samp(i) > vN && wt_samp(i) < vco
        Pwt_samp(i) = PN_wt;
    else % wt_samp(i) > vco
        Pwt_samp(i) = 0;
    end
end
Pwt_samp = Pwt_samp / baseMVA;

% 模拟33节点系统数据（因为缺少case33bw文件）
% 创建简化的33节点数据
mpc = struct();
mpc.bus = zeros(33, 13);
for i = 1:33
    mpc.bus(i, 1) = i; % bus number
    mpc.bus(i, 2) = 1; % bus type (PQ)
    mpc.bus(i, 3) = 0.1 + 0.05 * rand(); % real power demand (MW)
    mpc.bus(i, 4) = 0.05 + 0.02 * rand(); % reactive power demand (MVAR)
    mpc.bus(i, 5) = 1.0; % shunt conductance
    mpc.bus(i, 6) = 0.0; % shunt susceptance
    mpc.bus(i, 7) = 1.05; % area number
    mpc.bus(i, 8) = 1.0; % voltage magnitude
    mpc.bus(i, 9) = 0; % voltage angle
    mpc.bus(i, 10) = 1.05; % maximum voltage
    mpc.bus(i, 11) = 0.95; % minimum voltage
    mpc.bus(i, 12) = 2; % Vmax for generator buses
    mpc.bus(i, 13) = 0; % base KV
end

% 创建简化的支路数据
mpc.branch = zeros(32, 13);
for i = 1:32
    mpc.branch(i, 1) = i; % from bus
    mpc.branch(i, 2) = i+1; % to bus
    mpc.branch(i, 3) = 0.05 + 0.02*rand(); % resistance
    mpc.branch(i, 4) = 0.1 + 0.05*rand(); % reactance
    mpc.branch(i, 5) = 0.01 + 0.005*rand(); % conductance
    mpc.branch(i, 6) = 0.02 + 0.01*rand(); % susceptance
    mpc.branch(i, 7) = 1.0; % transformer ratio
    mpc.branch(i, 8) = 0; % transformer phase shift
    mpc.branch(i, 9) = 1.0; % maximum current rating
    mpc.branch(i, 10) = 1.0; % maximum current rating
    mpc.branch(i, 11) = 1.0; % maximum current rating
    mpc.branch(i, 12) = 0; % transformer indicator
    mpc.branch(i, 13) = 1; % branch status
end

% 提取负荷数据
P = mpc.bus(:, 3);
Q = mpc.bus(:, 4);
ld_ero = 0.05; %正态分布的方差

% 预先初始化负荷样本矩阵
Pld_samp = zeros(33, times);
Qld_samp = zeros(33, times);

for k = 1:33
    Pld_samp(k, :) = normrnd(P(k), P(k) * ld_ero, 1, times);    %生成服从正态分布的随机数
    Qld_samp(k, :) = normrnd(Q(k), Q(k) * ld_ero, 1, times);    %修正：使用Q(k)作为标准差的基础
end

% 初始化结果存储矩阵
line_flow = zeros(times, 32);
Vbus = zeros(times, 33);

% 蒙特卡洛仿真主循环
for i = 1:times
    % 创建当前仿真步的系统数据副本
    current_mpc = mpc;
    
    % 更新该次潮流计算的负荷数据
    current_mpc.bus(:, 3) = Pld_samp(:, i)'; 
    current_mpc.bus(:, 4) = Qld_samp(:, i)'; 

    % 更新接入的光伏功率 (节点14)
    current_mpc.bus(14, 3) = current_mpc.bus(14, 3) - Ppv_samp(1, i); 
    current_mpc.bus(14, 4) = current_mpc.bus(14, 4) - Ppv_samp(1, i) * 0.484;

    % 更新接入的风机功率 (节点30)
    current_mpc.bus(30, 3) = current_mpc.bus(30, 3) - Pwt_samp(1, i); 
    current_mpc.bus(30, 4) = current_mpc.bus(30, 4) - Pwt_samp(1, i) * 0.484;

    % 执行潮流计算 (使用简化的计算逻辑，因为缺少runpf函数)
    % 这里用模拟的潮流计算结果替代
    % 实际应用中需要使用电力系统分析工具箱的runpf函数
    result = current_mpc;
    % 模拟电压结果 (实际应通过潮流计算得到)
    result.bus(:, 8) = 0.98 + 0.04 * rand(33, 1); % 模拟电压幅值在0.98~1.02之间
    
    % 模拟支路功率结果
    result.branch(:, 14) = 0.5 + 0.3 * rand(32, 1); % 模拟功率流动
    
    line_flow(i, 1:32) = result.branch(1:32, 14)';  %得到线路有功功率
    Vbus(i, :) = result.bus(:, 8)'; %得到电压结果
end

% 绘制电压概率分布图
figure(1);
flag_node = 6;
[counts, centers] = hist(Vbus(:, flag_node), 100); 
plot(centers, counts / sum(counts), 'b-', 'LineWidth', 2); 
hold on;
xlabel('电压');
ylabel('概率');
title(['节点', num2str(flag_node), '电压概率分布图']);
grid on;

% 绘制线路功率概率分布图
figure(2);
line_idx = 12;
[counts, centers] = hist(line_flow(:, line_idx), 100);
plot(centers, counts / sum(counts), 'r-', 'LineWidth', 2); 
hold on;
xlabel('功率');
ylabel('概率');
title(['线路', num2str(line_idx), '功率概率分布图']);
grid on;

% 计算统计信息
line_power_mean = mean(line_flow(:, 6));
line_power_std = std(line_flow(:, 6));
voltage_mean = mean(Vbus(:, flag_node));
voltage_std = std(Vbus(:, flag_node));

fprintf('线路6功率均值: %.4f, 标准差: %.4f\n', line_power_mean, line_power_std);
fprintf('节点%d电压均值: %.4f, 标准差: %.4f\n', flag_node, voltage_mean, voltage_std);



