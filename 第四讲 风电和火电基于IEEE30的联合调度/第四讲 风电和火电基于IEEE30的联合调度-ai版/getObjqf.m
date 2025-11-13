function fqf = getObjqf(x_P_w,PW,Horizon)
fqf = 336*sum(PW-x_P_w);
