`timescale 1ns / 1ps



module fir_compiler_tb();

reg             aresetn      = 0;
reg             aclk         = 0;

wire [31:0]     m_axis_bpass_tdata;
wire            m_axis_bpass_tvalid;
wire            s_axis_bpass_tready;
wire            m_axis_bpass_tlast;

wire [31:0]     m_axis_hilb_tdata;
wire            m_axis_hilb_tvalid;
wire            s_axis_hilb_tready;
wire            m_axis_hilb_tlast;

wire [31:0]     m_axis_decim_tdata;
wire            m_axis_decim_tvalid;
wire            s_axis_decim_tready;
wire            m_axis_decim_tlast;

wire [31:0]     m_axis_inter_tdata;
wire            m_axis_inter_tvalid;
wire            s_axis_inter_tready;
wire            m_axis_inter_tlast;

`include "tb_util.vh"
// assign s_axis_tready = s_axis_bpass_tready & s_axis_hilb_tready;
assign s_axis_tready = s_axis_bpass_tready & s_axis_hilb_tready & s_axis_decim_tready;

wire [15:0]     x_re = m_axis_hilb_tdata[15: 0];
wire [15:0]     x_im = {m_axis_hilb_tdata[29:16], 2'b00};
wire [15:0]     decim_out = m_axis_decim_tdata[30:15];

reg  [31:0]     decim_data;





// Clock generation
always
    #(CLOCK_PERIOD/2) aclk = ~aclk;

// Reset sequence using events
event reset_start;
event reset_done;

initial begin
    aresetn = 1;
    @(reset_start);
    $display("<-- Reset");
    aresetn = 0;
    repeat(10) @(posedge aclk);
    aresetn = 1;
    -> reset_done;
    $display("<-- Reset done");
end

//---------------------------------------------------------
// File I/O: Write output samples to a binary file for analysis
//---------------------------------------------------------
integer fp_bpass, fp_hilb;
integer fp_dec, fp_int;
integer fp_input;

initial begin
    fp_bpass = $fopen("../../../../../fir_bpass_out.bin", "wb");
    if (!fp_bpass) begin
        $display("Error: Could not open output file!");
        $finish;
    end

    fp_hilb = $fopen("../../../../../fir_hilb_out.bin", "wb");
    if (!fp_hilb) begin
        $display("Error: Could not open output file!");
        $finish;
    end

    fp_dec = $fopen("../../../../../fir_decim_out.bin", "wb");
    if (!fp_dec) begin
        $display("Error: Could not open decimator output file!");
        $finish;
    end
    
    fp_int = $fopen("../../../../../fir_inter_out.bin", "wb");
    if (!fp_int) begin
        $display("Error: Could not open interpolator output file!");
        $finish;
    end

    fp_input = $fopen("../../../../../fir_input.bin", "wb");
    if (!fp_input) begin
        $display("Error: Could not open input data file!");
        $finish;
    end

end

always @(posedge aclk) begin
    if (s_axis_tvalid) begin
       // Write the 16-bit input sample as 2 bytes (big-endian order).
       $fwrite(fp_input, "%c", s_axis_tdata[15:8]);
       $fwrite(fp_input, "%c", s_axis_tdata[7:0]);
    end
end

// Capture and write DUT outputs whenever valid.
always @(posedge aclk) begin
    if (m_axis_bpass_tvalid) begin
       // Write the 32-bit output sample as 4 bytes (big-endian order).
       $fwrite(fp_bpass, "%c", m_axis_bpass_tdata[31:24]);
       $fwrite(fp_bpass, "%c", m_axis_bpass_tdata[23:16]);
       $fwrite(fp_bpass, "%c", m_axis_bpass_tdata[15:8]);
       $fwrite(fp_bpass, "%c", m_axis_bpass_tdata[7:0]);
    end
end

always @(posedge aclk) begin
    if (m_axis_hilb_tvalid) begin
        // Write x_re (16-bit) as two bytes
        $fwrite(fp_hilb, "%c", x_re[15:8]);
        $fwrite(fp_hilb, "%c", x_re[7:0]);
        // Write x_im (16-bit) as two bytes
        $fwrite(fp_hilb, "%c", x_im[15:8]);
        $fwrite(fp_hilb, "%c", x_im[7:0]);
    end
end

//----------------------------------------------------------
// Write Decimator Output to Binary File
// Writes the 32-bit decimator output sample as 4 bytes (big-endian)
//----------------------------------------------------------
always @(posedge aclk) begin
    if (m_axis_decim_tvalid) begin
       $fwrite(fp_dec, "%c", m_axis_decim_tdata[31:24]);
       $fwrite(fp_dec, "%c", m_axis_decim_tdata[23:16]);
       $fwrite(fp_dec, "%c", m_axis_decim_tdata[15:8]);
       $fwrite(fp_dec, "%c", m_axis_decim_tdata[7:0]);
       decim_data <= m_axis_decim_tdata;
    end
end

//----------------------------------------------------------
// Write Interpolator Output to Binary File
// Writes the 32-bit interpolator output sample as 4 bytes (big-endian)
//----------------------------------------------------------
always @(posedge aclk) begin
    if (m_axis_inter_tvalid) begin
       $fwrite(fp_int, "%c", m_axis_inter_tdata[31:24]);
       $fwrite(fp_int, "%c", m_axis_inter_tdata[23:16]);
       $fwrite(fp_int, "%c", m_axis_inter_tdata[15:8]);
       $fwrite(fp_int, "%c", m_axis_inter_tdata[7:0]);
    end
end


//---------------------------------------------------------
// Main simulation sequence: run several test signal frames
//---------------------------------------------------------
initial begin
    $display("<-- Start simulation");
    -> reset_start;
    @(reset_done);
    @(posedge aclk);
    
    // Delta Impulse Test
    // $display("<-- Starting Delta Impulse Test");
    // drive_delta(1024, 0);
    // repeat(100) @(posedge aclk);
    
    // Chirp Signal Test
    $display("<-- Starting Chirp Signal Test");
    // drive_chirp(1024, 0);
    repeat(100) @(posedge aclk);

    // Chirp Signal Test
    // $display("<-- Starting Sin Signal Test");
    // drive_sine(1024, 1.0e6, 0);
    // repeat(100) @(posedge aclk);
    
    // Random Noise Test
    // $display("<-- Starting Random Noise Test");
    drive_noise(1024, 1);
    repeat(100) @(posedge aclk);
    
    $display("<-- Simulation done !");
    $fclose(fp_bpass);
    $fclose(fp_hilb);
    $fclose(fp_dec);
    $fclose(fp_int);
    $fclose(fp_input);
    $finish;
end

//---------------------------------------------------------
// Instantiate the FIR IP Core (fir_bandpass)
//---------------------------------------------------------
fir_bandpass dut_0 (
    .aclk                (aclk),
    .aresetn             (aresetn),
    
    .s_axis_data_tvalid  (s_axis_tvalid),
    .s_axis_data_tdata   (s_axis_tdata),
    .s_axis_data_tready  (s_axis_bpass_tready),
    .s_axis_data_tlast   (s_axis_tlast),
    
    .m_axis_data_tvalid  (m_axis_bpass_tvalid),
    .m_axis_data_tready  (1'b1),
    .m_axis_data_tlast   (m_axis_bpass_tlast),
    .m_axis_data_tdata   (m_axis_bpass_tdata)
);

//-----------------------------
// DUT Instantiation: fir_hilbert
//-----------------------------
fir_hilbert dut_1 (
    .aclk               (aclk),
    .aresetn            (aresetn),
    .s_axis_data_tvalid (s_axis_tvalid),
    .s_axis_data_tdata  (s_axis_tdata),
    .s_axis_data_tready (s_axis_hilb_tready),
    .s_axis_data_tlast (s_axis_tlast),

    .m_axis_data_tvalid (m_axis_hilb_tvalid),
    .m_axis_data_tdata  (m_axis_hilb_tdata),
    .m_axis_data_tready (1'b1),
    .m_axis_data_tlast  (m_axis_hilb_tlast)
);

//-----------------------------
// DUT Instantiation: fir_decim
//-----------------------------
fir_decim dut_2 (
    .aclk               (aclk),
    .aresetn            (aresetn),
    .s_axis_data_tvalid (s_axis_tvalid),
    .s_axis_data_tdata  (s_axis_tdata),
    .s_axis_data_tready (s_axis_decim_tready),
    .s_axis_data_tlast  (s_axis_tlast),

    .m_axis_data_tvalid (m_axis_decim_tvalid),
    .m_axis_data_tready (1'b1),
    .m_axis_data_tlast  (m_axis_decim_tlast),
    .m_axis_data_tdata  (m_axis_decim_tdata)
);

//-----------------------------
// DUT Instantiation: fir_inter
//-----------------------------
fir_inter dut_3 (
    .aclk               (aclk),
    .aresetn            (aresetn),
    .s_axis_data_tvalid (m_axis_decim_tvalid),
    .s_axis_data_tdata  (m_axis_decim_tdata[30:15]),
    .s_axis_data_tready (s_axis_inter_tready),
    .s_axis_data_tlast  (m_axis_decim_tlast),


    .m_axis_data_tvalid (m_axis_inter_tvalid),
    .m_axis_data_tlast  (m_axis_inter_tlast),
    .m_axis_data_tready (1'b1),
    .m_axis_data_tdata  (m_axis_inter_tdata)
);


endmodule
