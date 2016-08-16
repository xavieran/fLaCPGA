function [Ak, k, Ek] = my_levinson(acf, order)

% Ak are the predictor coefficients
Ak = zeros(order + 1, order + 1);
Ak(:,1) = 1;

% Ek are the predictor error
Ek = zeros(1, order + 1);
Ek(1) = acf(1);

% Alpha are the top col of the R matrix * the current model
alpha = zeros(1, order + 1);
alpha(1) = Ak(1,1)*acf(2);

% k are the reflection coefficents
k = zeros(1, order + 1);

for i = 2:order + 1
    k(i) = -alpha(i - 1)/Ek(i - 1);
    
    Ek(i) = (1 - abs(k(i))^2) * Ek(i - 1);
    
    for j = 2:i
        Ak(i, j) = Ak(i - 1, j) + k(i)*Ak(i - 1, i - j + 1);
    end
    
    if (i ~= order + 1)
        %alpha(i) = sum(acf.*fliplr(Ak(i,:)));
        for j = 1:i
            alpha(i) = alpha(i) + Ak(i, j)*acf(i - j + 2);
        end
    end
end

end