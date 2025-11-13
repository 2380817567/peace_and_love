function cons = getConsRE(x_P_w,PW)
cons = [];
cons = [cons, 0<= x_P_w <= PW];  %大于0小于最大预测出力