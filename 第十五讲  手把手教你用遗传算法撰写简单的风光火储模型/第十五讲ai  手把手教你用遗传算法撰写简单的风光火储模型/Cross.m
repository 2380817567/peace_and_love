function ret = Cross(pcross, lenchrom, chrom, sizepop, bound)
% 本函数完成交叉操作
% pcross    input ： 交叉的概率
% lenchrom  input ： 染色体的长度
% chrom     input :  染色体群
% sizepop   input ： 种群规模
% bound     input ： 变量的取值范围
% ret       output： 交叉后的的染色体

for i = 1:sizepop
    % 随机选择两个染色体进行交叉
    pick = rand(1,2);
    while prod(pick) == 0
        pick = rand(1,2);
    end
    index = ceil(pick .* sizepop);
    
    % 交叉概率决定是否进行交叉
    pick = rand;
    while pick == 0
        pick = rand;
    end
    
    if pick > pcross
        continue;
    end
    
    flag = 0;
    while flag == 0
        % 随机选择交叉位置
        pick = rand;
        while pick == 0
            pick = rand;
        end
        
        % 修正语法错误，正确计算交叉位置
        pos = ceil(pick * length(chrom(1,:))); % 选择第几个变量进行交叉
        
        % 确保pos在有效范围内
        pos = min(pos, length(chrom(1,:)));
        
        % 交叉操作
        pick = rand;  % 交叉系数
        v1 = chrom(index(1), pos);
        v2 = chrom(index(2), pos);
        
        chrom(index(1), pos) = pick*v2 + (1-pick)*v1;
        chrom(index(2), pos) = pick*v1 + (1-pick)*v2;   % 交叉结束
        
        % 检验染色体的可行性
        flag1 = test(lenchrom, bound, chrom(index(1),:));
        flag2 = test(lenchrom, bound, chrom(index(2),:));
        
        % 如果两个染色体都可行，则继续
        if flag1 * flag2 == 1
            flag = 1;
        end
    end
end

ret = chrom;
end


























