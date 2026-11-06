`timescale 1ns / 1ps

// Testbench con los mismos datos y configuración que inyecta el ARM en xfft_main.c:
// señal cuadrada real (periodo 64 muestras, amplitud 16000), FFT de 2048 puntos con escalamiento 0x6AA
// y FFT inversa sin escalamiento. Vuelca un VCD para el diagrama de tiempo.
module xfft_square_tb();

reg             aresetn = 0;
reg             aclk    = 0;

reg 			s_config_fft_tvalid = 0;
reg  [23 : 0] 	s_config_fft_tdata = 0;
wire 			s_config_fft_tready;

reg 			s_config_ifft_tvalid = 0;
reg  [23 : 0] 	s_config_ifft_tdata = 0;
wire 			s_config_ifft_tready;

wire [31 : 0] 	m_axis_fft_tdata;
wire    		m_axis_fft_tvalid;
wire    		m_axis_fft_tready;
wire    		m_axis_fft_tlast;

wire [31 : 0] 	m_axis_ifft_tdata;
wire    		m_axis_ifft_tvalid;
wire    		m_axis_ifft_tlast;


`include "tb_util.vh"


always
    #(CLOCK_PERIOD/2) aclk = ~aclk;

// Señal cuadrada real: +A medio periodo y -A el otro medio, parte imaginaria cero (igual que init_tx_buffer_square)
task drive_xfft_square;
    input integer N;
    input integer periodo;
    input integer amplitud;
    input integer valid_mode;
    integer idx;
    reg signed [15:0] x_re;
    begin
        for (idx = 0; idx < N; idx = idx + 1) begin
            x_re = ((idx % periodo) < (periodo / 2)) ? amplitud : -amplitud;
            drive_xfft_sample({16'd0, x_re}, (idx == N-1), valid_mode);
        end
    end
endtask

// Volcado de las señales del nivel superior para el diagrama de tiempo
initial begin
    $dumpfile("../../../../../xfft_sq.vcd");
    $dumpvars(1, xfft_square_tb);
end

    
       
event reset_start;
event reset_done;

always // reset
begin
aresetn <= 1;
@(reset_start);
$display("<-- Reset");
    aresetn <= 0;
    repeat(10)@(posedge aclk);
    aresetn <= 1;
-> reset_done;
$display("<-- Reset done");
end
 
reg  [11 : 0]   config_reg = 0;
reg   [3 : 0]     log2nFFT = 0;
reg   [4 : 0]   FWD  = 5'b10000;
reg   [4 : 0]   INV  = 5'b00000;
 
always @(*)
      case (log2nFFT)
         4'b0000: config_reg = 12'd6;
         4'b0001: config_reg = 12'd6;
         4'b0010: config_reg = 12'd6;
         4'b0011: config_reg = 12'd6;
         4'b0100: config_reg = 12'd10;
         4'b0101: config_reg = 12'd26;
         4'b0110: config_reg = 12'd42;
         4'b0111: config_reg = 12'd106;
         
         4'b1000: config_reg = 12'd170;
         4'b1001: config_reg = 12'd426;
         4'b1010: config_reg = 12'd682;
         4'b1011: config_reg = 12'd1706;
         4'b1100: config_reg = 12'd2730;
         4'b1101: config_reg = 12'd2730;
         4'b1110: config_reg = 12'd2730;
         4'b1111: config_reg = 12'd2730;
      endcase

//---------------------------------------------------------
// File I/O: Write output samples to a binary file for analysis
//---------------------------------------------------------
integer fp_input, fp_fwd, fp_inv;


initial begin
    fp_fwd = $fopen("../../../../../xfft_sq_fwd_out.bin", "wb");
    if (!fp_fwd) begin
        $display("Error: Could not open output file!");
        $finish;
    end

    fp_inv = $fopen("../../../../../xfft_sq_inv_out.bin", "wb");
    if (!fp_inv) begin
        $display("Error: Could not open output file!");
        $finish;
    end

    fp_input = $fopen("../../../../../xfft_sq_input.bin", "wb");
    if (!fp_input) begin
        $display("Error: Could not open input data file!");
        $finish;
    end

end


always @(posedge aclk) begin
    if (s_axis_xfft_tvalid) begin
       $fwrite(fp_input, "%c", s_axis_xfft_tdata[31:24]);
       $fwrite(fp_input, "%c", s_axis_xfft_tdata[23:16]);
       $fwrite(fp_input, "%c", s_axis_xfft_tdata[15:8]);
       $fwrite(fp_input, "%c", s_axis_xfft_tdata[7:0]);
    end
end

// Capture and write DUT outputs whenever valid.
always @(posedge aclk) begin
    if (m_axis_fft_tvalid) begin
       $fwrite(fp_fwd, "%c", m_axis_fft_tdata[31:24]);
       $fwrite(fp_fwd, "%c", m_axis_fft_tdata[23:16]);
       $fwrite(fp_fwd, "%c", m_axis_fft_tdata[15:8]);
       $fwrite(fp_fwd, "%c", m_axis_fft_tdata[7:0]);
    end
end

always @(posedge aclk) begin
    if (m_axis_ifft_tvalid) begin
        $fwrite(fp_inv, "%c", m_axis_ifft_tdata[31:24]);
        $fwrite(fp_inv, "%c", m_axis_ifft_tdata[23:16]);
        $fwrite(fp_inv, "%c", m_axis_ifft_tdata[15:8]);
        $fwrite(fp_inv, "%c", m_axis_ifft_tdata[7:0]);
    end
end


initial begin
$display("<-- Start simulation");
-> reset_start;
@(reset_done);

@(posedge aclk);
repeat(10)@(posedge aclk);

$display("<-- Configure FFT 2048 points (igual que el ARM)");

log2nFFT = clogb2(2048);
@(posedge aclk);
s_config_fft_tdata  = {3'b000, config_reg, FWD, log2nFFT};   // config_reg = 1706 = 0x6AA
@(posedge aclk);
s_config_fft_tvalid = 0;
@(posedge aclk);
s_config_fft_tvalid = 1;
@(posedge aclk);
s_config_fft_tvalid = 0;

$display("<-- Configure Inverse FFT 2048 points (sin escalamiento)");
@(posedge aclk);
s_config_ifft_tdata  = {3'b000, 12'd0, INV, log2nFFT};
@(posedge aclk);
s_config_ifft_tvalid = 0;
@(posedge aclk);
s_config_ifft_tvalid = 1;
@(posedge aclk);
s_config_ifft_tvalid = 0;

repeat(10)@(posedge aclk);
drive_xfft_square(2048, 64, 16000, 0);
@(posedge aclk);

// wait for master tlast
@(posedge m_axis_ifft_tlast);
repeat(1000)@(posedge aclk);



$display("<-- Simulation done !");
$fclose(fp_fwd);
$fclose(fp_inv);
$fclose(fp_input);
$finish;
end // initial begin


xfft_0 dut_0
(
    .aclk (aclk),
    .aresetn(aresetn),
	
	.s_axis_config_tdata(s_config_fft_tdata),
    .s_axis_config_tvalid(s_config_fft_tvalid),
    .s_axis_config_tready(s_config_fft_tready),
	
    
    .s_axis_data_tvalid(s_axis_xfft_tvalid),
    .s_axis_data_tdata(s_axis_xfft_tdata),
	.s_axis_data_tready(s_axis_xfft_tready),
	.s_axis_data_tlast(s_axis_xfft_tlast),
    
    .m_axis_data_tdata(m_axis_fft_tdata),
    .m_axis_data_tvalid(m_axis_fft_tvalid),
    .m_axis_data_tready(m_axis_fft_tready),
    .m_axis_data_tlast(m_axis_fft_tlast),
	
	.event_frame_started(),
    .event_tlast_unexpected(),
    .event_tlast_missing(),
    .event_status_channel_halt(),
    .event_data_in_channel_halt(),
    .event_data_out_channel_halt()
);

xfft_1 dut_1
(
    .aclk (aclk),
    .aresetn(aresetn),
	
	.s_axis_config_tdata(s_config_ifft_tdata),
    .s_axis_config_tvalid(s_config_ifft_tvalid),
    .s_axis_config_tready(s_config_ifft_tready),
	
    
    .s_axis_data_tvalid(m_axis_fft_tvalid),
    .s_axis_data_tdata(m_axis_fft_tdata),
	.s_axis_data_tready(m_axis_fft_tready),
	.s_axis_data_tlast(m_axis_fft_tlast),
    
    .m_axis_data_tdata(m_axis_ifft_tdata),
    .m_axis_data_tvalid(m_axis_ifft_tvalid),
    .m_axis_data_tready(1'b1),
    .m_axis_data_tlast(m_axis_ifft_tlast),
	
	.event_frame_started(),
    .event_tlast_unexpected(),
    .event_tlast_missing(),
    .event_status_channel_halt(),
    .event_data_in_channel_halt(),
    .event_data_out_channel_halt()
);

   

endmodule
