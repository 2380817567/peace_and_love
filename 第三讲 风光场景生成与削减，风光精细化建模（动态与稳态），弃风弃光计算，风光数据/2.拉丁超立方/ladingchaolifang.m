clc;clear;
%%
% 场景法
%%% wf1 wf2 为平均值
wf1 = [339,287,449,471,512,530,527,641,634,519,401,634,589,530,512,505,206,85,81,80,83,110,353,523];
wf2 = [0,0,0,0,0,0,99,137,150,178,189,191,176,171,138,104,77,0,0,0,0,0,0,0];
m1 = ones(24,1000); %风生成
m2 = ones(24,1000); %光生成
m = ones(24,1000); %可再生生成
%% 
% 生成1000个场景
%%
% 拉丁超立方抽样方法
%%% 拉丁超立方抽样 ==== 属于分层抽样技术（从多元参数分布中近似随机抽样的方法） ----分层抽样：将抽样区间（本程序为正态分布区间）
%按某种特性或某种规划分为不同的层，然后从不同的层中独立、随机（打乱排序、无规律抽取）
%地抽取样本（如取10个苹果样本，按照特性把苹果树分为5类，每类随机抽取两个），从而保证样本的结构与总体的结构比较相近，提高估计的精度。

%拉丁超立方相较蒙卡，改进了采样策略能够做到较小采样规模中获得较高的采样精度。

%%lhsnorm（mu，sigma，n）；mu为平均值（数量a）：求解公式：u = （1/N）*（sum（样本））：N为样本数目
                %      sigma协方差矩阵（数量a*a）；求解公式：=（（1/N）^3）*(sum(样本i-u）^2);   i=1至N
                %      n抽样次数
% 表示方式1
c = 1;  %c 表示基础数据的数量
u1 = lhsdesign(1,24);
u2 = lhsdesign(1,24);
for t = 1:24
    m1(t,:) = lhsnorm(sum(wf1(:,t))/c,u1(t)*sum(wf1(:,t))/c,1000); % 拉丁超立方抽样（lhsnorm函数）方法
                                                                     %（基于风电和光伏处理遵从正态分布normed（均值，标准差，n，m）n*m阶正态矩阵），
                                                                     %因此lhsnorm函数的均值和标准差采用正态分布的均值，标准差
                                                                     %依据文献，可以加订标准差与均值之间存在一定的比例关系。
    if t>=7&&t<=17
        m2(t,:) = lhsnorm(sum(wf2(:,t))/c,u2(t)*sum(wf2(:,t))/c,1000);
    else
        m2(t,:) = 0;
    end
    m(t,:) = m1(t,:)+m2(t,:);
end
 %%
 % 表示方式2
%  for t = 1:24
%      m1(t,:) = normrnd(wf1(t),0.12*wf1(t),1,1000);   %正态分布 normrnd（均值，标准差，n，m）  n*m阶正态矩阵
%      m2(t,:) = normrnd(wf2(t),0.1*wf2(t),1,1000);
%      m(t,:) = m1(t,:) + m2(t,:);
%  end
%% 场景生成图
figure()
plot(m1,'--')
hold on
plot(m2,'-')
hold on
l2 = xlabel('t/h');
set(l2,'Fontname','Times New Roman','Fontsize',20)
l3 = ylabel('P/kW');
set(l3,'Fontname','Times New Roman','Fontsize',20)
set(gca,'Fontname','Times New Roman','Fontsize',20)
%%
%场景削减（快速后向削减）
%原理：确定初始场景集合的一个子集，并给其重新分配场景概率，
% 使保留场景的概率分布Q与初始场景集合的概率P之间的某种概率距离最短（即，P与Q相近）
%从而削减概率小的概率，将其加到与其场景的概率距离最近的场景上。
%%
%计算各个场景之间的概率距离
k = zeros(1000,1000);
for i = 1:1000
    for j=1:1000
        if i == j
            k(i,j) %k距离
        else
            k(i,j) = sqrt(sum((m(:,i)-m(:,j)).^2));
        end
    end
end
p = ones(1000,1)*0.001; %各场景初始概率
%%
%%寻找最小概率距离场景
k1 = k;b2 = [];k1(k1 == 0) = inf;
for n = 1:990 %削减990次，保留10个概率最高场景
    [mink,index] = min(k1,[],2);%index每行最小坐标列  %mink 每行最小数值 %min（k1,[],2）求取每行的...
    %%
    %删去index2 行 %%min（mink，p） 概率最低...被淘汰
    [mink11,index2] = min(mink.*p);
    b = index2;
   %减少一个场景
   k1(b,:) = [];
   k1(:,b) = [];
%%
b2 = [b2;b];
%%
%新概率生成
a = index(index2);%与被削减场景的概率距离最近的场景a
%新场景概率a=原来对应场景概率a+概率重新分配系数*与此情景概率距离最近场景index2
p(a) = p(index2)+p(a);
%%
%一次循环后新的概率和场景
p(b) = [];
m(:,b) = [];
m1(:,b) = [];
m2(:,b) = [];
%%
end %%%%一轮结束，场景削减1个。
%%
%%削减后的场景
figure()
plot(wf1,'*')
hold on
plot(wf2,'-')
hold on
for n1 = 1:10
    plot(m1(:,n1));
    hold on
    plot(m2(:,n1));
    grid on
end
l2 = xlabel('t/h');
set(l2,'Fontname','Time New Roman','Fontsize',20)
l3 = ylabel('P/kW');
set(l3,'Fontname','Time New Roman','Fontsize',20)
set(gca,'Fontname','Time New Roman','Fontsize',20)














