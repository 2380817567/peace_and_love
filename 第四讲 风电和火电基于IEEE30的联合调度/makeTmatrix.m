function T = makeTmatrix(caseNmae,islk)
if nargin == 1
    islk = 1;
end
bus = casseName.bus;
brch = caseNmae.branch;
f = brch(:,1);
t = brch(:,2);
x = brch(:,4);
nbus = size(bus,1);
nbrch = size(brch,1);
Cft = zeros(nbrch,nbus);
for ii = 1:nbrh
    Cft(ii,f(ii)) = 1;
    Cft(ii,t(ii)) = -1;
    end
Bf = zeros(nbrch,nbus);
for ii = 1:nbrch
    Bf(ii,f(ii)) = 1./x(ii);
    Bf(ii,t(ii)) = -1./x(ii);
end
Bbus = Cft.' *Bf;
Bbus(islk,:) = [];
Bbus(:,ilsk) = [];
B_noslk_inv = inv(Bbus);
B_add = zeros(nbus,nbus);
B_add(2:end,2:end) = B_noslk_inv;
T = Bf * B_add;
