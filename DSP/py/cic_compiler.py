import numpy as np
import matplotlib.pyplot as plt

def read_int16_be(filename, expected_samples):
    """
    Read a binary file containing 16-bit big-endian integers.
    Returns a numpy array of float64 values.
    """
    data = np.fromfile(filename, dtype='>i2')
    if len(data) != expected_samples:
        print(f"Warning: Expected {expected_samples} samples, but got {len(data)}")
    return data.astype(np.float64)

def compute_fft_and_sfdr(samples, fs):
    """
    Compute the FFT (only positive frequencies) and return:
      - freq: Frequency bins (Hz)
      - mag_db: Magnitude in dB
      - sfdr: Spurious-Free Dynamic Range (in dB)
      - idx_peak: Index of the fundamental peak
    """
    N = len(samples)
    fft_data = np.fft.fft(samples)
    fft_data = fft_data[:N//2]  # Positive frequencies
    freq = np.fft.fftfreq(N, d=1/fs)[:N//2]
    mag = np.abs(fft_data)
    # Avoid log(0)
    mag_db = 20 * np.log10(mag + 1e-12)
    
    # Find the fundamental peak
    idx_peak = np.argmax(mag)
    fundamental_db = mag_db[idx_peak]
    
    # Exclude a few bins around the peak (e.g., ±2 bins) to find the largest spur.
    idx_start = max(0, idx_peak-2)
    idx_end = min(len(mag_db), idx_peak+3)
    mag_db_excl = mag_db.copy()
    mag_db_excl[idx_start:idx_end] = -np.inf
    spur_db = np.max(mag_db_excl)
    sfdr = fundamental_db - spur_db
    return freq, mag_db, sfdr, idx_peak

def plot_signal(time, samples, fs, title):
    """
    Plot the time-domain waveform and the FFT magnitude (in dB) of the signal.
    The SFDR is estimated and shown in the frequency-domain plot title.
    """
    N = len(samples)
    # Time-domain plot
    plt.figure(figsize=(12, 8))
    plt.subplot(2, 1, 1)
    plt.plot(time * 1e6, samples, '.-b')
    plt.xlabel("Time (µs)")
    plt.ylabel("Amplitude")
    plt.title(title + " - Time Domain")
    plt.grid(True)
    
    # Frequency-domain plot
    freq, mag_db, sfdr, idx_peak = compute_fft_and_sfdr(samples, fs)
    plt.subplot(2, 1, 2)
    plt.plot(freq/1e6, mag_db, '.-b')
    plt.xlabel("Frequency (MHz)")
    plt.ylabel("Magnitude (dB)")
    plt.title(title + " - Frequency Domain ")
    plt.grid(True)
    
    plt.tight_layout()
    

def main():
    # File names (adjust the path as needed)
    file_input = "build/cic_input.bin"
    file_decim = "build/cic_decim_out.bin"
    file_inter = "build/cic_inter_out.bin"
    
    # Expected number of samples from testbench
    num_input = 2048
    num_decim = 128
    num_inter = 2048
    
    # Sampling frequencies:
    fs_input = 100e6         # 100 MHz for the input signal (10 ns period)
    fs_decim = 100e6 / 16    # 6.25 MHz for decimator output (160 ns period)
    fs_inter = 100e6         # 100 MHz for the interpolator output (restored rate)
    
    # Read the binary files (each sample is a 16-bit signed integer)
    input_samples = read_int16_be(file_input, num_input)
    decim_samples = read_int16_be(file_decim, num_decim)
    inter_samples = read_int16_be(file_inter, num_inter)
    
    # Create time vectors for each set
    t_input = np.arange(len(input_samples)) / fs_input
    t_decim = np.arange(len(decim_samples)) / fs_decim
    t_inter = np.arange(len(inter_samples)) / fs_inter
    
    # Plot the signals
    plot_signal(t_input, input_samples, fs_input, "CIC Input")
    plot_signal(t_decim, decim_samples, fs_decim, "CIC Decimator Output")
    plot_signal(t_inter, inter_samples, fs_inter, "CIC Interpolator Output")
    plt.show()
    
if __name__ == "__main__":
    main()
