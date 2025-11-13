clc;clear;close all;    %这个代码是不考虑时间变化的

%% 参数设置
N = 1e5;  %抽样次数（样本数）这里N是模拟次数。蒙特卡洛方法依赖"大量随机样本"来逼近真实分布

% 风速分布参数（weibull）分布
k = 2;   %形状参数
c = 8;   %尺度参数（平均风速大约6.9m/s）

% 光照出力分布参数（Beta分布）
alpha = 2; % 形状参数α
beta = 5;  % 形状参数β

%% 蒙特卡洛抽样
% 风电出力；先抽风速，再用功率曲线近似出力
wind_speed = wblrnd(c,k,N,1); % 按weibull分布生成风速
P_rated = 1;                  % 归一化额定功率（1表示100%）
v_cut_in = 3; v_rated = 12; v_cut_out = 25;

% 简化的风电功率曲线
P_wind = zeros(N,1);
for i = 1:N
    v = wind_speed(i);
    if v<v_cut_in
        P_wind(i) = 0;
    elseif v < v_rated
        P_wind(i) = P_rated*((v - v_cut_in)/(v_rated - v_cut_in))^3;
    elseif v < v_cut_out
        P_wind(i) = P_rated;
    else
        P_wind(i) = 0;
    end
end

% 光伏出力（0-1 之间）
P_solar = betarnd(alpha,beta,N,1);

% 风光联合出力
P_total = 0.5 * P_wind + 0.5*P_solar;   %假设风光各占50%

%% 结果分析
mean_wind = mean(P_wind);
mean_solar = mean(P_solar);
mean_total = mean(P_total);

fprintf('平均风电出力：%.3f pu\n',mean_wind);
fprintf('平均光伏出力：%.3f pu\n',mean_solar);
fprintf('平均联合出力：%.3f pu\n',mean_total);

%% 绘图
figure;
subplot(3,1,1);
histogram(P_wind,50,'Normalization','pdf');
title('风电出力分布');  xlabel('出力（pu）');ylabel('概率密度');

subplot(3,1,2);
histogram(P_solar,50,'Normalization','pdf');
title('光伏出力分布');xlabel('出力（pu）');ylabel('概率密度');

subplot(3,1,3);
histogram(P_wind,50,'Normalization','pdf');
title('风光联合分布');  xlabel('总出力（pu）');ylabel('概率密度');















