function ACF = my_autocorr(data, lags)

ACF = zeros(lags + 1, 1);

for i = 1:max(size(data))
    for j = 0:lags
        if (i + j) < max(size(data))
            ACF(j + 1) = ACF(j + 1) + data(i)*data(i + j);
        end
    end
end

ACF = ACF/ACF(1);
end


% function ACF = my_autocorr(data, lags)
% 
% m = mean(data);
% ACF = zeros(lags + 1, 1);
% normalizer = sum((data - m).^2);
% 
% for i = 1:max(size(data))
%     for j = 0:lags
%         if (i + j) < max(size(data))
%             ACF(j + 1) = ACF(j + 1) + (data(i) - m)*(data(i + j) - m);
%         end
%     end
% end
% 
% ACF = ACF/normalizer;
% end