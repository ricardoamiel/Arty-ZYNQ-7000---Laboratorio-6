module dds_axi_wrapper #(
  parameter FRAME_SIZE  = 2048,
  parameter IDLE_CYCLES = 32,
  parameter D_WIDTH  = 32
)(
  input  wire         aclk,
  input  wire         aresetn,
  // Input from DDS compiler (no TLAST)
  input  wire         s_axis_tvalid,
  output wire         s_axis_tready,
  input  wire [D_WIDTH-1:0]  s_axis_tdata,
  // Output to AXI DMA (with TLAST)
  output reg          m_axis_tvalid,
  input  wire         m_axis_tready,
  output reg [D_WIDTH-1:0]   m_axis_tdata,
  output reg          m_axis_tlast
);

  // Two states: NORMAL (data passing) and IDLE (dropping extra words)
  localparam NORMAL = 1'b0, IDLE = 1'b1;
  reg state;
  reg [15:0] count;         // counts words in current frame
  reg [15:0] idle_counter;  // counts idle cycles

  // When in NORMAL state, we pass data if the downstream is ready.
  // When in IDLE, we do not accept new input.
  assign s_axis_tready = (state == NORMAL) ? m_axis_tready : 1'b0;

  always @(posedge aclk) begin
    if (!aresetn) begin
      state         <= NORMAL;
      count         <= 0;
      idle_counter  <= 0;
      m_axis_tvalid <= 0;
      m_axis_tlast  <= 0;
      m_axis_tdata  <= 32'd0;
    end else begin
      case (state)
        NORMAL: begin
          if (s_axis_tvalid && m_axis_tready) begin
            m_axis_tdata  <= s_axis_tdata;
            m_axis_tvalid <= 1;
            // If we reached the last word of the frame, assert TLAST and switch to IDLE.
            if (count == FRAME_SIZE - 1) begin
              m_axis_tlast <= 1;
              state        <= IDLE;
              idle_counter <= 0;
            end else begin
              m_axis_tlast <= 0;
              count <= count + 1;
            end
          end else if (m_axis_tready) begin
            m_axis_tvalid <= 0;
          end
        end

        IDLE: begin
          // Remain idle for a fixed number of clock cycles
          m_axis_tvalid <= 0;
          m_axis_tlast  <= 0;
          if (idle_counter < IDLE_CYCLES - 1)
            idle_counter <= idle_counter + 1;
          else begin
            idle_counter <= 0;
            count <= 0;
            state <= NORMAL;
          end
        end

        default: state <= NORMAL;
      endcase
    end
  end

endmodule
