tic

VWC = 0.120;
tag_depth = 0.1;
reader_height = 0.5;

packet_start_36 = [];
packet_start_96 = 0;
Pathloss = [];
Fs_rx = 9.6e6;
bw  = 96e3;

disp = 0;                                       %% Display real part of raw I/Q samples
upsampling_factor = 1;                          %% Default to 1

file_name_1 = 'Moisture_1_0.120_SH_50cm';
fil_pth_1 = ['C:\Users\Patron\Desktop\Soil Moisture Sensing\Moisture_Experiments\Tag_Depth_10cm\SH_50cm\Moisture_0.120\' file_name_1];
x_1 = load_file(fil_pth_1,upsampling_factor,0);

%Down Sampling Factor
ds_factor = Fs_rx/bw;

% Donwnsampling the signal
ds_x_1 = x_1(1:ds_factor:end);

% figure, subplot(311), plot(real(x_1))
% subplot(312), plot(real(ds_x_1))

bit_rate = 24e3;
N_samp = Fs_rx/bit_rate;
% ds_x_1 = ds_x_1(cursor_info.DataIndex:cursor_info1.DataIndex);
Time_1 = [];
Time_2 = [];
packet_start_36 = [];
packet_start_96 = 0;
p_ = 1;
[flag, p_1, packet_start_3, packet_start_96] = autocorrelation(ds_x_1,Fs_rx,ds_factor,bit_rate,0);
if (flag)
    for i = (1:length(packet_start_3))

        pointer_1 = (packet_start_3(i)* ds_factor)-(7* N_samp);
        pointer_2 = ((packet_start_3(i) * ds_factor) + 18*N_samp);
        ds_x_1 = x_1(pointer_1 : pointer_2);
        [flag, p_1,packet_start_36,packet_start_96] = autocorrelation(ds_x_1,9.6e6,1,bit_rate,flag);
        if (flag)
            [pathloss, power] = Calculate_Pathloss_1(((packet_start_96+pointer_1)/Fs_rx), 1000);
            fprintf("Detected packet at %d and time is %f and pathloss is -%f\n",packet_start_96+pointer_1,(packet_start_96+pointer_1)/Fs_rx,pathloss)
            Pathloss = [Pathloss pathloss];
            p_ = p_ + 1; 
            if (p_ > 2)
                Time_2 = [Time_2 (packet_start_96+pointer_1)/Fs_rx];
            else
                Time_1 = [Time_1 (packet_start_96+pointer_1)/Fs_rx];
            end
        end
    end
end

fprintf("The difference in pathloss is %f\n", diff(Pathloss))

[theoretical_pl_1, theoretical_pl_2] = compute_theoretical_pathlosses(VWC, reader_height, tag_depth);
fprintf("\n")
[estimated_soil_moisture] = compute_vwc_from_pathlosses(tag_depth,reader_height,Pathloss(1),Pathloss(2));


toc
