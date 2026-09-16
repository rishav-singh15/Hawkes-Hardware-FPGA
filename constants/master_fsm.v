module master_fsm(
    input wire clk,
    input wire tick_done_Q,
    input wire tick_done_T,
    input wire tick_done_C,
    input wire signed [39:0] LL_Q,
    input wire signed [39:0] LL_T,
    input wire signed [39:0] LL_C,
    output reg tick_valid,
    output reg window_reset,
    output reg [1:0] regime_out // 01: Quiet, 10: Trending, 11: Crash
);

    reg [9:0] window_counter = 0;
    reg [2:0] state = 0;

    always @(posedge clk) begin
        case (state)
            0: begin // INIT / RESET
                window_reset <= 1;
                tick_valid <= 0;
                window_counter <= 0;
                state <= 1;
            end
            1: begin // FIRE CORES
                window_reset <= 0;
                tick_valid <= 1;
                state <= 2;
            end
            2: begin // WAIT CORES
                tick_valid <= 0;
                if (tick_done_Q && tick_done_T && tick_done_C) begin
                    if (window_counter == 999) state <= 3;
                    else begin
                        window_counter <= window_counter + 1;
                        state <= 1;
                    end
                end
            end
            3: begin // MLE EVAL
                if (LL_C > LL_T && LL_C > LL_Q) regime_out <= 2'b11;
                else if (LL_T > LL_Q) regime_out <= 2'b10;
                else regime_out <= 2'b01;
                
                state <= 0; // Trigger reset for next window
            end
        endcase
    end
endmodule