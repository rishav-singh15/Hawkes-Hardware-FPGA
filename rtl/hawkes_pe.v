module hawkes_pe(
    input wire clk,
    input wire window_reset,
    input wire tick_valid,
    input wire [31:0] dt,
    input wire [31:0] beta,
    input wire [31:0] mu,
    input wire [31:0] alpha,
    input wire [31:0] a_over_b,
    output reg signed [39:0] LL_acc,
    output reg tick_done
);

    reg [31:0] lambda_reg = 0;   
    reg [3:0] state = 0;
    
    // Pipeline Registers
    reg [63:0] beta_dt_mult;
    reg [11:0] exp_addr;
    wire [31:0] exp_val;
    wire [31:0] log_val;
    
    reg [31:0] B;
    reg [63:0] B_exp_mult;
    reg [31:0] lambda_pre;
    reg [31:0] penalty;
    reg signed [39:0] LL_update;

    // Instantiate LUTs
    exp_lut exp_unit (.clk(clk), .addr_in(exp_addr), .exp_out(exp_val));
    log_lut log_unit (.clk(clk), .addr_in(lambda_pre[27:16]), .log_out(log_val));

    always @(posedge clk) begin
        if (window_reset) begin
            lambda_reg <= mu;
            LL_acc <= 40'sd0;
            state <= 0;
            tick_done <= 0;
        end else if (tick_valid && state == 0) begin
            state <= 1;
            tick_done <= 0;
        end else begin
            case (state)
                1: begin
                    beta_dt_mult <= beta * dt;
                    state <= 2;
                end
                2: begin
                    // Address truncation fix: extract Q3.9 bits [46:35] with clamp
                    exp_addr <= (beta_dt_mult[63:47] > 0) ? 12'hFFF : beta_dt_mult[46:35];
                    B <= lambda_reg - mu + alpha;
                    state <= 3;
                end
                3: begin
                    // Wait for EXP LUT read
                    state <= 4;
                end
                4: begin
                    B_exp_mult <= B * exp_val;
                    state <= 5;
                end
                5: begin
                    lambda_reg <= mu + B_exp_mult[55:24];
                    lambda_pre <= (mu + B_exp_mult[55:24]) - alpha;
                    state <= 6;
                end
                6: begin
                    // Wait for LOG LUT read
                    penalty <= (mu * dt) >> 16;
                    state <= 7;
                end
                7: begin
                    LL_update <= $signed({8'b0, log_val}) - $signed({8'b0, penalty}) - $signed({8'b0, a_over_b});
                    state <= 8;
                end
                8: begin
                    LL_acc <= LL_acc + LL_update;
                    tick_done <= 1;
                    state <= 0;
                end
            endcase
        end
    end
endmodule