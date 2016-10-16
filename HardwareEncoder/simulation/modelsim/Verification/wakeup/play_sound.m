%% Play sound!

s = dlmread('data.txt');
%real_s = dlmread('../wakeup_pcm.txt');
real_s = dlmread('../PavaneAll256.pcm');

s = s(1:4096*251);
disp('Read data')
% Note that we ignore the last 4 blocks because they weren't actually
% written due to the latency of the encoder...
play = s;
%play = s - real_s(1:length(s));
%play = real_s;

play = play./max(play);

sound(play, 44100)

b = 251;
plot(1:4096*b, s(1:4096*b), 'bo', 1:4096*b, real_s(1:4096*b), 'r+')