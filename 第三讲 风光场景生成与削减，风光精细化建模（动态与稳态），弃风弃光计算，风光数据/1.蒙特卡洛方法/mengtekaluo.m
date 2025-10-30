%% 蒙特卡罗生成场景，并用基于概率距离的快速前代消除技术进行场景削减
clc
clear
%% 生成风电场并削减
% 风电处理预测均值E
Ww = [5.8,6.7,5.8,5.1,6.3,5,6.2,6,4.1,6,7,6.8,6.5,6.9,5,5.6,6,5.8,6.2,4.7,3.3,4.4,6.6,5];

W = 0.3*Ww;
%取标准差为风电出力预测值E的5%-20%，这里x=E*10%
l = W*0.1;
Ws = [];
% 生成一个风电场景，E+x*randn(1,24),其中randn（1,24）为生成随机数的标准正态分布
m = 200; %生成m个场景
for i = 1:m
    s = W+1.*randn(1,24);
    Ws = [Ws;s];
end

figure(1)
[ss,gg] = meshgrid(1:200,1:24);
plot3(ss,gg,Ws,'-');
grid
xlabel('场景');
ylabel('时刻');
zlabel('风机出力值');
title('场景生成图');
% legend('负荷曲线1','负荷曲线2','负荷曲线3','负荷曲线4')

Ws_d = Ws; %定义削减后的场景
%场景削减
pi =1/m*ones(m,1);%蒙特卡罗生成的场景为等概率场景，建立每个场景的概率向量
%计算风电场景Ws中每对场景的集合距离x
x = zeros(m,m);
for i = 1:m
    for j = 1:m
        x(i,j) = sum(abs(Ws(i,:) - Ws(j,:)));
    end
end

%计算每个场景与剩余场景的概率距离之和y
y = zeros(m,1);
for i = 1:m
    y(i)=1/m*sum(x(i,:));
end
k = length(y);

% 不断削减场景，直到剩余5个场景
while(k>5)
    d = find(y == min(y)); %选定与剩余场景的概率距离之和的最小场景
    x_2 = x+100*eye(k); %构造新的x，以便找出风电场景Ws中与场景d几何距离最小的场景r
    r = find(x_2(d,:) == min(x_2(d,:)));
    pi(r) = pi(r)+pi(d); %将d场景的概率加到r场景上
% 在风电场景中删除d场景
pi(d) = [];
Ws_d(d,:) = [];
x(d,:) = [];
x(:,d) = [];
y(d) = [];
k = length(y);
end

figure(2)
[ss,gg] = meshgrid(1:5,1:24);
plot3(ss,gg,Ws_d,'-');
grid
xlabel('场景');
ylabel('时刻');
zlabel('风机出力值');
title('场景削减图')


















