function flag = test(lenchrom,bound,code)
% 检验染色体的可行性
% lenchrom    input:染色体的长度
% bound       input：变量的取值范围
% code        output：染色体的编码值

flag = 1;
[n,m] = size(code);

for i = 1:n
    if code(i) < bound(i,1) || code(i) > bound(i,2)
        flag = 0;
    end
end
end