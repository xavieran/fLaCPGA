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


k(2) = -alpha(1)/Ek(1);
Ak(2, 2) = k(2);
%disp('!!!!')
%acf(2)
%Ak(2,2)
%acf(3)
alpha(2) = acf(2)*Ak(2,2) + acf(3);
Ek(2) = Ek(1)*(1 - k(2)^2);

for i = 3:order + 1
    k(i) = -alpha(i - 1)/Ek(i - 1);
    for j = 2:(i/2 + 1)
        a = j;
        b = i - j + 1;
        Ak(i, a) = Ak(i - 1, a) + k(i)*Ak(i - 1, b);
        Ak(i, b) = Ak(i - 1, b) + k(i)*Ak(i - 1, a); 
    end
    
    Ak(i,i) = k(i);
    
    Ek(i) = (1 - k(i)^2) * Ek(i - 1);
    
    if (i ~= order + 1)
        for j = 1:i
            alpha(i) = alpha(i) + Ak(i, j)*acf(i - j + 2);
        end
    end
end

%Ak
%k
%alpha
%Ek

end