module top_module(
    input wire clk,
    input wire rst_n,
    output wire [1:0] regime_out
);

    wire window_reset;
    wire tick_valid;
    wire [31:0] dt;
    
    // Engine Completion Flags
    wire tick_done_Q, tick_done_T, tick_done_C;
    
    // Log-Likelihood Scores
    wire signed [39:0] LL_Q, LL_T, LL_C;

    // ROM address counter controlled by tick_valid
    reg [9:0] rom_addr;
    always @(posedge clk) begin
        if (!rst_n) rom_addr <= 0;
        else if (tick_valid) rom_addr <= rom_addr + 1;
    end

    dt_rom dt_mem (
        .clk(clk),
        .addr(rom_addr),
        .dt_out(dt)
    );

    master_fsm fsm (
        .clk(clk),
        .tick_done_Q(tick_done_Q),
        .tick_done_T(tick_done_T),
        .tick_done_C(tick_done_C),
        .LL_Q(LL_Q),
        .LL_T(LL_T),
        .LL_C(LL_C),
        .tick_valid(tick_valid),
        .window_reset(window_reset),
        .regime_out(regime_out)
    );

    // Engine 1: Quiet
    hawkes_pe pe_quiet (
        .clk(clk), .window_reset(window_reset), .tick_valid(tick_valid), .dt(dt),
        .mu(32'h015CECEA),      
        .alpha(32'h001D7F0F),   
        .beta(32'h02591687),    
        .a_over_b(32'h00C8FF40),
        .LL_acc(LL_Q), .tick_done(tick_done_Q)
    );

    // Engine 2: Trending
    hawkes_pe pe_trending (
        .clk(clk), .window_reset(window_reset), .tick_valid(tick_valid), .dt(dt),
        .mu(32'h04349668),      
        .alpha(32'h000CFA05),   
        .beta(32'h018E5604),    
        .a_over_b(32'h00856F96),
        .LL_acc(LL_T), .tick_done(tick_done_T)
    );

    // Engine 3: Crash
    hawkes_pe pe_crash (
        .clk(clk), .window_reset(window_reset), .tick_valid(tick_valid), .dt(dt),
        .mu(32'h03F029F1),      
        .alpha(32'h00125AEE),   
        .beta(32'h01D7E671),    
        .a_over_b(32'h009F51CB),
        .LL_acc(LL_C), .tick_done(tick_done_C)
    );

endmodule