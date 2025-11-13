clc;clear;
disp('开始执行简化测试脚本...');

%% 导入ieee30节点网络
disp('导入ieee30节点网络...');
try
    caseName = ieee30;
    disp('成功导入ieee30节点网络');
    disp(['节点数量: ', num2str(size(caseName.bus,1))]);
    disp(['支路数量: ', num2str(size(caseName.branch,1))]);
catch ME
    disp('导入ieee30节点网络失败:');
    disp(ME.message);
    return;
end

%% 系统参数
disp('设置系统参数...');
try
    iw = 3;   %风电接入节点
    idg = [1;2;5;8;11];  %DG接入节点
    igd = [1]; %DG接入节点
    Horizon = 24;
    ngen = 5; %发电机数量
    nw = 1;  %风电数量
    nbus = size(caseName.bus,1);
    disp(['系统参数设置完成，节点数:', num2str(nbus)]);
catch ME
    disp('设置系统参数失败:');
    disp(ME.message);
    return;
end

disp('简化测试完成');