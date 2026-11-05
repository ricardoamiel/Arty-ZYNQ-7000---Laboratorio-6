import numpy as np
import matplotlib.pyplot as plt

def plot_signal(time, signal, title):
    """Plot time-domain and frequency-domain representations of a signal."""
    fig, axs = plt.subplots(2, 1, figsize=(10, 8))
    
    # Time-domain plot
    axs[0].plot(time, signal, '.-b', label='Time Domain')
    axs[0].set_title(f'{title} - Time Domain')
    axs[0].set_xlabel('Time (s)')
    axs[0].set_ylabel('Amplitude')
    axs[0].grid(True)
    axs[0].legend()
    
    # Frequency-domain plot
    N = len(signal)
    fft_signal = np.fft.fft(signal)/N
    fft_magnitude = 20*np.log10(np.abs(fft_signal))
    fs = 1 / (time[1] - time[0])  # Sampling frequency from time step
    freq = np.fft.fftfreq(N, d=(time[1] - time[0]))
    pos_mask = freq >= 0
    axs[1].plot(freq[pos_mask]/1e6, fft_magnitude[pos_mask], '.-b', label='Magnitude Spectrum')
    axs[1].set_title(f'{title} - Frequency Domain')
    axs[1].set_xlabel('Frequency (MHz)')
    axs[1].set_ylabel('Magnitude, dB')
    axs[1].grid(True)
    axs[1].legend()
    
    plt.tight_layout()
    

def plot_hilbert_signal(time, signal_re, signal_im, title):
    """Plot time-domain and frequency-domain representations of a Hilbert-transformed signal."""
    fig, axs = plt.subplots(3, 1, figsize=(10, 10))

    # Time-domain plot - Real part
    axs[0].plot(time, signal_re, '.-b', label='Real Part')
    axs[0].plot(time, signal_im, '.-r', label='Imaginary Part', alpha=0.7)
    axs[0].set_title(f'{title} - Time Domain')
    axs[0].set_xlabel('Time (s)')
    axs[0].set_ylabel('Amplitude')
    axs[0].grid(True)
    axs[0].legend()

    # Time-domain plot - Signal magnitude
    signal_mag = np.sqrt(signal_re**2 + signal_im**2)
    axs[1].plot(time, signal_mag, '.-g', label='Magnitude')
    axs[1].set_title(f'{title} - Signal Magnitude')
    axs[1].set_xlabel('Time (s)')
    axs[1].set_ylabel('Magnitude')
    axs[1].grid(True)
    axs[1].legend()

    # Frequency-domain plot
    N = len(signal_re)
    fft_signal = np.fft.fft(signal_re + 1j * signal_im) / N  # Compute FFT of complex signal
    fft_magnitude = 20 * np.log10(np.abs(fft_signal))
    fs = 1 / (time[1] - time[0])  # Sampling frequency from time step
    freq = np.fft.fftfreq(N, d=(time[1] - time[0]))
    pos_mask = freq >= 0  # Keep only positive frequencies

    axs[2].plot(freq[pos_mask] / 1e6, fft_magnitude[pos_mask], '.-b', label='Magnitude Spectrum')
    axs[2].set_title(f'{title} - Frequency Domain')
    axs[2].set_xlabel('Frequency (MHz)')
    axs[2].set_ylabel('Magnitude (dB)')
    axs[2].grid(True)
    axs[2].legend()

    plt.tight_layout()


def main():
    
    # Data is stored as 32-bit big-endian signed integers.
    fir_input = np.fromfile("build/fir_input.bin", dtype='>i2')
    print(f"Read {len(fir_input)} samples from fir_input.bin")

    # Data is stored as 32-bit big-endian signed integers.
    fir_bp = np.fromfile("build/fir_bpass_out.bin", dtype='>i4')
    print(f"Read {len(fir_bp)} samples from fir_bpass_out.bin")
    
    fir_inter = np.fromfile("build/fir_inter_out.bin", dtype='>i4')
    print(f"Read {len(fir_inter)} samples from fir_inter_out.bin")
    
    fir_decim = np.fromfile("build/fir_decim_out.bin", dtype='>i4')
    print(f"Read {len(fir_decim)} samples from fir_decim_out.bin")
    
    fir_hilb = np.fromfile("build/fir_hilb_out.bin", dtype='>i2')
    print(f"Read {len(fir_hilb)} samples from fir_hilb_out.bin")
    
    fir_hilb = fir_hilb.reshape(-1, 2)
    fir_hilb_re = fir_hilb[:, 0]  # First column: real part
    fir_hilb_im = fir_hilb[:, 1]  # Second column: imaginary part
    

    # Simulation sample period: 10 ns per sample
    sample_period = 10e-9
    
    # Create time vectors for each segment
    t_decim = np.arange(len(fir_decim)) * sample_period * 4
    t_inter = np.arange(len(fir_inter))  * sample_period
    
    # Plot each signal separately
    plot_signal(t_inter, fir_input, "FIR Compiler Input")
    plot_signal(t_inter, fir_bp, "FIR BandPass")
    plot_signal(t_inter, fir_inter, "FIR Interpolator")
    plot_signal(t_decim, fir_decim, "FIR Decimator")
    plot_hilbert_signal(t_inter, fir_hilb_re, fir_hilb_im, "FIR Hilbert")
    plt.show()

if __name__ == "__main__":
    main()

