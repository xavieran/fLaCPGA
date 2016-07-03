function Ak = my_levinson(acf, order)
Ak = zeros(1, order + 1);
Ak(1) = 1;
Ek = acf(1);
lambda = 0;
for k = 1:order
    lambda = 0;
    for j = 1:k
        lambda = lambda - Ak(j)*acf(k + 1 -j);
    end
    lambda = lambda/ Ek;
    
    for n = 1:(k+1)/2
        t = Ak(k + 1 - n) + lambda*Ak(n);
        Ak(n) = Ak(n) + lambda*Ak(k+1-n);
        Ak(k+1-n) = t;
    end
    Ek = Ek*(1-lambda^2);
end

end