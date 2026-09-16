module log_lut #(
    parameter ADDR_WIDTH = 12,  // Q8.4 address
    parameter DATA_WIDTH = 32   // Q1.31 output
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr_in,
    output reg [DATA_WIDTH-1:0] log_out
);
    reg [DATA_WIDTH-1:0] lut [0:(1<<ADDR_WIDTH)-1];

    initial begin
        $readmemh("log_lut.mem", lut);
    end

    always @(posedge clk) begin
        log_out <= lut[addr_in];
    end
endmodule