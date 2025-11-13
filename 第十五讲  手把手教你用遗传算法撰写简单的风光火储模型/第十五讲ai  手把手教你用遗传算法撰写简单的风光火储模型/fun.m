function [y pgrid Ebat] = fun(X)
%% 目标函数
% 输入     X：变量向量，前24个为储能出力，后24个为柴油机出力
% 输出     y：目标值（总成本）
%          pgrid：电网交互功率
%          Ebat：储能容量变化

%% 加载数据
Load = load('典型日负荷.txt'); %负荷数据
pv = load('PV.txt');  %光伏发电数据
wt = load('WT.txt');  %风力发电数据
price = load('电价.txt');  %24小时电价数据

%% 初始化变量
pgrid = zeros(1,24); %24小时电网交互功率
cgrid = zeros(1,24); %电网交互费用
cde = zeros(1,24);   %柴油机费用
Ebat = zeros(1,24);  %储能的容量变化
y1 = zeros(1,24); %目标函数数值

%% 储能参数
Ebatmax = 551.8;    %最大储能容量
Ebatmin = 0.4*Ebatmax; %最小储能容量（40%）
Ebat0 = 0.8*Ebatmax; %初始储能容量（80%）

%% 逐小时计算
for i = 1:24
    % 储能容量计算
    if i == 1
        Ebat(1) = Ebat0*(1-0.0001) + X(i)*1*0.9; %考虑自放电率0.01%
    else
        Ebat(i) = Ebat(i-1)*(1-0.0001) + X(i)*1*0.9;
    end
    
    % 功率平衡约束：计算电网交互功率
    % 负荷 = 光伏发电 + 风电 + 储能出力 + 柴油机出力 + 电网交互功率
    pgrid(i) = Load(i) - (pv(i) + wt(i) + X(i) + X(i+24));
    
    % 成本计算
    cde(i) = 1.25 * X(i+24); %柴油机成本
    cgrid(i) = price(i) * pgrid(i); %电网交互成本（注意：负的pgrid表示向电网送电）
    
    % 目标函数值（包括可再生能源补贴和储能运维成本）
    y1(i) = cde(i) + cgrid(i) + pv(i)*0.6 + wt(i)*0.8 + 0.25*abs(X(i));
    
    % 确保储能容量在约束范围内
    if Ebat(i) > Ebatmax
        Ebat(i) = Ebatmax;
    elseif Ebat(i) < Ebatmin
        Ebat(i) = Ebatmin;
    end
end

%% 计算总成本
y = sum(y1);

% 输出检查信息（可选，调试用）
% disp(['总成本: ', num2str(y)]);
% disp(['储能容量范围: ', num2str(min(Ebat)), ' - ', num2str(max(Ebat))]);
end















