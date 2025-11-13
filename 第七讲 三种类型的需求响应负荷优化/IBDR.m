function [Psl,Pcl] = IBDR(Z_SL,Z_CL,load,p_a,p_b,W2,W3)

Psl = zeros(1,24);  %削减负荷
Pcl = zeros(1,24);  %转移负荷
%价格型需求响应
for i = 1:24
    sum1 = 0;
    for j = 1:24
        sum1 = sum1 + (Z_SL(i,j)*((p_a(j)-p_b(j))/p_b(j))); %可转移系数削峰填谷
    end
    Psl(i) = W2*load(i)*sum1;
end

for i = 1:24
    sum2 = 0;
    for j = 1:24
        sum2 = sum2+(Z_CL(i,j)*((p_a(j)-p_b(j))/p_b(j)));   %可削减系数
    end
    if sum2>0
        sum2 = 0;   %削减发生在价格上涨的时候
    else
        Pcl(i) = W3*load(i)*sum2;
    end
end






