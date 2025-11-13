function result = fitness(x,k)
%以经济型为目标
C_MT = 0;
C_GRID = 0;
C_BA  = 0;
C_BA_sum = 0;
deltp_sum = 0;
P_BA_sum_delt = 0;
%% 储能荷电状态
BAsocMax = 200;
P_laod = [11.7 12.4 11.7 12.4 11.7.22.4 81.9 122.4 241.3 242.0 241.3 241.3 241.3 240.7 241.3 240.7 241.3 ];
P_pv = [0 0 0 0 0 0 0 0.0391 19.5244 40.0204 50.1010 73.3946 76.3489 72.8004 53.1185 4.6458 0 0 0];
G_price = [0 0 0 0 0 0 0 0 0.0931  0.0931 0.0931 0.0931 0.0931 0.0931 0.0931 0.0931 0.0931 0.0931];

%1-24，燃机；25-48，电网交互；49-72储能
for i = 1:72
    if i < 25
        C_MT = C_MT + 0.04*x(i);
    elseif i>24 && i<49
        C_GRID = C_GRID + G_price(i-24) * x(i);
    else
        C_BA = C_BA+8*abs(x(i));
    end
end

%储能的约束
for i = 49:72
    P_BA_sum = P_BA_sum+(-x(i));
    P_BA_sum_delt = P_BA_sum_delt+max(0,P_BA_sum-BAsocMax);
end


if(P_BA_sum_delt<0)
    d = 0;
elseif(P_BA_sum_delt>0&&P_BA_sum_delt<=0.001)
    d = 10;   %%%%%迭代次数
elseif(P_BA_sum_delt>0.001&&P_BA_sum_delt<0.1)
    d = 20;
elseif(P_BA_sum_delt>0.1&&P_BA_sum_delt<=1.0)
    d = 100;
else
    d = 1000;
end



















