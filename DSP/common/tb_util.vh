`ifndef TB_UTIL_VH
`define TB_UTIL_VH

// Parameters common to all testbenches
parameter CLOCK_PERIOD = 10;
parameter T_HOLD = 1;

reg  [15:0]     s_axis_phase_tdata  = 0;
reg             s_axis_phase_tvalid = 0;
reg             s_axis_phase_tlast  = 0;
wire            s_axis_phase_tready;

reg  [15:0]     s_axis_tdata  = 0;
reg             s_axis_tvalid = 0;
reg             s_axis_tlast  = 0;
wire            s_axis_tready;

reg  [31:0]     s_axis_xfft_tdata  = 0;
reg             s_axis_xfft_tvalid = 0;
reg             s_axis_xfft_tlast  = 0;
wire            s_axis_xfft_tready;

function integer clogb2;
input [31:0] value;
integer i;
begin
    clogb2 = 0;
    for(i = 0; 2**i < value; i = i + 1)
    clogb2 = i + 1;
end
endfunction

// Task to drive a single sample
task drive_sample;
    input [15:0] data;
    input        last;
    input integer valid_mode;
    begin
        s_axis_tdata <= data;
        s_axis_tlast <= last;
        if (valid_mode == 1) begin
            s_axis_tvalid <= 0;
            repeat(1 + $urandom % 4) @(posedge aclk);
            s_axis_tvalid <= 1;
        end else begin
            s_axis_tvalid <= 1;
        end
        @(posedge aclk);
        while (s_axis_tready == 0) @(posedge aclk);
        #T_HOLD;
        s_axis_tvalid <= 0;
    end
endtask

// Task to drive a single sample
task drive_xfft_sample;
    input [31:0] data;
    input        last;
    input integer valid_mode;
    begin
        s_axis_xfft_tdata <= data;
        s_axis_xfft_tlast <= last;
        if (valid_mode == 1) begin
            s_axis_xfft_tvalid <= 0;
            repeat(1 + $urandom % 4) @(posedge aclk);
            s_axis_xfft_tvalid <= 1;
        end else begin
            s_axis_xfft_tvalid <= 1;
        end
        @(posedge aclk);
        while (s_axis_xfft_tready == 0) @(posedge aclk);
        #T_HOLD;
        s_axis_xfft_tvalid <= 0;
    end
endtask

// Task for delta impulse test signal
task drive_delta;
    input integer N;
    input integer valid_mode;
    integer idx;
    begin
        for (idx = 0; idx < N; idx = idx + 1) begin
            if (idx == 0)
                drive_sample(16'd32767, (idx == N-1), valid_mode);
            else
                drive_sample(16'd0, (idx == N-1), valid_mode);
        end
    end
endtask


task drive_xfft_time;
    input integer N;       // number of samples to drive
    input real    f;       // desired sine frequency in Hz
    input integer valid_mode;
    integer idx;
    real angle;
    real angle_step;
    real amplitude;
    reg [15:0] x_re;
    reg [15:0] x_im;
    begin
         amplitude = 10000.0; // adjust amplitude as needed
         // Calculate phase increment per sample
         angle_step = 2.0 * 3.141592653589793 * f * 10e-9;
         for (idx = 0; idx < N; idx = idx + 1) begin
             angle = angle_step * idx;
             x_re = $rtoi(amplitude * $cos(angle));
             x_im = $rtoi(amplitude * $sin(angle));
             drive_xfft_sample({x_im, x_re}, (idx == N-1), valid_mode);
         end
    end
endtask

// Task for sine wave test signal with frequency as a parameter.
// Sample clock is 100 MHz (10 ns period)
task drive_sine;
    input integer N;       // number of samples to drive
    input real    f;       // desired sine frequency in Hz
    input integer valid_mode;
    integer idx;
    real angle;
    real angle_step;
    real amplitude;
    begin
         amplitude = 10000.0; // adjust amplitude as needed
         // Calculate phase increment per sample
         angle_step = 2.0 * 3.141592653589793 * f * 10e-9;
         for (idx = 0; idx < N; idx = idx + 1) begin
             angle = angle_step * idx;
             drive_sample($rtoi(amplitude * $sin(angle)), (idx == N-1), valid_mode);
         end
    end
endtask

// Task for chirp test signal (sweeping from 0 to 20 MHz over N samples)
task drive_chirp;
    input integer N;
    input integer valid_mode;
    integer idx;
    real phase;
    real Ts, k, amplitude;
    begin
         Ts = 10e-9; // sample period (10 ns)
         k = 20e6 / (N * Ts);
         amplitude = 16383.0;
         for (idx = 0; idx < N; idx = idx + 1) begin
             phase = 3.141592653589793 * k * Ts * Ts * idx * idx;
             drive_sample($rtoi(amplitude * $sin(phase)), (idx == N-1), valid_mode);
         end
    end
endtask

// Task for random noise test signal
task drive_noise;
    input integer N;
    input integer valid_mode;
    integer idx;
    begin
         for (idx = 0; idx < N; idx = idx + 1) begin
             drive_sample($urandom_range(0, 65535), (idx == N-1), valid_mode);
         end
    end
endtask

// Task to drive a single phase sample. This is similar to drive_sample,
// but for the phase interface (32-bit) used by DDS compilers.
task drive_phase_sample;
    input [15:0] phase_data;
    input        last;
    input integer valid_mode;
    begin
        s_axis_phase_tdata <= phase_data;
        s_axis_phase_tlast <= last;
        if (valid_mode == 1) begin
            s_axis_phase_tvalid <= 0;
            repeat(1 + $urandom % 4) @(posedge aclk);
            s_axis_phase_tvalid <= 1;
        end else begin
            s_axis_phase_tvalid <= 1;
        end
        @(posedge aclk);
        while (s_axis_phase_tready == 0) @(posedge aclk);
        #T_HOLD;
        s_axis_phase_tvalid <= 0;
    end
endtask

// Task for chirp test signal for DDS with internal phase generator.
// This task outputs only the phase delta (tuning word) for each sample.
// The chirp sweeps linearly from Freq_start to Freq_end over N samples.
// Frequency resolution is assumed to be 0.4 Hz per LSB.
task drive_phase_sin;
    input integer N;           // number of samples to stream
    input real    Freq_start;  // starting frequency in Hz
    input real    Freq_end;    // ending frequency in Hz
    input integer valid_mode;
    integer idx;
    real f_inst;
    integer unsigned delta;
    begin
         // For each sample, compute instantaneous frequency and corresponding tuning word.
         for (idx = 0; idx < N; idx = idx + 1) begin
             f_inst = Freq_start + (Freq_end - Freq_start) * idx / (N - 1);
             // Convert frequency (Hz) to delta-phase count using resolution of 0.4 Hz/LSB.
             delta = $rtoi(f_inst * 0.00065536);
             drive_phase_sample(delta, (idx == N-1), valid_mode);
         end
    end
endtask


// Task for chirp test signal for DDS with only LUT.
// This task outputs the accumulated phase for each sample.
// The chirp sweeps linearly from Freq_start to Freq_end over N samples.
// Frequency resolution is assumed to be 0.4 Hz per LSB.
// The phase accumulator is 28 bits wide.
task drive_lut_sin;
    input integer N;           // number of samples to stream
    input real    Freq_start;  // starting frequency in Hz
    input real    Freq_end;    // ending frequency in Hz
    input integer valid_mode;
    integer idx;
    real f_inst;
    integer unsigned delta;
    integer unsigned phase;
    begin
         phase = 0;
         for (idx = 0; idx < N; idx = idx + 1) begin
             f_inst = Freq_start + (Freq_end - Freq_start) * idx / (N - 1);
             // Convert frequency (Hz) to delta-phase count using resolution of 0.4 Hz/LSB.
             delta = $rtoi(f_inst * 0.00065536);
             phase = phase + delta;
             // Wrap the phase accumulator to 28 bits.
             // phase = phase & 28'hFFFFFFF;
             drive_phase_sample(phase, (idx == N-1), valid_mode);
         end
    end
endtask


`endif