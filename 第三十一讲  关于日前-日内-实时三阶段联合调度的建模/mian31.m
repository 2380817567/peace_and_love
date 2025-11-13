% 这个代码跑不出成功，直接看ai改的那个就行


function dispatch_joint_model_highres()
% 联合日前（24点）、日内（96点）和实时（360点）调度
% 实现逐阶段调度，并绘图扎实三个时间尺度调度结果

%% 参数设置
T_DA = 24;   %日前24小时
T_ID = 96;   %日内：15分钟一段
T_RT = 360;  %实时：4分钟一段

N = 3;       %发电机数量

% 发电机参数
P_min = [50; 60; 80];      %最小出力（MW）
P_max = [200; 180; 300];   %最大出力（MW）
cost_da = [20;23;25];      %日前报价（美元/MWh）
cost_id = [24;27;28];      %日内报价
cost_rt = [30;35;40];      %实时报价

% 负荷曲线生成
t_da = linspace(0, 24, T_DA);
t_id = linspace(0, 24, T_ID);
t_rt = linspace(0, 24, T_RT);

load_DA = 500 + 100*sin(t_da * pi / 12);
load_ID = 500 + 100*sin(t_id * pi / 12) + 20*sin(2*pi*t_id/4);  %添加扰动
load_RT = 500 + 100*sin(t_rt * pi / 12) + 30*cos(2*pi*t_rt/3);  %添加更强扰动

%% 日前调度
P_DA = zeros(N,T_DA);
for t = 1:T_DA
    P_DA(:,t) = dispatch_stage(load_DA(t),P_min,P_max,cost_da);
end

%% 日内调度
P_ID = zeros(N,T_ID);
for t = 1:T_ID
    P_ID(:,t) = dispatch_stage(load_ID(t),P_min,P_max,cost_id);
end

%% 实时调度
P_RT = zeros(N,T_RT);
for t = 1:T_RT
    P_RT(:,t) = dispatch_stage(load_RT(t),P_min,P_max,cost_rt);
end

%% 点线图绘图输出
figure;

% 日前调度输出（24点）
plot(t_da,P_DA(1,:),'o-', ...
     t_da,P_DA(2,:),'s--', ...
     t_da,P_DA(3,:),'d-.','LineWidth',1.5); 
legend('机组1','机组2','机组3');
xlabel('时间（h）');
ylabel('出力（MW）');
title('日前调度（24点）');grid on;

% 日内调度输出（96点）
figure;
plot(t_id,P_ID(1,:),'o-', ...
     t_id,P_ID(2,:),'s--', ...
     t_id,P_ID(3,:),'d-.','LineWidth',1.2); 
legend('机组1','机组2','机组3');
xlabel('时间（h）');
ylabel('出力（MW）');
title('日前调度（96点），每15分钟');grid on;

% 实时调度输出（360点）
figure;
plot(t_rt,P_RT(1,:),'o-', ...
     t_rt,P_RT(2,:),'s--', ...
     t_rt,P_RT(3,:),'d-.','LineWidth',1); 
legend('机组1','机组2','机组3');
xlabel('时间（h）');
ylabel('出力（MW）');
title('实时调度（360点），每4分钟');grid on;
end


%% 调度函数
function P = dispatch_stage(demand,P_min,P_max,cost)
% 使用gurobi实现给定负荷下的最优调度
N = length(P_min);
f = cost;
A = [eye(N); -eye(N)];
b = [P_max,-P_min];
Aeq = ones(1,N);
beq = demand;

options = optimoptions('linprog','Display','none');
[P,~,exitflag] = linprog(f,A,b,Aeq,beq,[],options);

if exitflag ~= 1
    warning('调度不可行，返回最小出力');
end
end










