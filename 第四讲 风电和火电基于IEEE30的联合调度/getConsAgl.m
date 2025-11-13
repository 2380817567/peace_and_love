%% 这个是ai帮我编的，因为原文中up没给展示


function cons = getConsAgl(x_theta)
%% 获取潮流计算中的相位角约束
cons = [];
% 1. 参考节点（通常是节点1）相位角设为0
cons = [cons, x_theta(1,:) == 0];
% 2. 其他节点的相位角在合理范围内（-π到π弧度，约-180°到180°）
cons = [cons, -pi <= x_theta(2:end,:) <= pi];
% 3. 相邻节点之间的相位角差限制，保证系统稳定性
% 这里可以根据实际需要调整差值范围，例如±30度（约±0.5236弧度）
max_angle_diff = 30 * pi / 180; % 30度转换为弧度
nbus = size(x_theta, 1);
for i = 1:nbus
    for j = i+1:nbus
        cons = [cons, -max_angle_diff <= x_theta(i,:) - x_theta(j,:) <= max_angle_diff];
    end
end