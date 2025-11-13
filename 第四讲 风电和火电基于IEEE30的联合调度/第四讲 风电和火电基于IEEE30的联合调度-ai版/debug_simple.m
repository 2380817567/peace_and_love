clc;clear;
disp('开始调试...');

%% 步骤1: 导入ieee30并设置基本参数
disp('步骤1: 导入ieee30并设置基本参数');
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
catch ME
    disp('步骤1失败:');
    disp(ME.message);
    return;
end

%% 步骤2: 检查sdpvar是否可用
disp('步骤2: 检查YALMIP是否可用');
try
    x_test = sdpvar(1,1);
    disp('YALMIP可用');
catch ME
    disp('步骤2失败 - YALMIP可能未安装:');
    disp(ME.message);
    return;
end

%% 步骤3: 创建决策变量
disp('步骤3: 创建决策变量');
try
    x_theta = sdpvar(nbus,Horizon,'full');
    x_P_g = sdpvar(ngen,Horizon,'full');
    x_P_w = sdpvar(nw,Horizon,'full');
    x_u_g = binvar(ngen,Horizon,'full');
    disp('决策变量创建成功');
catch ME
    disp('步骤3失败:');
    disp(ME.message);
    return;
end

disp('调试完成');