// Parte PL: logica pura en la FPGA, sin intervencion del procesador.
// led[0] (LD2) parpadea a 1 Hz con un contador; led[1] (LD3) copia el switch SW0.
module pl_blink #(
    parameter integer CLK_HZ = 100_000_000
)(
    input  wire       clk,
    input  wire       sw,
    output wire [1:0] led
);
    localparam integer HALF = CLK_HZ / 2;
    reg [31:0] cnt = 0;
    reg        q   = 1'b0;
    always @(posedge clk) begin
        if (cnt == HALF - 1) begin
            cnt <= 0;
            q   <= ~q;
        end else begin
            cnt <= cnt + 1;
        end
    end
    assign led[0] = q;
    assign led[1] = sw;
endmodule
