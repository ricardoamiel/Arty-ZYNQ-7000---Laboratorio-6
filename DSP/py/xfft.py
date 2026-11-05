import numpy as np
import matplotlib.pyplot as plt

def read_xfft_bin(filename):
    """
    Reads a binary file containing 32-bit big-endian words.
    Each word is interpreted as a complex number where:
      - Bits [31:16] are the imaginary part (16-bit signed).
      - Bits [15:0]  are the real part (16-bit signed).
    Returns a complex numpy array.
    """
    data = np.fromfile(filename, dtype='>i4')
    # Extract real and imaginary parts.
    real = np.int16(data & 0xFFFF)
    imag = np.int16((data >> 16) & 0xFFFF)
    return real.astype(np.float64) + 1j * imag.astype(np.float64)

def compute_fft(samples, fs):
    """
    Computes the FFT of a time-domain signal and returns:
      - freq: Frequency bins (positive frequencies)
      - fft_data: FFT result for the positive frequencies.
    """
    N = len(samples)
    fft_data_full = np.fft.fft(samples)
    pos_mask = np.fft.fftfreq(N, d=1/fs) >= 0
    fft_data = fft_data_full[pos_mask]
    freq = np.fft.fftfreq(N, d=1/fs)[pos_mask]
    return freq, fft_data

def plot_subplots(time_axes, freq_axes, fs, 
                  input_samples, fwd_samples, inv_samples):
    """
    Creates a 3x2 subplot figure:
      Row 1: xFFT Input.
      Row 2: Forward FFT output.
      Row 3: Inverse FFT output.
      
    time_axes and freq_axes are the axes arrays from plt.subplots(3,2).
    """
    # Row 1: xFFT Input.
    N_input = len(input_samples)
    t_input = np.arange(N_input) / fs  # seconds
    # Time domain: simply the input signal.
    time_axes[0,0].plot(t_input*1e6, np.real(input_samples), '.-b', label="Real")
    time_axes[0,0].plot(t_input*1e6, np.imag(input_samples), '.-r', label="Imag")
    time_axes[0,0].set_xlabel("Time (µs)")
    time_axes[0,0].set_ylabel("Amplitude")
    time_axes[0,0].set_title("xFFT Input - Time Domain")
    time_axes[0,0].legend()
    time_axes[0,0].grid(True)
    
    # Frequency domain: compute FFT of input signal.
    freq_input, fft_input = compute_fft(input_samples, fs)
    freq_axes[0,1].plot(freq_input/1e6, np.real(fft_input), '.-b', label="Real")
    freq_axes[0,1].plot(freq_input/1e6, np.imag(fft_input), '.-r', label="Imag")
    freq_axes[0,1].set_xlabel("Frequency (MHz)")
    freq_axes[0,1].set_ylabel("Amplitude")
    freq_axes[0,1].set_title("xFFT Input - Frequency Domain (FFT)")
    freq_axes[0,1].legend()
    freq_axes[0,1].grid(True)
    
    # Row 2: Forward FFT Output.
    # Time domain: reconstruct using inverse FFT.
    N_fwd = len(fwd_samples)
    # Note: fwd_samples is assumed to be the forward FFT output (frequency domain)
    # Here, we compute the inverse FFT. Since numpy.ifft scales by 1/N, multiply by N.
    # reconstructed = np.fft.ifft(fwd_samples) * N_fwd
    reconstructed = np.fft.ifft(fwd_samples)
    t_recon = np.arange(N_fwd) / fs  # assume same N as forward FFT output?
    # In many systems, the forward FFT output size equals the original FFT length.
    time_axes[1,0].plot(t_recon*1e6, np.real(reconstructed), '.-b', label="Real")
    time_axes[1,0].plot(t_recon*1e6, np.imag(reconstructed), '.-r', label="Imag")
    time_axes[1,0].set_xlabel("Time (µs)")
    time_axes[1,0].set_ylabel("Amplitude")
    time_axes[1,0].set_title("Forward FFT Output - Reconstructed Time Domain")
    time_axes[1,0].legend()
    time_axes[1,0].grid(True)
    
    # Frequency domain: for forward FFT output, plot as read (assume already frequency domain)
    # Create frequency axis from 0 to fs/2 with length equal to number of bins.
    freq_axis = np.linspace(0, fs/2, N_fwd)
    freq_axes[1,1].plot(freq_axis/1e6, np.real(fwd_samples), '.-b', label="Real")
    freq_axes[1,1].plot(freq_axis/1e6, np.imag(fwd_samples), '.-r', label="Imag")
    freq_axes[1,1].set_xlabel("Frequency (MHz)")
    freq_axes[1,1].set_ylabel("Amplitude")
    freq_axes[1,1].set_title("Forward FFT Output - Frequency Domain (Direct)")
    freq_axes[1,1].legend()
    freq_axes[1,1].grid(True)
    
    # Row 3: Inverse FFT Output.
    N_inv = len(inv_samples)
    t_inv = np.arange(N_inv) / fs
    # Time domain: plot inverse FFT output directly.
    time_axes[2,0].plot(t_inv*1e6, np.real(inv_samples), '.-b', label="Real")
    time_axes[2,0].plot(t_inv*1e6, np.imag(inv_samples), '.-r', label="Imag")
    time_axes[2,0].set_xlabel("Time (µs)")
    time_axes[2,0].set_ylabel("Amplitude")
    time_axes[2,0].set_title("Inverse FFT Output - Time Domain")
    time_axes[2,0].legend()
    time_axes[2,0].grid(True)
    
    # Frequency domain: compute FFT of inverse FFT output.
    freq_inv, fft_inv = compute_fft(inv_samples, fs)
    freq_axes[2,1].plot(freq_inv/1e6, np.real(fft_inv), '.-b', label="Real")
    freq_axes[2,1].plot(freq_inv/1e6, np.imag(fft_inv), '.-r', label="Imag")
    freq_axes[2,1].set_xlabel("Frequency (MHz)")
    freq_axes[2,1].set_ylabel("Amplitude")
    freq_axes[2,1].set_title("Inverse FFT Output - Frequency Domain (FFT)")
    freq_axes[2,1].legend()
    freq_axes[2,1].grid(True)

def main():
    # File paths (adjust as needed)
    file_input = "build/xfft_input.bin"
    file_fwd   = "build/xfft_fwd_out.bin"
    file_inv   = "build/xfft_inv_out.bin"
    
    # Sampling frequency (Hz)
    fs = 100e6  # 100 MHz
    
    # Read binary files.
    input_signal = read_xfft_bin(file_input)
    fwd_signal   = read_xfft_bin(file_fwd)
    inv_signal   = read_xfft_bin(file_inv)
    
    print("Input samples:", len(input_signal))
    print("Forward FFT samples:", len(fwd_signal))
    print("Inverse FFT samples:", len(inv_signal))
    
    # Create a 3x2 subplot figure (3 rows, 2 columns)
    fig, axes = plt.subplots(3, 2, figsize=(12, 12))
    # We'll pass axes[:,0] for time-domain plots and axes[:,1] for frequency-domain plots.
    plot_subplots(axes, axes, fs, input_signal, fwd_signal, inv_signal)
    
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()
