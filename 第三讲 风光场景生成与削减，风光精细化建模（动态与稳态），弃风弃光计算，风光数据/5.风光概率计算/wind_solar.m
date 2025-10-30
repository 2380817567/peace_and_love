clc;
clear;

times = 5000; %蒙特卡洛仿真次数
baseMVA = 100000;
% 光伏有功服从Beta分布
Ppv_samp = zeros(1,times);
% Beta分布的两个形状参数
a_pv = 0.6869;
b_pv = 2.1320;
% 光伏发电相关参数：组件总面积S_pv、光电转化率prey_pv、最大光强rmax（MW/m2）
S_pv = 10;
prey_pv = 0.14;
rmax = 700;
% 光伏有功出力样本
pv_samp(1,:) = betarnd(a_pv,b_pv,1,times);
Ppv_samp(1,:) = pv_samp(1,:)*rmax*S_pv*prey_pv/baseMVA;

% weibull分布的两个形状参数
k_wt = 1.637;
c_wt = 5.218;
wt_samp = wblrnd(c_wt,k_wt,1,times); %产生服从weibull分布的样本
PN_wt = 1000;
      vci = 3;
      vN = 13;
      vco = 25;
      for i = 1:times  %得到风电出力的样本
            if wt_samp(i)<vci
                Pwt_samp(i) = 0;
            end
            if wt_samp(i)>vci&&wt_samp(i)<vN
                Pwt_samp(i) = (wt_samp(i)-vci)/(vN-vci)*PN_wt;
                if  Pwt_samp(i)>PN_wt
                    Pwt_samp(i)=PN_wt;
                end
            end
            if wt_samp(i)>vN&&wt_samp(i)<vco
                Pwt_samp(i)=PN_wt;
            end
            if wt_samp(i)>vco
                Pwt_samp(i)=0;
            end
      end
      for i = 1:times
          Pwt_samp(i) = Pwt_samp(i)/baseMVA ;
      end
      mpc =case33bw;  %得到33节点的数据
      P = mpc.bus(:,3); %提取33节点的P、Q数据
      Q = mpc.bus(:,4);
      ld_ero = 0.05; %正态分布的方差

 for k = 1:33
     Pld_samp(k,:) = normrnd(P(k),P(k)*ld_ero,1,times);    %%生成服从正态分布的随机数
     Qld_samp(k,:) = normrnd(Q(k),P(k)*ld_ero,1,times);
 end

 for i = 1:times
     mpc.bus(:,3) = Pld_samp(:,i)'; %更新该次潮流计算的复合数据
     mpc.bus(:,4) = Qld_samp(:,i)'; 

     mpc.bus(14,3) = mpc.bus(14,3)-Ppv_samp(1,i); %更新接入的光伏功率
     mpc.bus(14,4) = mpc.bus(14,4)-Ppv_samp(1,i)*0.484;

     mpc.bus(30,3) = mpc.bus(30,3)-Pwt_samp(1,i); %更新接入的风机功率
     mpc.bus(30,4) = mpc.bus(30,4)-Pwt_samp(1,i)*0.484;

     result = runpf(mpc);
     line_flow(i,1:32) = result.branch(1:32,14)';  %得到线路有功功率

     Vbus(i,:) = result.bus(:,8)'; %得到电压结果

 end

figure(1)
flage = 6;
[counts,centers] = hist(Vbus(:,flage),100); %返回指定数据，特定间隔（如7）的各个分割区间的数量和...

plot(centers,counts / sum(counts)) %画直方图，x是各个区间的中间值，y是对应的概率（区间数/总数量）
hold on

xlabel('电压');
ylabel('概率');
title('电压概率分布图');
line13_m = mean(line_flow(:,6));
line13_d = std(line_flow(:,6));

figure
[counts,centers] = hist(line_flow(:,12),100);%返回指定数据，特定间隔（如7）的各个分割区间的数量和...
plot(centers,counts / sum(counts)) %画直方图，x是各个区间中间值，y是对应的概率（区间数/总数量）
hold on
xlabel('功率');
ylabel('概率');
title('线路功率概率分布图')
line13_m = mean(line_flow(:,6));
line13_d = std(line_flow(:,6));
 













