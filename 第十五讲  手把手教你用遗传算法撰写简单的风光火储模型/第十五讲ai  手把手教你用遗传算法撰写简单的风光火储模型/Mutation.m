function ret = Mutation(pmutation, lenchrom, chrom, sizepop, pop, bound)
% 本函数完成变异操作
% pmutation        input :  变异概率
% lenchrom         input ： 染色体长度
% chrom            input ： 染色体群
% sizepop          input ： 种群规模
% pop              input ： 当前种群的进化代数和最大的进化代数信息 [current_gen max_gen]
% bound            input ： 变量的取值范围
% ret              output ： 变异后的染色体

for i = 1:sizepop
    % 变异概率决定该轮循环是否进行变异
    pick = rand;
    if pick > pmutation
        continue;
    end
    
    flag = 0;
    while flag == 0
        % 变异位置
        pick = rand;
        while pick == 0
            pick = rand;
        end
        
        % 正确计算变异位置
        pos = ceil(pick * length(chrom(1,:)));
        pos = min(pos, length(chrom(1,:)));  % 确保位置有效
        
        % 获取当前变量值和约束范围
        v = chrom(i, pos);
        v_min = bound(pos, 1);
        v_max = bound(pos, 2);
        v1 = v - v_min;  % 到下界的距离
        v2 = v_max - v;  % 到上界的距离
        
        % 变异操作（自适应变异）
        pick = rand;
        if pop(1) > 0 && pop(2) > 0
            % 根据当前进化代数计算变异步长
            if pick > 0.5
                delta = v2 * (1 - pick^((1 - pop(1)/pop(2))^2));
                chrom(i, pos) = v + delta;
            else
                delta = v1 * (1 - pick^((1 - pop(1)/pop(2))^2));
                chrom(i, pos) = v - delta;
            end
        else
            % 没有进化代数信息时使用简单变异
            delta = (v_max - v_min) * (rand - 0.5) * 0.2;  % 小幅度随机变异
            chrom(i, pos) = v + delta;
        end
        
        % 确保变异后的变量在约束范围内
        chrom(i, pos) = max(v_min, min(v_max, chrom(i, pos)));
        
        % 检验染色体的可行性
        flag = test(lenchrom, bound, chrom(i,:));
    end
end

ret = chrom;
end







