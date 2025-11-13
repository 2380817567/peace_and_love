
clear; clc;   % 清空工作区和命令行

%------ 参数 ------
a = 100;   % 消费者效用线性系数
b = 1;     % 消费者效用二次系数（边际效用递减）
c = 20;    % 主方生产成本

% ------ 变量 ------
p = sdpvar(1,1);     % 主方价格决策变量
q = sdpvar(1,1);     % 从放数量决策变量
lambda_low = sdpvar(1,1);   % 下界约束对应的对偶变量（KKT条件用）

% ------ 下层KKT条件 ------
Constraints = [];     % 初始化约束集合

% stationary条件：从方最优条件（梯度=0）
Constraints = [Constraints,p-a+b*q - lambda_low == 0];

% q下界约束及互补条件：q>0,lambda_low >= 0,且 lambda_low*q = 0
Constraints = [Constraints,q >= 0, lambda_low >= 0 ];
Constraints = [Constraints,complements(q>=0, lambda_low>=0)];

% 价格非负约束
Constraints = [Constraints, p >= 0];

% ------ 上层目标函数 ------
Objective = (p - c)*q;    % 主方利润 = （价格 - 成本）*销量

% ------ 求解器设置 ------
options = sdpsettings('solver','gurobi','verbose',1);  % 使用gurobi求解器并输出信息,使用非线性求解器

% ------ 求解 ------
sol = optimize(Constraints,-Objective,options);  % 最大化利润（YALMIP 用负号表示最大化）

% ------ 输出 ------
if sol.problem == 0
    % 提取最优解
    p_opt = value(p);    % 最优价格
    q_opt = value(q);    % 最有销量
    profit_opt = value(Objective);  % 最大利润

    %打印最优结果
    fprintf('最优价格 p* = %.2f\n',p_opt);
    fprintf('最优销量 q* = %.2f\n',q_opt);
    fprintf('最大利润 = %.2f\n',profit_opt);

    % ---- 画消费者反应曲线 + 主方利润曲线 ----
    p_grid = linspace(0,a,200);   % 生成价格网络，从0到a
    q_grid = max((a - p_grid)/b,0);    % 消费主反应曲线q(p) = (a-p)/b
    profit_grid = (p_grid - c).*q_grid;   % 主方利润曲线π(p) = (p-c)*q(p)

    figure('Name','Stackelberg Pricing','Position',[200 200 800 400]);  %新建图形窗口

    yyaxis left   %左y轴画消费者需求
    plot(p_grid,q_grid,'b-','LineWidth',2); hold on;  % 蓝线：q(p)
    plot(p_opt,q_opt,'bo','MarkerSize',8,'MarkerFaceColor','b');  % 蓝点：最优点
    ylabel('消费者需求q(p)');
    xlabel('价格p');
    title('主从博弈：消费者反应曲线 & 主方利润曲线');
    grid on;

    yyaxis right   % 右y轴画主方利润
    plot(p_grid,profit_grid,'r--','LineWidth',2);   % 红虚线：主方利润曲线
    plot(p_opt,profit_opt,'ro','Markersize',8,'MarkerFaceColor','r');   % 红点：最大利润
    ylabel('主方利润（p-c）q');

    legend('消费者反应曲线','最优点','主方利润曲线','Location','best');
else
    disp('求解失败L：');  % 输出求解失败信息
    disp(sol.info);
end






















