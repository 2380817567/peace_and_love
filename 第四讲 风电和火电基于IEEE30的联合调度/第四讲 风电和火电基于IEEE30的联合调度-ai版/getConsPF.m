function [cons,pf] = getConsPF(caseName,x_theta,Horizon,rateA,baseMVA)

if nargin < 3
    error('getConsPF：输入参数数量错误');
end
if nargin == 3
    rateA = caseName.branch(:,6);
    baseMVA = 100;
end
if nargin == 4
    baseMVA = 100;
end
%% 参数预处理
brch = caseName.branch;
f = brch(:,1);
t = brch(:,2);
x = brch(:,4);
rateA(rateA == 0) = inf;
%% 支路潮流约束，有名值
cons = [];
d_theta = x_theta(f,:) - x_theta(t,:);
pf = d_theta ./ repmat(x,1,Horizon) .* baseMVA;
cons = [cons,-1000 <= pf(1:41,:) <= 1000 ];