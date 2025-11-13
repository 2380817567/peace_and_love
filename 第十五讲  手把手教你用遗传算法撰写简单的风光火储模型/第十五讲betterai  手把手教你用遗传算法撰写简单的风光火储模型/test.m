function flag = test(lenchrom,bound,code)
%lenchrom    input:染色体的长度
%bound       input：变量的取值范围
%code        output：染色体的编码值

flag = 1;
if isrow(code)
    % 处理行向量
    for i = 1:length(code)
        if i <= size(bound,1) && (code(i) < bound(i,1) || code(i) > bound(i,2))
            flag = 0;
            break;
        end
    end
else
    % 处理矩阵
    [n,m] = size(code);
    for i = 1:n
        for j = 1:m
            if j <= size(bound,1) && (code(i,j) < bound(j,1) || code(i,j) > bound(j,2))
                flag = 0;
                return;
            end
        end
    end
end