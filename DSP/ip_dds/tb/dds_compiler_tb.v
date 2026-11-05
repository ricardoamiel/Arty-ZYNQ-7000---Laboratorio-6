`timescale 1ns / 1ps

module dds_compiler_tb();

localparam      Nsamples = 4096;

reg             aresetn      = 0;
reg             aclk         = 0;

wire [31:0]     m_axis_phase_tdata;
wire            m_axis_phase_tvalid;
wire            m_axis_phase_tready;
wire            m_axis_phase_tlast;
wire            s_axis_none_tready;

wire [31:0]     i_phase_tdata;
wire            i_phase_tvalid;
wire            i_phase_tready;
wire            i_phase_tready;

wire [31:0]     m_axis_lut_tdata;
wire            m_axis_lut_tvalid;
wire            s_axis_lut_tready;
wire            m_axis_lut_tlast;

wire [31:0]     i_lut_tdata;
wire            i_lut_tvalid;
wire            i_lut_tready;
wire            i_lut_tlast;

integer         lut_en = 0;

`include "tb_util.vh"

assign          s_axis_phase_tready =  s_axis_none_tready & s_axis_lut_tready;



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
integer fp_phase, fp_lut, fp_input;

initial begin
    fp_phase = $fopen("../../../../../dds_phase_out.bin", "wb");
    if (!fp_phase) begin
        $display("Error: Could not open output file!");
        $finish;
    end

    fp_lut = $fopen("../../../../../dds_lut_out.bin", "wb");
    if (!fp_lut) begin
        $display("Error: Could not open output file!");
        $finish;
    end
    
    fp_input = $fopen("../../../../../dds_phase_in.bin", "wb");
    if (!fp_input) begin
        $display("Error: Could not open output file!");
        $finish;
    end

end


integer sample_count_phase = 0;
always @(posedge aclk) begin
    if (m_axis_phase_tvalid && (lut_en == 0) && (sample_count_phase < Nsamples)) begin
       // Write the 32-bit output sample as 4 bytes (big-endian order).
       $fwrite(fp_phase, "%c", m_axis_phase_tdata[31:24]);
       $fwrite(fp_phase, "%c", m_axis_phase_tdata[23:16]);
       $fwrite(fp_phase, "%c", m_axis_phase_tdata[15:8]);
       $fwrite(fp_phase, "%c", m_axis_phase_tdata[7:0]);
       sample_count_phase = sample_count_phase + 1;
       if (sample_count_phase == Nsamples) begin
           $fclose(fp_phase);
           $display("Wrote 2048 samples to fp_phase.");
       end
    end
end

integer sample_count_lut = 0;
always @(posedge aclk) begin
    if (m_axis_lut_tvalid && (lut_en == 1) && (sample_count_lut < Nsamples)) begin
       // Write the 32-bit output sample as 4 bytes (big-endian order).
       $fwrite(fp_lut, "%c", m_axis_lut_tdata[31:24]);
       $fwrite(fp_lut, "%c", m_axis_lut_tdata[23:16]);
       $fwrite(fp_lut, "%c", m_axis_lut_tdata[15:8]);
       $fwrite(fp_lut, "%c", m_axis_lut_tdata[7:0]);
       sample_count_lut = sample_count_lut + 1;
       if (sample_count_lut == Nsamples) begin
           $fclose(fp_lut);
           $display("Wrote 2048 samples to fp_lut.");
       end
    end
end

integer sample_count_lut_phase = 0;
always @(posedge aclk) begin
    if (s_axis_phase_tvalid && (lut_en == 1) && (sample_count_lut_phase < Nsamples)) begin
       $fwrite(fp_input, "%c", s_axis_phase_tdata[7:0]);
       $fwrite(fp_input, "%c", s_axis_phase_tdata[15:8]);
       sample_count_lut_phase = sample_count_lut_phase + 1;
       if (sample_count_lut_phase == Nsamples) begin
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
    
    drive_phase_sin(Nsamples + 100, 1.12345e6, 0, 0);
    repeat(1024) @(posedge aclk);
    
    lut_en = 1;
    
    drive_lut_sin(Nsamples + 100, 1.12345e6, 0, 0);
    repeat(1024) @(posedge aclk);

    $display("<-- Simulation done !");
    
    $finish;
end


dds_compiler_0 dut_0
(
    .aclk (aclk),
    .aresetn(aresetn),
    
    .s_axis_phase_tvalid(s_axis_phase_tvalid),
    .s_axis_phase_tready(s_axis_none_tready),
    .s_axis_phase_tdata(s_axis_phase_tdata),
    
    .m_axis_data_tvalid(i_phase_tvalid),
    .m_axis_data_tready(i_phase_tready),
    .m_axis_data_tdata(i_phase_tdata)
);


dds_compiler_1 dut_1
(
    .aclk (aclk),
    .aresetn(aresetn),
    
    .s_axis_phase_tvalid(s_axis_phase_tvalid),
    .s_axis_phase_tready(s_axis_lut_tready),
    .s_axis_phase_tdata(s_axis_phase_tdata),
    
    .m_axis_data_tvalid(i_lut_tvalid),
    .m_axis_data_tready(i_lut_tready),
    .m_axis_data_tdata(i_lut_tdata)
);

dds_axi_wrapper #(.FRAME_SIZE(Nsamples), .IDLE_CYCLES(32)) dut_2
  (
     .aclk(aclk),
     .aresetn(aresetn),
      
    .s_axis_tvalid(i_phase_tvalid),
    .s_axis_tready(i_phase_tready),
    .s_axis_tdata(i_phase_tdata),
    
    .m_axis_tvalid(m_axis_phase_tvalid),
    .m_axis_tready(1'b1),
    .m_axis_tdata(m_axis_phase_tdata),
    .m_axis_tlast(m_axis_phase_tlast)
    );
    
dds_axi_wrapper #(.FRAME_SIZE(Nsamples), .IDLE_CYCLES(32)) dut_3
  (
     .aclk(aclk),
     .aresetn(aresetn),
      
    .s_axis_tvalid(i_lut_tvalid),
    .s_axis_tready(i_lut_tready),
    .s_axis_tdata(i_lut_tdata),
    
    .m_axis_tvalid(m_axis_lut_tvalid),
    .m_axis_tready(1'b1),
    .m_axis_tdata(m_axis_lut_tdata),
    .m_axis_tlast(m_axis_lut_tlast)
    );




endmodule
