function [flag,p,packet_start_36,packet_start_96] = autocorrelation(ds_x_1,Fs_rx,ds_factor,bit_rate,flag)

N_samp = (Fs_rx/ds_factor)/bit_rate;
win_len = N_samp * 4;
loop_end = length(ds_x_1) - 2*win_len - 1;

i = 1;
k = 1;
auto_corr=[];

packet_start_36 = [];
packet_start_96 = 0;

r=1;
o = 1;
p=1;
n = 1;
z = [];

% Assigning windows for autocorrelation and looping from start to end of
% the file

while i < loop_end

    win_1 = ds_x_1(i : (i + win_len - 1));
    win_2 = ds_x_1((i + win_len) : (i + 2*win_len - 1));

    auto_corr(k) = sum (win_1 .* conj(win_2)) /...
        sqrt(sum(win_1 .* conj(win_1)) * sum(win_2 .* conj(win_2)));

    abs(auto_corr(k));
    % If we see a peak and it is higher than a threshold then, now check
    % for start and stop bits by demodulating them
    % abs(auto_corr(k))
    % threshold = sum(abs(auto_corr))/k;
    if flag
        threshold = 0.9;
    else
        threshold = 0.8;
    end
    if ((k>2) && (abs(auto_corr(k-1)) > abs(auto_corr(k))) && (abs(auto_corr(k-1)) > abs(auto_corr(k-2))) && abs(auto_corr(k-1)) > threshold)
        if ((i-1) - (N_samp*4)) > 0

            if (flag && (i-1 + (12*N_samp)) < length(ds_x_1))
                demod_sig = ds_x_1( ((i-1) - (N_samp*4)) : (i-1 + (12*N_samp)));
                sig_len = length(demod_sig);
                if mod(sig_len,N_samp) > 0
                    while mod(size(demod_sig,2),N_samp) ~= 0
                        demod_sig(end)=[];
                    end
                end
                z = fskdemod(demod_sig,2,20e3,N_samp,Fs_rx);
                if ((length(z) == 16) && isequal(z(1:4),[0 0 1 0]) && isequal(z(13:16),[0 1 0 0]) && isequal(z(5:12),[1 1 1 1 1 1 1 1]))
                    p = p+1;
                    packet_start_96 = ((i-1) - (N_samp*4));
                    break
                end
                
            else
                demod_sig = ds_x_1( ((i-1)) : (i-1 + (8*N_samp)));
                sig_len = length(demod_sig);
                if mod(sig_len,N_samp) > 0
                    while mod(size(demod_sig,2),N_samp) ~= 0
                        demod_sig(end)=[];
                    end
                end
                z = fskdemod(demod_sig,2,20e3,N_samp,Fs_rx/ds_factor);
                if ((length(z) == 8) && isequal(z(1:8),[1 1 1 1 1 1 1 1]) && bandpower(demod_sig) > 0.000005)
                    packet_start_36 = [packet_start_36 i-1];
                    i = i + 10000*N_samp;
                    p = p + 1;
                    if (p > 2)
                        flag = 1;
                        break
                    end
                end
                
            end
        end
    end

    k = k + 1;
    if flag
        i = i + 1;
    else
        i = i + 1;
    end
end
