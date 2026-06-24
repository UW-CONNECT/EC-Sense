import uhd
import numpy as np
import threading
import argparse
from CSI_Estimation import *
import time

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-a", "--args", default="", type=str)
    parser.add_argument("-o", "--output-file", type=str, required=	True)
    parser.add_argument("-r", "--sample_rate", default=1e6, type=float)
    parser.add_argument("-d", "--receive_duration", default=5.0, type=float)
    parser.add_argument("-c","--clock",default= 16e6, type = float)
    return parser.parse_args()

        
args = parse_args()

usrp = uhd.usrp.MultiUSRP()
#f = open('/home/uwcon/Desktop/TX_5sec','rb') # create random signal
# USRP parameters

usrp.set_master_clock_rate(args.clock)

#sample_rate = 2e6 # Sample rate in samples per second
#transmit_gain = 71.5
transmit_gain = 72  # Gain in dB
receive_gain = 10



# Signal parameters
signal_duration = 5  # Signal duration in seconds
frequency = 1e3  # Signal frequency in Hz
amplitude = 1 # Signal amplitude

# Receive parameters
#receive_duration = 10  #Receive duration in seconds
#receive_filename = 'received_samples' # File name to save received samples

# Generate signal
signal = amplitude * np.exp(2j * np.pi * frequency * np.arange(signal_duration * args.sample_rate))
signal_samples = np.append(np.zeros((10,),dtype=complex),signal)


# Thread function for transmitting
def transmit():
    # Start transmission

    center_freq = 902e6 
    usrp.set_tx_bandwidth(200e3)

    usrp.send_waveform(signal_samples, signal_duration, center_freq, args.sample_rate, [1], transmit_gain)
    #print(usrp.get_tx_bandwidth())

# Thread function for receiving
def receive():
    
    center_freq_1 = 926.0075e6 # Center frequency in Hz
    usrp.set_rx_bandwidth(200e3)
    # Receive samples 
    
    num_samps = int(np.ceil(args.receive_duration*args.sample_rate))
    samps = usrp.recv_num_samps(num_samps, center_freq_1, args.sample_rate, [0] , receive_gain)
    #print(usrp.get_rx_bandwidth())
    
    samps = samps.astype(np.complex64) # Convert to 64
    samps.tofile(args.output_file) # Save to file
    # save received samples to a file
    #with open(receive_filename, 'wb') as file:
     #   np.save(file, samps, allow_pickle=False, fix_imports=False)


# Create and start transmit thread
#time_tx = usrp.get_time_now().get_real_secs()
time_tx = time.time()
print("TX started : ",time_tx)

transmit_thread = threading.Thread(target=transmit)
transmit_thread.start()


# Create and start receive thread
#time_rx = usrp.get_time_now().get_real_secs()
time_rx = time.time()
print("RX started : ",time_rx)

receive_thread = threading.Thread(target=receive)
receive_thread.start()

# Wait for threads to complete
print("Time Difference", (time_rx - time_tx))

# Wait for threads to complete

#transmit_thread.join()
receive_thread.join()

#time_diff = usrp.get_time_now().get_real_secs() - time_rx
time_diff = time.time() - time_rx
print("RX ended : ",time_diff)

Nsamp = int(args.sample_rate // 1.2e3)
win_len = Nsamp * 16
Packet_Detection(args.output_file, args.sample_rate, Nsamp, win_len)




#usrp.close()




