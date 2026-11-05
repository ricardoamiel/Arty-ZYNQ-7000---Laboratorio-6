`timescale 1ns / 1ps

module cic_compiler_tb();

reg             aresetn      = 0;
reg             aclk         = 0;

wire [15:0]     m_axis_inter_tdata;
wire            m_axis_inter_tvalid;
wire            s_axis_inter_tready;

wire [15:0]     m_axis_decim_tdata;
wire            m_axis_decim_tvalid;
wire            s_axis_decim_tready;

`include "tb_util.vh"

assign          s_axis_tready = s_axis_decim_tready; //s_axis_decim_tready & s_axis_inter_tready;



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
integer fp_decim, fp_inter, fp_input;

initial begin
    fp_decim = $fopen("../../../../../cic_decim_out.bin", "wb");
    if (!fp_decim) begin
        $display("Error: Could not open output file!");
        $finish;
    end

    fp_inter = $fopen("../../../../../cic_inter_out.bin", "wb");
    if (!fp_inter) begin
        $display("Error: Could not open output file!");
        $finish;
    end

    fp_input = $fopen("../../../../../cic_input.bin", "wb");
    if (!fp_input) begin
        $display("Error: Could not open input file!");
        $finish;
    end
end


integer sample_count_decim = 0;
always @(posedge aclk) begin
    if (m_axis_decim_tvalid && (sample_count_decim < 128)) begin
       $fwrite(fp_decim, "%c", m_axis_decim_tdata[15:8]);
       $fwrite(fp_decim, "%c", m_axis_decim_tdata[7:0]);
       sample_count_decim = sample_count_decim + 1;
       if (sample_count_decim == 128) begin
           $fclose(fp_decim);
           $display("Wrote 128 samples to fp_decim.");
       end
    end
end

integer sample_count_inter = 0;
always @(posedge aclk) begin
    if (m_axis_inter_tvalid && (sample_count_inter < 2048)) begin
       $fwrite(fp_inter, "%c", m_axis_inter_tdata[15:8]);
       $fwrite(fp_inter, "%c", m_axis_inter_tdata[7:0]);
       sample_count_inter = sample_count_inter + 1;
       if (sample_count_inter == 2048) begin
           $fclose(fp_inter);
           $display("Wrote 2048 samples to fp_inter.");
       end
    end
end

integer sample_count_input = 0;
always @(posedge aclk) begin
    if (s_axis_tvalid && (sample_count_input < 2048)) begin
       $fwrite(fp_input, "%c", s_axis_tdata[15:8]);
       $fwrite(fp_input, "%c", s_axis_tdata[7:0]);
       sample_count_input = sample_count_input + 1;
       if (sample_count_input == 2048) begin
           $fclose(fp_input);
           $display("Wrote 2048 samples to fp_input.");
       end
    end
end



//---------------------------------------------------------
// Main simulation sequence: run several test signal frames
//---------------------------------------------------------
initial begin
    $display("<-- Start simulation");

    -> reset_start;
    @(reset_done);
    repeat(128) @(posedge aclk);
    
    // Chirp Signal Test
    $display("<-- Starting Sin Signal Test");
    // drive_sine(4096, 1.0e6, 0);
    drive_chirp(1024, 0);
    repeat(100) @(posedge aclk);

    $display("<-- Simulation done !");
    
    $finish;
end


cic_decim dut_0
(
    .aclk (aclk),
    .aresetn(aresetn),
    
    .s_axis_data_tvalid(s_axis_tvalid),
    .s_axis_data_tdata(s_axis_tdata),
	.s_axis_data_tready(s_axis_decim_tready),
    
    .m_axis_data_tvalid(m_axis_decim_tvalid),
    .m_axis_data_tdata(m_axis_decim_tdata)
);

cic_inter dut_1
(
    .aclk (aclk),
    .aresetn(aresetn),
    
    .s_axis_data_tvalid(m_axis_decim_tvalid),
    .s_axis_data_tdata(m_axis_decim_tdata),
	.s_axis_data_tready(s_axis_inter_tready), // just avoid
    
    .m_axis_data_tvalid(m_axis_inter_tvalid),
    .m_axis_data_tdata(m_axis_inter_tdata)
); 



endmodule
