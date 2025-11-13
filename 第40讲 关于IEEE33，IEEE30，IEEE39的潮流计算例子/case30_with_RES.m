function case30_with_RES
% IEEE30节点系统 + 光伏 + 风机 + 常规机组

mpc = loadcase('case30');    %载入IEEE30节点系统的基础算例
define_constants;            %导入MATPOWER的常量定义（BUS_I,VM,PD等）

%% ————光伏机组—————
ncol = size(mpc.gen,2);    %获取gen矩阵的列数
newgen = zeros(1,ncol);    % 初始化一行发电机数据，长度和原来一致
% 按照MATPOWER gen 矩阵格式，填入光伏机组参数（母线号、有功、无功上下限、电压等）
newgen([GEN_BUS PG QG QMAX QMIN VG MBASE GEN_STATUS PMAX PMIN]) = [10 20 0 10 -10 1.01 100 1 20 0];

mpc.gen = [mpc.gen; newgen]; %将光伏机组追加到gen矩阵 

ncol_cost  = size(mpc.gencost,2);    %获取gencost矩阵的列数
nowcost = zeros(1,ncol_cost,2);   %初始化一行机组成本参数
newcost(1,1:7) = [2 0 0 3 0.01 20 0];  %定义光伏机组的成本函数
mpc.gencost = [mpc.gencost;newcost]; % 讲光伏机组的成本追加到gencost

%% --- 风机 （PQ，负负荷建模）---
mpc.bus(24,PD ) = mpc.bus(24,PD ) - 15; %在24号母线上加入风机，相当于减少有功负荷15MW

%% 常规机组 
newgen =zeros(1,ncol);     % 初始化常规机组数据
% 填入常规机组参数
newgen([GEN_BUS PG QG QMAX QMIN VG MBASE GEN_STATUS PMAX PMIN]) = [27 40 0 20 -20 1.00 100 1 40 0];

mpc.gen = [mpc.gen; newgen];   % 讲常规机组追加到gen

zeros(1,ncol_cost);    % 初始化成本参数
newcost(1,1:7) = [2 0 0 3 0.02 30 0];    %定义常规机组的成本函数
mpc.gencost = [mpc.gencost; newcost];    % 将常规机组成本追加到 gencost

%% --- 运行潮流 --- 
res = runpf(mpc);     % 使用MATPOWER的牛顿法运行潮流计算，结果存到res

%% --- 可视化 ---
figure('Name','IEEE 30 节点系统');    % 打开一个新图窗口，命名

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









