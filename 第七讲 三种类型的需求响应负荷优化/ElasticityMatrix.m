function [Z] = ElasticityMatrix(P)
%%%总，用户需求弹性矩阵
%时段 %谷 %平 %峰
%低 -0.1 0.01 0.012
%平 0.01 -0.1 0.016
%峰 0.012 0.016 -0.1  %%数据来源《电力需求侧响应原理及其在电力市场中的应用——曾明》
%构造需求弹性矩阵
for i = 1:24
    if P(i) == min(P)
        for j = 1:24
            if P(j) == min(P)
                Z(i,j) = -0.1;
            elseif P(j)==max(P)
                Z(i,j)=0.012;
            elseif min(P)<P(j)<max(P)
                Z(i,j) = 0.01;
            else
                Z(i,j) = 0.01;
            end
        end
    elseif P(i) == max(P)
        for j = 1:24
            if P(j) == min(P)
                Z(i,j) = 0.012;
            elseif P(j) == max(P)
                Z(i,j) = -0.1;
            elseif min(P)<P(j)<max(P)
                Z(i,j) = 0.016;
            else
                Z(i,j) = 0.016;
            end
        end
    else
         for j = 1:24
            if P(j) == min(P)
                Z(i,j) = 0.01;
            elseif P(j)==max(P)
                Z(i,j)=0.016;
            elseif min(P)<P(j)<max(P)
                Z(i,j) = -0.1;
            else
                Z(i,j) = -0.1;
            end
         end
    end
end



















