%% Wakeup:

close all
blocks = 80;
res_start = 0;
start = 0;
%data = dlmread('test_stages_res_out.txt', '', [0*4096, 0, (blocks)*4096, 0]);
%sound = dlmread('Pavane16Blocks.txt', '', [start*4096, 0, (blocks + start)*4096, 0]);
%data = dlmread('pavane_residuals.txt', '', [start*4096, 0, (blocks + start)*4096, 0]);
%sound = dlmread('Pavane_PCM_All.txt', '', [start*4096, 0, (blocks + start)*4096, 0]);

data = dlmread('wakeup_test_residuals.txt', '',[res_start*4096, 0, (res_start + blocks)*4096, 0]);
sound = dlmread('wakeup_pcm.txt', '',[start*4096, 0, (blocks + start)*4096, 0]);

hold on;
plot(sound, 'b+');

plot(data,'ro');

a = 500;
p = zeros(4096, 1) + 1;
n  = zeros(4096, 1) - 1;

jj = [p*a; n*a];
jj = repmat(jj, floor(size(data,1)/(4096*2)));

plot(jj,'g')
legend('Audio','Residual', 'Blocks');


%  figure;
%  b = 1;
%  hist(data, 100);
%  title('Histogram of residuals')
%  figure;
%  hist(sound, 100);
% title('Histogram of audio')

