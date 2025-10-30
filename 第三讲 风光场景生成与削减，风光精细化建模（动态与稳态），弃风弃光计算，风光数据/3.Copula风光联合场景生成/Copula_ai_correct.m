%Copula风光联合场景生成+Kmeans聚类

%用ai改完了，看起来和正常的没什么区别了，但是不知道是不是我想要的东西

%% 基于Copula：场景生成；风光出力相关性
%这个光伏处理好像还有一点问题，我添加了一个光伏功率不应该小于零，好像能变好看一点
clc;clear;close all;
% 导入数据与预处理
solardata = xlsread('数据-光伏.xlsx');  %这个数据up没有展示，我感觉我可以根据ai生成一个  光数据和下面的差不多
winddata = xlsread('数据-风功率.xlsx'); %他视频里这个是24列77行，77组一天24小时的风数据
winddata = winddata(2:end,:);
solardata = solardata(2:end,:);

scenarionum = 500; %初始场景数目，可修改
num_cluster = 5;   % 要削减到的场景数目，可修改
ntime = 24;        % 24小时

% X和Y分别存储缝合光的24个时刻历史观测数据
X = []; Y = [];
for t = 1:ntime
    X{t} = winddata(:,t);
    Y{t} = solardata(:,t);
end

%% Copula拟合
% Frank-Copula 函数可以同时考虑变量的非负与负相关的关系
% 故采用 Frank-Copula 函数分别对24个时刻进行拟合
for i = 1:ntime
    U = ksdensity(X{i},'function','cdf'); %核密度估计
    V = ksdensity(Y{i},'function','cdf');

    alpha = copulafit('frank',[U(:) V(:)]); % 拟合出的参数
    copulaparams.alpha = alpha;
    copulaparams.numParams = 1;
    copModels(i) = copulaparams;
end
%% 绘制二元Frank-Copula的密度函数和分布函数图
[Udata,Vdata] = meshgrid(linspace(0,1,31)); %为绘图需要，产生新的网络数据
Ccdf_Frank = copulacdf('Frank',[Udata(:),Vdata(:)],copModels(12).alpha);

%% 采样
Data = cell(1,ntime);
for j = 1:ntime
    Data{j} = copularnd('Frank',copModels(i).alpha,scenarionum); %从Frank Copula中采样
end
%逆变换，转换为实际场景
w = cell(1,ntime);
for k = 1:ntime
    [fwind,xwind] = ecdf(X{k});
    funwind = @(pdwind)spline(fwind,xwind,pdwind); % 样条插值

    [fsolar,xsolar] = ecdf(Y{k});
    funsolar = @(pdsolar)spline(fsolar,xsolar,pdsolar);

    for i = 1:2
        for j = 1:scenarionum
            if i == 1
                w{k}(j,i) = funwind(Data{k}(j,i)); %逆变换
            else
                w{k}(j,i) = max(0, funsolar(Data{k}(j,i))); % 添加非负约束，确保光伏功率不小于零
            end
        end
    end
end
% 基于大量历史数据的场景生成
%% 场景削减
wind = [];
solar = [];

for i = 1:ntime
    wind = [wind,w{i}(:,1)];
    solar = [solar,w{i}(:,2)];
end

% K-means削减
opts = statset('Display','final');
[idx, C] = kmeans([wind,solar],num_cluster,'Distance','cityblock','Replicates',20,'Options',opts);

C_wind = C(:,1:24);    %最终的风电场景
C_solar = max(0, C(:,25:end)); % 最终的光伏场景，确保所有值非负
%% 概率计算
for i = 1:num_cluster
    p(i) = length(find(idx == i)) / length(idx) ;
end
disp(['各场景概率为：',num2str(p)]);

P_wd2 = zeros(5,24);
for j = 1:5
    for i = 1:24
        P_wd2(j,i) = P_wd2(j,i) + p(j)*C_wind(j,i);
    end
end
P_WD = zeros(1,24);
for i = 1:24
    for j = 1:5
        P_WD(1,i) = P_WD(1,i) + P_wd2(j,i);
    end
end

P_pv2 = zeros(5,24);
for j = 1:5
    for i = 1:24
        P_pv2(j,i) = P_pv2(j,i)+p(j)*C_solar(j,i);
    end
end

P_PV = zeros(1,24);
for i = 1:24
    for j = 1:5
        P_PV(1,i) = P_PV(1,i)+P_pv2(j,i);
    end
    P_PV(1,i) = max(0, P_PV(1,i)); % 确保最终的光伏不确定性出力非负
end
% 创建一个大图形窗口，使用subplot展示所有图表
figure('Position', [100, 100, 1200, 900]); % 设置较大的图形窗口

% 图1：考虑相关性生成的风电出力场景
subplot(4,2,1);
[ss,gg] = meshgrid(1:scenarionum,1:24);
plot3(ss,gg,wind,'LineWidth',1);
title(['考虑相关性生成的风电出力',num2str(scenarionum),'个场景'])
xlabel('场景');ylabel('时刻');zlabel('风电出力值');

% 图2：考虑相关性生成的光伏出力场景
subplot(4,2,2);
plot3(ss,gg,solar,'LineWidth',1);
title(['考虑相关性生成的光伏出力',num2str(scenarionum),'个场景'])
xlabel('场景');ylabel('时刻');zlabel('光伏出力值');

% 图3：削减后风电出力场景
subplot(4,2,3);
[ss1,gg1] = meshgrid(1:num_cluster,1:24);
plot3(ss1,gg1,C_wind,'LineWidth',1);
title(['削减后风电出力',num2str(num_cluster),'个场景'])
xlabel('场景');ylabel('时刻');zlabel('风电出力值');

% 图4：削减后光伏出力场景
subplot(4,2,4);
plot3(ss1,gg1,C_solar,'LineWidth',1);
title(['削减后光伏出力',num2str(num_cluster),'个场景'])
xlabel('场景');ylabel('时刻');zlabel('光伏出力值');

% 图5：各场景概率
subplot(4,2,5);  
bar(p);
xlabel('场景数');
ylabel('概率');
title('各场景下概率');

% 图6：风电不确定性出力
subplot(4,2,6);
plot(P_WD);
xlabel('时间/t');
ylabel('功率/kW');
title('风电不确定性出力');

% 图7：光伏不确定性出力
subplot(4,2,7);
plot(P_PV);
xlabel('时间/t');
ylabel('功率/kW');
title('光电不确定性出力');

% 图8：二元Frank-Copula分布函数图
subplot(4,2,8);
surf(Udata,Vdata,reshape(Ccdf_Frank,size(Udata)));   % 绘制二元Frank-Couple分布函数图
xlabel('风电出力');
ylabel('光伏出力');
zlabel('C(u,v)');
title('二元Frank-Copula分布函数图');

% 调整子图间距，使布局更美观
sgtitle('风光联合场景生成与聚类分析结果汇总'); % 添加总标题
%Copula风光联合场景生成+Kmeans聚类
%% 基于Copula：场景生成；风光出力相关性
%这个光伏处理好像还有一点问题，我添加了一个光伏功率不应该小于零，好像能变好看一点
clc;clear;close all;
% 导入数据与预处理
solardata = xlsread('数据-光伏.xlsx');  %这个数据up没有展示，我感觉我可以根据ai生成一个  光数据和下面的差不多
winddata = xlsread('数据-风功率.xlsx'); %他视频里这个是24列77行，77组一天24小时的风数据
winddata = winddata(2:end,:);
solardata = solardata(2:end,:);

scenarionum = 500; %初始场景数目，可修改
num_cluster = 5;   % 要削减到的场景数目，可修改
ntime = 24;        % 24小时

% X和Y分别存储缝合光的24个时刻历史观测数据
X = []; Y = [];
for t = 1:ntime
    X{t} = winddata(:,t);
    Y{t} = solardata(:,t);
end

%% Copula拟合
% Frank-Copula 函数可以同时考虑变量的非负与负相关的关系
% 故采用 Frank-Copula 函数分别对24个时刻进行拟合
for i = 1:ntime
    U = ksdensity(X{i},'function','cdf'); %核密度估计
    V = ksdensity(Y{i},'function','cdf');

    alpha = copulafit('frank',[U(:) V(:)]); % 拟合出的参数
    copulaparams.alpha = alpha;
    copulaparams.numParams = 1;
    copModels(i) = copulaparams;
end
%% 绘制二元Frank-Copula的密度函数和分布函数图
[Udata,Vdata] = meshgrid(linspace(0,1,31)); %为绘图需要，产生新的网络数据
Ccdf_Frank = copulacdf('Frank',[Udata(:),Vdata(:)],copModels(12).alpha);

%% 采样
Data = cell(1,ntime);
for j = 1:ntime
    Data{j} = copularnd('Frank',copModels(i).alpha,scenarionum); %从Frank Copula中采样
end
%逆变换，转换为实际场景
w = cell(1,ntime);
for k = 1:ntime
    [fwind,xwind] = ecdf(X{k});
    funwind = @(pdwind)spline(fwind,xwind,pdwind); % 样条插值

    [fsolar,xsolar] = ecdf(Y{k});
    funsolar = @(pdsolar)spline(fsolar,xsolar,pdsolar);

    for i = 1:2
        for j = 1:scenarionum
            if i == 1
                w{k}(j,i) = funwind(Data{k}(j,i)); %逆变换
            else
                w{k}(j,i) = max(0, funsolar(Data{k}(j,i))); % 添加非负约束，确保光伏功率不小于零
            end
        end
    end
end
% 基于大量历史数据的场景生成
%% 场景削减
wind = [];
solar = [];

for i = 1:ntime
    wind = [wind,w{i}(:,1)];
    solar = [solar,w{i}(:,2)];
end

% K-means削减
opts = statset('Display','final');
[idx, C] = kmeans([wind,solar],num_cluster,'Distance','cityblock','Replicates',20,'Options',opts);

C_wind = C(:,1:24);    %最终的风电场景
C_solar = max(0, C(:,25:end)); % 最终的光伏场景，确保所有值非负
%% 概率计算
for i = 1:num_cluster
    p(i) = length(find(idx == i)) / length(idx) ;
end
disp(['各场景概率为：',num2str(p)]);

P_wd2 = zeros(5,24);
for j = 1:5
    for i = 1:24
        P_wd2(j,i) = P_wd2(j,i) + p(j)*C_wind(j,i);
    end
end
P_WD = zeros(1,24);
for i = 1:24
    for j = 1:5
        P_WD(1,i) = P_WD(1,i) + P_wd2(j,i);
    end
end

P_pv2 = zeros(5,24);
for j = 1:5
    for i = 1:24
        P_pv2(j,i) = P_pv2(j,i)+p(j)*C_solar(j,i);
    end
end

P_PV = zeros(1,24);
for i = 1:24
    for j = 1:5
        P_PV(1,i) = P_PV(1,i)+P_pv2(j,i);
    end
end
% 创建一个大图形窗口，使用subplot展示所有图表
figure('Position', [100, 100, 1200, 900]); % 设置较大的图形窗口

% 图1：考虑相关性生成的风电出力场景
subplot(4,2,1);
[ss,gg] = meshgrid(1:scenarionum,1:24);
plot3(ss,gg,wind,'LineWidth',1);
title(['考虑相关性生成的风电出力',num2str(scenarionum),'个场景'])
xlabel('场景');ylabel('时刻');zlabel('风电出力值');

% 图2：考虑相关性生成的光伏出力场景
subplot(4,2,2);
plot3(ss,gg,solar,'LineWidth',1);
title(['考虑相关性生成的光伏出力',num2str(scenarionum),'个场景'])
xlabel('场景');ylabel('时刻');zlabel('光伏出力值');

% 图3：削减后风电出力场景
subplot(4,2,3);
[ss1,gg1] = meshgrid(1:num_cluster,1:24);
plot3(ss1,gg1,C_wind,'LineWidth',1);
title(['削减后风电出力',num2str(num_cluster),'个场景'])
xlabel('场景');ylabel('时刻');zlabel('风电出力值');

% 图4：削减后光伏出力场景
subplot(4,2,4);
plot3(ss1,gg1,C_solar,'LineWidth',1);
title(['削减后光伏出力',num2str(num_cluster),'个场景'])
xlabel('场景');ylabel('时刻');zlabel('光伏出力值');

% 图5：各场景概率
subplot(4,2,5);  
bar(p);
xlabel('场景数');
ylabel('概率');
title('各场景下概率');

% 图6：风电不确定性出力
subplot(4,2,6);
plot(P_WD);
xlabel('时间/t');
ylabel('功率/kW');
title('风电不确定性出力');

% 图7：光伏不确定性出力
subplot(4,2,7);
plot(P_PV);
xlabel('时间/t');
ylabel('功率/kW');
title('光电不确定性出力');

% 图8：二元Frank-Copula分布函数图
subplot(4,2,8);
surf(Udata,Vdata,reshape(Ccdf_Frank,size(Udata)));   % 绘制二元Frank-Couple分布函数图
xlabel('风电出力');
ylabel('光伏出力');
zlabel('C(u,v)');
title('二元Frank-Copula分布函数图');

% 调整子图间距，使布局更美观
sgtitle('风光联合场景生成与聚类分析结果汇总'); % 添加总标题




