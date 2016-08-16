%% Calculate Levinson Durbin of some data... 
% The following flac command was used
% flac -V -b 4096 -l 12  -A hamming ../../audio/Pavane16Blocks.wav -f
% resulting coefficients were 
flac_qlp = [1427,-154,416,-517,-134,-281,-54,136,140,131,116,-206]


data = dlmread('Pavane16Blocks.txt');
% Window using hamming window...
data = data(1:4096);%.*hamming(4096);
%data = data(1+4096:4096+4096);%.*hamming(4096);

order = 12;

ACF =  my_autocorr(data, order)

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

A = my_levinson(ACF, order)
A = A(13,:)

filtered = filter([0, -A(2:order)], 1, data);

%sound(filtered - data, 44100)

plot(1:order, A(2:end)*flac_qlp(1)/A(2), 1:order,flac_qlp, 'r')
legend('Me', 'FLAC');
title('Calculated model and FLAC quantized model');