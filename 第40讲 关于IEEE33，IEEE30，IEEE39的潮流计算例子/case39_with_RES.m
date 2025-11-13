function case39_with_RES
% IEEE 39 节点配电系统  +  光伏  +  风机  +  柴油机组

mpc = loadcase('case39');     %载入IEEE33节点配电系统算例（需准备case33bw.m）
define_constants;               %导入MATOIWER的常量定义

ncol = size(mpc.gen,2);         % 获取 gen 矩阵列数
ncol_cost = size(mpc.gencost,2);% 获取 gencost 矩阵列数

%% --- 光伏 ---
newgen = zeros(1,ncol);         % 初始化光伏机组数据
% 按照gen矩阵格式定义光伏机组参数
newgen([GEN_BUS PG QG QMAX QMIN VG MBASE GEN_STATUS PMAX PMIN]) = [18 50 0 20 -20 1.02 100 1 50 0];

mpc.gen = [mpc.gen; newgen];     % 将光伏机组追加到 gen

newcost = zeros(1,ncol_cost);   %初始化一行机组成本参数
newcost(1,1:7) = [2 0 0 3 0.01 15 0];  %定义光伏机组的成本函数
mpc.gencost = [mpc.gencost;newcost]; % 讲光伏机组的成本追加到gencost

%% -----风机（PQ，负负荷建模）---
mpc.bus(25,PD ) = mpc.bus(25,PD ) - 30;    %在25号母线上加入风机，相当于减小有功负荷30MW

%% --- 柴油机组 ---
newgen = zeros(1,ncol);      %初始化柴油机组数据
% 按照gen矩阵格式定义光伏机组参数
newgen([GEN_BUS PG QG QMAX QMIN VG MBASE GEN_STATUS PMAX PMIN]) = [30 60 0 25 -25 1.00 100 1 60 0];

mpc.gen = [mpc.gen; newgen];     % 将柴油机组追加到 gen

newcost = zeros(1,ncol_cost);   %初始化柴油机组成本参数
newcost(1,1:7) = [2 0 0 3 0.02 35 0];  %定义光伏机组的成本函数
mpc.gencost = [mpc.gencost;newcost]; % 讲柴油机组的成本追加到gencost

%% --- 运行潮流 --- 
res = runpf(mpc);      % 调用runpf运行潮流计算

%% --- 可视化 ---
figure('Name','IEEE 33 节点系统');    % 打开一个新图窗口，命名

% 子图1：电压
subplot(2,2,1);
plot(res.bus(:,BUS_I), res.bus(:,VM),'-o','LineWidth',1.5); %画出各母线电压（点线图）
grid on;     %打开网络
title('节点电压（p.u.）');    %设置标题
xlabel('Bus');  ylabel('Voltage');   % 设置坐标轴

% 子图2：有功负荷
subplot(2,2,2);
bar(res.bus(:,PD ));     %显示各母线有功负荷
title('有功负荷P（MW）');
xlabel('Bus');ylabel('P(MW)');

% 子图3：无功负荷
subplot(2,2,3);
bar(res.bus(:,QD ));     %显示各母线有功负荷
title('无功负荷Q（MVar）');
xlabel('Bus');ylabel('Q(MVar)');

% 子图 4 ：频率
if isfield(mpc,'basefreq')    % 如果mpc里有basefreq字段，就用它
    fbase = mpc.basefreq;
else
    fbase = 60;               % 否则假设系统基准频率为60Hz
end
subplot(2,2,4);
plot(res.bus(:,BUS_I),ones(size(res.bus,1),1)*fbase,'-s','LineWidth',1.5); %频率曲线
grid on;
title('系统频率（Hz）');
xlabel('Bus');  ylabel('Frequency');
