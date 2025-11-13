%% 清空环境
clc
clear
tic; %tic用来保存时间

%% 本案例设置变量为储能的出力以及柴油机的出力1*24
%% 遗传算法参数
MAXGEN = 50;         %进化代数
sizepop = 100;       %种群规模
pcross = 0.6;        %交叉概率
pmutation = 0.01;    %变异概率
lenchrom=ones(1,48); %变量子串长度   %为什么变量为48个，24*2
bound = [-20   20
         -20   20
         -20   20 
         -20   20
         -20   20
         -20   20 
         -20   20
         -20   20
         -20   20 
         -20   20
         -20   20
         -20   20 
         -20   20
         -20   20
         -20   20 
         -20   20
         -20   20
         -20   20 
         -20   20
         -20   20
         -20   20 
         -20   20
         -20   20
         -20   20 
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         30    120
         ];          %BE、DE变量范围
trace = zeros(1,MAXGEN);
%% 个体初始化
gen = 1;
fprintf('%d\n',gen);
individuals = struct('fitness',zeros(1,sizepop),'chrom',[],'pgrid',[],'Ebat',[]);  %种群结构体
bestfitness = [];                                                                  %种群最佳适应度
bestchrom = [];                                                                    %适应度最好的染色体
% 初始化种群
for i = 1:sizepop
    individuals.chrom(i,:) = Code(lenchrom,bound);       %随机产生个体
    X = individuals.chrom(i,:);
    [money pgrid Ebat] = fun(X);
    individuals.fitness(i) = money;                      %个体适应度
    individuals.pgrid(i,:)=pgrid;
    individuals.Ebat(i,:)=Ebat;
end
%找最好的染色体
[bestfitness bestindex] = min(individuals.fitness);
bestchrom = individuals.chrom(bestindex,:);   %最好的染色体
bestpgrid = individuals.pgrid(bestindex,:);
bestEbat = individuals.Ebat(bestindex,:);

% 记录每一代进化中最好的适应度和平均适应度
trace(1) = bestfitness;

%% 进化开始
for gen = 2:MAXGEN
    fprintf('%d\n',gen)
    %选择操作
    individuals = Select(individuals,sizepop);
    %交叉操作
    individuals.chrom = Cross(pcross,lenchrom,individuals.chrom,sizepop,bound);
    %变异操作
    individuals.chrom = Mutation(pmutation,lenchrom,individuals.chrom,sizepop,[gen MAXGEN],bound);

    % 计算适应度
    for j = 1:sizepop
        X = individuals.chrom(j,:);
        [money pgrid Ebat] = fun(X);
        individuals.fitness(j) = money;
        individuals.pgrid(j,:)=pgrid;
        individuals.Ebat(j,:)=Ebat;
    end
%找到最小和最大适应度的染色体及它们在种群中的位置
 [newbestfitness,newbestindex] = min(individuals.fitness);

 %代替上一次进化中最好的染色体
 if bestfitness>newbestfitness
     bestfitness = newbestfitness;
     bestchrom = individuals.chrom(newbestindex,:);
     bestpgrid = individuals.pgrid(newbestindex,:);
     bestEbat = individuals.Ebat(newbestindex,:);
 end
 trace(gen) = bestfitness;  %记录每一代进化中最好的适应度和平均适应度
end
%进化结束
time = toc;
%% 结果显示
xx = 1:24;
figure(1);
plot(1:MAXGEN,trace);
legend('最优成本追踪')

figure(2)
plot(1:24,Ebat);
legend('储能容量变化')

figure(3);
plot(xx,individuals.chrom(j,1:24),'-k*',xx,individuals.chrom(j,25:48),'r-*',xx,pgrid,'-b^');
disp(X);
disp(['运行时间time：',num2str(time)]);
legend('储能功率','柴油机功率','电网交互功率')

