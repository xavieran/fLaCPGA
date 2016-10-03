%% Calculate Levinson Durbin of some data... 
% The following flac command was used
% flac -V -b 4096 -l 12  -A hamming ../../audio/Pavane16Blocks.wav -f
% resulting coefficients were 
%format long
%flac_qlp = [1427,-154,416,-517,-134,-281,-54,136,140,131,116,-206]


data = dlmread('Pavane16Blocks.txt');
% Window using hamming window...
data = data(1:end);%.*hamming(4096);
%data = data(1+4096:4096+4096);%.*hamming(4096);

order = 10;
blocks = 1;



%%
% Ra = b
% R = [acf(1), acf(2), ..., acf(n);
%      acf(2), acf(1), ..., acf(n - 1);
%      ...;
%      acf(n), ..., acf(2), acf(1)]
% b = -[acf(2), acf(3), ...,  acf(n), acf(1)]
% execute 'doc levinson' to view the R and b matrices

% Inversion is O(N^3), so for N=12 which is the case for FLAC
% ~1728 operations...

%R = toeplitz(ACF(1:end-1));
%b = -ACF(2:end);
%A = inv(R)*b;
%A = [1, A']

residuals = zeros(size(data));
for i = 1:blocks
    ACF = autocorr(data(4096*(i-1) + 1:4096*i).*hamming(4096), order)
    A = my_levinson(ACF, order);
    A = A(order,:);
    A = round(A*-1024);

    coeffs = int32((A(2:end)))
    residuals(4096*(i-1) + 1:4096*i) = my_fir_filter(coeffs, data(4096*(i-1) + 1:4096*i));
    
end

hold on
plot(data, 'r.')
plot(residuals, 'g*')

play = double(residuals);
play = play./max(play);
play = .6*play;
sound(play, 44100)



%plot(1:order, A(2:end)*flac_qlp(1)/A(2), 'ob',1:order,flac_qlp, '+r')
%legend('Me', 'FLAC');
%title('Calculated model and FLAC quantized model');

