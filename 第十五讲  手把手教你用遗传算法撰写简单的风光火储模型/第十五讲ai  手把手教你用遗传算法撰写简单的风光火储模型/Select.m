function ret = Select(individuals,sizepop)
% 本函数对每一代种群中的染色体进行选择，以进行后面的交叉和变异
% individuals   input    ： 种群的信息
%sizepop        input    ： 种群的规模
%ret            output   ： 经过选择后的种群

% 适应度转换（使用小值优化，所以取倒数）
individuals.fitness = 1 ./ max(individuals.fitness, 1e-10); % 避免除以零
sumfitness = sum(individuals.fitness);
sumf = individuals.fitness ./ sumfitness;
index = [];

% 轮盘赌选择
for i = 1:sizepop   %转sizepop次轮盘
    pick = rand;
    while pick == 0
        pick = rand;
    end
    for j = 1:sizepop
        pick = pick - sumf(j);
        if pick < 0
            index = [index, j];
            break; %寻找落入的区间，此次转轮盘选中了染色体j
        end
    end
end

% 更新种群（修正变量名拼写错误）
individuals.chrom = individuals.chrom(index,:);
individuals.fitness = individuals.fitness(index);
ret = individuals;
end