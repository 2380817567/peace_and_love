function [y pgrid Ebat] = fun(X)
%% 目标函数
% 输入     x：二进制编码
%lenchrom： 各变量的二进制位数
% 输出     Y：目标值
%          X：十进制数
%X（1）为储能出力；X（2）为柴油机出力
%% 计算适应度-函数值
Load = load('典型日负荷ai生成.txt'); %负荷
pv = load('PVai生成.txt');  %光伏发电
wt = load('WTai生成.txt');  %风力发电
% 没用 prem = Load - (pv+wt);
price = load('电价ai生成.txt');  %24小时电价
pgrid = zeros(1,24); %24小时电网交互功率
cgrid = zeros(1,24); %电网交互费用
cde = zeros(1,24);   %柴油机费用
Ebat = zeros(1,24);  %储能的容量变化
y1 = zeros(1,24); %目标函数数值
Ebatmax = 551.8;
Ebatmin = 0.4*Ebatmax;
Ebat0 = 0.8*Ebatmax;
for i = 1:24
    if i == 1
        Ebat(1) = Ebat0*(1-0.0001) + X(1)*1*0.9;
    else
        Ebat(i) = Ebat(i-1)*(1-0.0001)+X(i)*1*0.9;
    end

    % 计算功率平衡，设置pgrid的值
    pgrid(i) = Load(i) - X(i) - X(i+24) - pv(i) - wt(i);  %功率平衡约束
    cde(i) = 1.25*X(i+24); %柴油机成本
    cgrid(i) = price(i)*pgrid(i); %电网交互成本
    y1(i) = cde(i) + cgrid(i) + pv(i)*0.6+wt(i)*0.8+0.25*X(i);
end
y = sum(y1);















