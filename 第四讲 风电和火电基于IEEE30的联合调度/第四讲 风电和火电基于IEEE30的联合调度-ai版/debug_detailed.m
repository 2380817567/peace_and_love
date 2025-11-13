clc;clear;
fid = fopen('debug_output.txt', 'w');
function log_msg(msg)
    disp(msg);
    fid = fopen('debug_output.txt', 'a');
    fprintf(fid, '%s\n', msg);
    fclose(fid);
end

log_msg('开始详细调试...');

%% 基本设置
log_msg('设置基本参数...');
try
    caseName = ieee30;
    iw = 3;
    idg = [1;2;5;8;11];
    igd = [1];
    Horizon = 24;
    ngen = 5;
    nw = 1;
    nbus = size(caseName.bus,1);
    log_msg(['节点数:', num2str(nbus)]);
catch ME
    log_msg('设置基本参数失败:');
    log_msg(ME.message);
    return;
end

%% 创建决策变量
log_msg('创建决策变量...');
try
    x_theta = sdpvar(nbus,Horizon,'full');
    x_P_g = sdpvar(ngen,Horizon,'full');
    x_P_w = sdpvar(nw,Horizon,'full');
    x_u_g = binvar(ngen,Horizon,'full');
    log_msg('决策变量创建成功');
catch ME
    log_msg('创建决策变量失败:');
    log_msg(ME.message);
    return;
end

%% 创建分段线性化变量
log_msg('创建分段线性化变量...');
try
    gn = 5;
    x_pf = sdpvar(ngen,Horizon,'full');
    gw1 = sdpvar(gn+1,Horizon,'full');
    gw2 = sdpvar(gn+1,Horizon,'full');
    gw3 = sdpvar(gn+1,Horizon,'full');
    gw4 = sdpvar(gn+1,Horizon,'full');
    gw5 = sdpvar(gn+1,Horizon,'full');
    gw6 = sdpvar(gn+1,Horizon,'full');
    gz1 = binvar(gn,Horizon,'full');
    gz2 = binvar(gn,Horizon,'full');
    gz3 = binvar(gn,Horizon,'full');
    gz4 = binvar(gn,Horizon,'full');
    gz5 = binvar(gn,Horizon,'full');
    log_msg('分段线性化变量创建成功');
catch ME
    log_msg('创建分段线性化变量失败:');
    log_msg(ME.message);
    return;
end

log_msg('调试完成');
fclose(fid);