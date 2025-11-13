clc; clear; close all;         %依旧只是一个简单的小例子啊，还有非常多不完善的地方

%% 参数设置
T= 24;        % 模拟24小时
N = 1000;     % 蒙特卡洛场景数
t = (1:T)';   % 时同步

% 基本风俗与光照趋势曲线（可替换为实测均值）
mean_wind = 6 + 2*sin((t-6)/24*2*pi);  %白天风大
mean_solar = max(0,sin((t-6)/24*pi));    %白天有光照

%% 模拟风速时间序列（加入时间相关性）
rho = 0.8 ;  % 风速自相关系数（越大越平滑）
sigma_wind = 1.5;   % 风速波动标准差

wind_series = zeros(T,N);
for n = 1:N
    % AR（1）模型：X_t = rho*X_{t-1} + noise
    noise = sigma_wind * randn(T,1);
    for t_idx = 2:T
        noise(t_idx) = rho*noise(t_idx-1) + sqrt(1-rho^2)*sigma_wind*randn;
    end
    wind_series(:,n) = mean_wind + noise;
    wind_series(:,n) = max(0,wind_series(:,n));  % 风速不能为负
end

%% 模拟光伏出力时间顺序 
sigma_solar = 0.2;   % 光伏随机波动
solar_series = zeros(T,N);
for n = 1:N
    daily_variation = mean_solar + sigma_solar*randn(T,1);
    solar_series(:,n) = min(max(daily_variation,0),1);   % 限制在0~1
end

%% 功率计算（简化风电功率曲线）
v_cut_in = 3;  v_rated = 12;   v_cut_out = 25;
P_rated = 1;
P_wind = zeros(T,N);
for n = 1:N
    for t_idx = 1:T
         v = wind_series(t_idx,n);
         if v < v_cut_in
             P_wind(t_idx,n) = 0;
         elseif v < v_rated
              P_wind(t_idx,n) = P_rated*((v - v_cut_in)/(v_rated - v_cut_in))^3;
         elseif v < v_cut_out
              P_wind(t_idx,n) = P_rated;
         else
              P_wind(t_idx,n) = 0;
         end
     end
end

%% 联合出力
P_total = 0.5 * P_wind + 0.5 * solar_series;

%% 结果可视化
figure;
plot(t,mean(P_total,2),'k','LineWidth',2);hold on;
plot(t,P_total(:,1:30),'Color',[0.7,0.7,0.9]);    % 前30个场景
title('风光联合出力时间顺序的蒙特卡洛模拟');
xlabel('时间（h）');  ylabel('出力（pu）');
legend('平均处理','样本场景（部分）');

%% 输出部分统计指标
fprintf('平均日均风光出力：%.3f pu\n',mean(mean(P_total)));
fprintf('峰值小时平均出力：%.3f pu\n',max(mean(P_total,2)));
fprintf('出力标准差（波动性）：%.3f pu\n',std(mean(P_total,2)));















