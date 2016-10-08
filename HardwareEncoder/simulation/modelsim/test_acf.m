start = 400;
blocks = 1;

sound = dlmread('wakeup_pcm.txt', '',[start*4096, 0, (blocks + start)*4096, 0]);

[acf, lags] = autocorr(sound, 12)