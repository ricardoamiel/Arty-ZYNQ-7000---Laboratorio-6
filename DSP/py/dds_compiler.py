import numpy as np
import matplotlib.pyplot as plt

def read_dds_32(filename):
    """
    Reads a 32-bit DDS output file.
    The 32-bit word is assumed to be in big-endian order,
    with bits [31:16] representing the imaginary part and
    bits [15:0] representing the real part (in 16-bit two's complement).
    Returns a complex numpy array.
    """
    # Read as big-endian 32-bit integer
    data = np.fromfile(filename, dtype='>i4')
    # Extract real and imag parts.
    # Lower 16 bits (0xFFFF mask) is real, upper 16 bits is imag.
    real = np.int16(data & 0xFFFF)
    imag = np.int16((data >> 16) & 0xFFFF)
    return real.astype(np.float64) + 1j * imag.astype(np.float64)

def sign_extend_24(x):
    """
    Given an array x of 24-bit unsigned values (stored in a 32-bit container),
    returns an array of signed 24-bit values (as int32).
    """
    mask = 1 << 23
    # Where the sign bit is set, subtract 2^24.
    x_signed = x.copy().astype(np.int32)
    x_signed = np.where(x & mask, x_signed - (1 << 24), x_signed)
    return x_signed

def read_dds_48(filename):
    """
    Reads a 48-bit DDS output file.
    Each sample is 6 bytes, stored in big-endian order.
    For each sample:
      - Bytes [0:2] (most significant) form the imaginary part (24 bits)
      - Bytes [3:5] form the real part (24 bits)
    Both parts are in two's complement.
    Returns a complex numpy array.
    """
    data = np.fromfile(filename, dtype=np.uint8)
    num_samples = len(data) // 6
    data = data.reshape((num_samples, 6))
    # Combine bytes for imag and real.
    # For imag: bytes 0,1,2
    imag = (data[:,0].astype(np.uint32) << 16) | (data[:,1].astype(np.uint32) << 8) | data[:,2].astype(np.uint32)
    # For real: bytes 3,4,5
    real = (data[:,3].astype(np.uint32) << 16) | (data[:,4].astype(np.uint32) << 8) | data[:,5].astype(np.uint32)
    imag = sign_extend_24(imag)
    real = sign_extend_24(real)
    return real.astype(np.float64) + 1j * imag.astype(np.float64)

def compute_fft_and_sfdr(samples, fs):
    """
    Computes the FFT of the samples and returns:
      - freq: frequency bins (only positive frequencies)
      - mag_db: magnitude spectrum in dB
      - sfdr: spurious free dynamic range in dB
      - idx_peak: index of the fundamental peak in the FFT
    A simple SFDR estimation is computed as the difference between the
    fundamental and the largest spurious tone (after removing bins near the peak).
    """
    N = len(samples)
    fft_samples = np.fft.fft(samples)
    fft_samples = fft_samples[:N//2]  # positive frequencies
    freq = np.fft.fftfreq(N, 1/fs)[:N//2]
    mag = np.abs(fft_samples)
    # Avoid log(0) issues.
    mag_db = 20 * np.log10(mag + 1e-12)
    
    # Identify the fundamental peak.
    idx_peak = np.argmax(mag)
    fundamental_db = mag_db[idx_peak]
    # Exclude a window around the fundamental (e.g., ±2 bins) when searching for spur.
    idx_start = max(0, idx_peak-2)
    idx_end = min(len(mag_db), idx_peak+3)
    mag_db_excluding = mag_db.copy()
    mag_db_excluding[idx_start:idx_end] = -np.inf
    spur_db = np.max(mag_db_excluding)
    sfdr = fundamental_db - spur_db
    return freq, mag_db, sfdr, idx_peak

def plot_results(samples, fs, title):
    """
    Plots the time-domain (real and imaginary) signal and its frequency-domain
    magnitude (in dB). Also computes and displays the SFDR.
    """
    N = len(samples)
    t = np.arange(N) / fs

    # Time-domain plot.
    plt.figure(figsize=(12, 10))
    plt.subplot(2,1,1)
    plt.plot(t, np.real(samples), '.-b', label="Real")
    plt.plot(t, np.imag(samples), '.-r', label="Imag")
    plt.xlabel("Time (s)")
    plt.ylabel("Amplitude")
    plt.title(title + " - Time Domain")
    plt.legend()
    plt.grid(True)
    
    # Frequency-domain.
    freq, mag_db, sfdr, idx_peak = compute_fft_and_sfdr(samples, fs)
    plt.subplot(2,1,2)
    plt.plot(freq/1e6, mag_db, '.-b', label="Magnitude Spectrum")
    plt.xlabel("Frequency (MHz)")
    plt.ylabel("Magnitude (dB)")
    plt.title(title + " - Frequency Domain ")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    

def main():
    fs = 100e6  # Sampling frequency (e.g., 100 MHz)
    
    # Read files.
    samples_lut = read_dds_32("build/dds_lut_out.bin")
    samples_phase = read_dds_32("build/dds_phase_out.bin")
    samples_input = np.fromfile("build/dds_phase_in.bin", dtype=np.int16)
    
    print("dds_lut_out.bin: {} samples".format(len(samples_lut)))
    print("dds_phase_out.bin: {} samples".format(len(samples_phase)))
    
    # Plot results.
    plot_results(samples_lut, fs, "DDS LUT")
    plot_results(samples_phase, fs, "DDS Phase")

    plt.figure(figsize=(12,10))
    plt.plot(samples_input, '.-b')
    plt.title("Input Phase")
    plt.xlabel("Samples")
    plt.grid()

    plt.show()

if __name__ == "__main__":
    main()
