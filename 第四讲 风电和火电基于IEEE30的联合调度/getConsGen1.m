function cons = getConsGen1(x_P_g,x_u_g,Pmax,Pb,rg,ru,Horizon)
%% 获取机组约束
cons = [];
% 1.机组上下限约束
cons = [cons, x_u_g.*repmat(Pb,1,Horizon) <= x_P_g <=x_u_g.*repmat(Pmax,1,Horizon)];%xug是启停状态
% 2.爬坡约束
cons = [cons,abs([x_P_g(:,2:end),x_P_g(:,1)]-x_P_g)<=repmat(rg.*Pmax,1,Horizon)];
% 3. 旋转备用
cons = [cons,sum(repmat(Pmax,1,Horizon)-x_P_g) >= ru];
cons = [cons,sum(x_P_g-repmat(Pb,1,Horizon))>=ru];