module dt_rom #(
    parameter ADDR_WIDTH = 10,  // 1024 entries for a 1000-event window
    parameter DATA_WIDTH = 32   // Q16.16
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] dt_out
);
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    initial begin
        $readmemh("dt.mem", mem);
    end

    always @(posedge clk) begin
        dt_out <= mem[addr];
    end
endmodule