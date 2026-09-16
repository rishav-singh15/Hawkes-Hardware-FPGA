module exp_lut #(
    parameter ADDR_WIDTH = 12,  // 4096 entries to match the Q3.9 address
    parameter DATA_WIDTH = 32   // Q1.31 output
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr_in,
    output reg [DATA_WIDTH-1:0] exp_out
);
    reg [DATA_WIDTH-1:0] lut [0:(1<<ADDR_WIDTH)-1];

    // Iverilog looks for this file in the directory where you run the command
    initial begin
        $readmemh("exp_lut.mem", lut);
    end

    always @(posedge clk) begin
        exp_out <= lut[addr_in];
    end
endmodule