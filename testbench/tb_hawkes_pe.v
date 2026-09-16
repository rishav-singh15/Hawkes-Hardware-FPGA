`timescale 1ns / 1ps

module tb_hawkes_pe();
    reg clk;
    reg window_reset;
    reg tick_valid;
    reg [31:0] dt;
    reg [31:0] mu;
    reg [31:0] alpha;
    reg [31:0] beta;
    reg [31:0] a_over_b;
    
    wire signed [39:0] LL_acc;
    wire tick_done;

    hawkes_pe uut (
        .clk(clk),
        .window_reset(window_reset),
        .tick_valid(tick_valid),
        .dt(dt),
        .beta(beta),
        .mu(mu),
        .alpha(alpha),
        .a_over_b(a_over_b),
        .LL_acc(LL_acc),
        .tick_done(tick_done)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_hawkes_pe.vcd");
        $dumpvars(0, tb_hawkes_pe);

        window_reset = 1;
        tick_valid = 0;
        // Sample parameters
        mu = 32'h015C_0000;      // Q8.24
        alpha = 32'h001D_0000;   // Q8.24
        beta = 32'h0258_0000;    // Q4.28
        a_over_b = 32'h00CC_0000;// Q8.24
        dt = 32'h0000_8000;      // Q16.16 (0.5 seconds)

        #20 window_reset = 0;
        
        // Fire event 1
        #10 tick_valid = 1;
        #10 tick_valid = 0;
        
        wait(tick_done);
        
        // Fire event 2
        #50 tick_valid = 1;
        #10 tick_valid = 0;

        wait(tick_done);
        #100 $finish;
    end
endmodule