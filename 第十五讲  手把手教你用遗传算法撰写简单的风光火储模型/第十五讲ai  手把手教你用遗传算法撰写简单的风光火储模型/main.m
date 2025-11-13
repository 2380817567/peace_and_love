% 风光火储模型主程序
% 运行现有的Genetic.m脚本来求解最优调度方案

clc;
clear;
close all;

fprintf('开始运行风光火储模型的遗传算法求解...\n');
fprintf('将直接调用现有的Genetic.m脚本...\n\n');

try
    % 直接运行Genetic.m脚本
    run('Genetic.m');
    
    fprintf('\n遗传算法计算完成！\n');
    fprintf('结果图形已生成，请查看\n');
    
    % 显示最终的最优成本
    fprintf('最终最优成本: %.2f\n', bestfitness);
    
    % 可以在这里添加额外的结果分析代码
    % 例如计算并显示各项成本的详细信息
    
    % 读取数据进行额外分析
    load_data = load('典型日负荷.txt');
    pv_data = load('PV.txt');
    wt_data = load('WT.txt');
    price_data = load('电价.txt');
    
    % 计算最优解下的功率平衡
    [total_cost, pgrid_opt, Ebat_opt] = fun(bestchrom);
    
    % 计算各项成本
    diesel_cost = sum(bestchrom(1:24) * 0.5);  % 假设柴油成本系数为0.5
    grid_cost = sum(pgrid_opt .* price_data);
    
    fprintf('\n成本分析：\n');
    fprintf('- 柴油发电机成本: %.2f\n', diesel_cost);
    fprintf('- 电网交互成本: %.2f\n', grid_cost);
    fprintf('- 总成本: %.2f\n', total_cost);
    
    % 计算可再生能源渗透率
    renewable_gen = sum(pv_data + wt_data);
    total_load = sum(load_data);
    penetration_rate = renewable_gen / total_load * 100;
    
    fprintf('\n可再生能源分析：\n');
    fprintf('- 光伏发电总量: %.2f\n', sum(pv_data));
    fprintf('- 风力发电总量: %.2f\n', sum(wt_data));
    fprintf('- 可再生能源渗透率: %.2f%%\n', penetration_rate);
    
catch ME
    fprintf('错误: %s\n', ME.message);
    fprintf('错误发生在: %s\n', ME.stack(1).name);
    fprintf('行号: %d\n', ME.stack(1).line);
end