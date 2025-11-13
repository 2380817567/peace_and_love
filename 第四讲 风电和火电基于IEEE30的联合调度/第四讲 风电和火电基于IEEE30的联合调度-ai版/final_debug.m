clc;clear;
disp('开始最终调试...');

%% 基本设置
try
    caseName = ieee30;
    iw = 3;
    idg = [1;2;5;8;11];
    igd = [1];
    Horizon = 24;
    ngen = 5;
    nw = 1;
    nbus = size(caseName.bus,1);
    disp(['节点数:', num2str(nbus)]);
    
    %% 负荷设置
    L_base = caseName.bus(:,3);
    plt = 1.3*[715 711 705 703 723 728 745 767 786 798 806 819 832 845 858 769 775 789 791 741 732 723 716 719];
    L_Horizon = repmat(L_base./sum(L_base),1,Horizon) .* repmat(plt, nbus, 1);
    ru = plt.*0.1;
    
    %% 创建变量
    x_theta = sdpvar(nbus,Horizon,'full');
    x_P_g = sdpvar(ngen,Horizon,'full');
    x_P_w = sdpvar(nw,Horizon,'full');
    x_u_g = binvar(ngen,Horizon,'full');
    
    %% 风电参数
    Wind = 0.2*[320,323,313,377,372,371,385,379,368,365,368,361,372,380,382,379,386,362,350,345,345,338,329,324];
    PW = Wind./max(Wind)*100;
    
    %% 简化约束
    cons = [];
    Pmax = [260;320;260;220;240];
    Pmin = 0.5.*Pmax;
    
    % 基本约束
    cons = [cons, 0 <= x_P_w <= PW];
    cons = [cons, x_u_g.*repmat(Pmin,1,Horizon) <= x_P_g <= x_u_g.*repmat(Pmax,1,Horizon)];
    
    % 简化的潮流约束
    try
        Mbg = getMbdMatrix(idg, caseName.bus);
        Mbw = getMbdMatrix(iw, caseName.bus);
        Pbus = Mbg*x_P_g + Mbw*x_P_w - L_Horizon;
        
        % 简单的功率平衡
        for ii = 1:Horizon
            cons = [cons, sum(Pbus(:,ii)) == 0];
        end
        disp('约束设置完成');
    catch ME
        disp('设置约束时出错:');
        disp(ME.message);
    end
    
    %% 简化目标函数
    f = sum(x_P_g) + sum(x_P_w);
    
    disp('准备优化...');
    options = sdpsettings('verbose', 1, 'solver', 'gurobi');
    sol = optimize(cons, f, options);
    
    if sol.problem == 0
        disp('优化成功!');
    else
        disp('优化失败:');
        disp(sol.info);
    end
    
catch ME
    disp('发生错误:');
    disp(ME.message);
    disp('堆栈信息:');
    disp(ME.stack);
end

disp('调试结束');