function residual = my_fir_filter(coeffs, data)

order = length(coeffs)

residual = int32(zeros(1, length(data)));
for i = order + 1:length(data)
    Sum = 0;
    for j = 1:order
        Sum = Sum + data(i - j)*coeffs(j);
    end
    
    residual(i) = data(i) - Sum/1024;
end

end