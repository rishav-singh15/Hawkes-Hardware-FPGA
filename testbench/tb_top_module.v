`timescale 1ns / 1ps

module tb_top_module();
    reg clk;
    reg rst_n;
    wire [1:0] regime_out;

    // Instantiate Top Module
    top_module uut (
        .clk(clk),
        .rst_n(rst_n),
        .regime_out(regime_out)
    );

    // 100 MHz Clock Generation (10 ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // File I/O for Python Visualization
    integer outfile;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top_module);

        outfile = $fopen("../data/sim_results.csv", "w");
        $fdisplay(outfile, "Time,LL_Q,LL_T,LL_C,Regime");

        rst_n = 0;
        #20;
        rst_n = 1;

        // Increased to 300,000 ns to capture over 3,000 events
        #300000;
        
        $display("Simulation finished.");
        $display("1. Open dump.vcd in Surfer.");
        $display("2. Run python scripts on data/sim_results.csv");
        $fclose(outfile);
        $finish;
    end

    // Log the data continuously every time the engines finish a tick!
    always @(posedge clk) begin
        if (uut.tick_done_Q && rst_n) begin
            $fdisplay(outfile, "%0t,%d,%d,%d,%b", 
                      $time, uut.LL_Q, uut.LL_T, uut.LL_C, regime_out);
        end
    end
endmodule