`include "define.vh"
module rgb2ycbcr_v2 (
    input clk, rstn,
    input unsigned [`RGB_N-1:0] r, g, b, // signed (N,R)=(16,7)
    input vld_i,
    output reg [7:0] y, cb, cr,      // unsigned 8 bits
    output reg vld_o
);

wire [14:0] y_tmp;      // (22,14)
wire [14:0] cb_tmp;
wire [14:0] cr_tmp;

wire [7:0] y_round;  // (8,0) all integer values
wire [7:0] cb_round;
wire [7:0] cr_round;

wire [14:0] y_tmp1, y_tmp2, y_tmp3;
wire [14:0] cb_tmp1, cb_tmp2, cb_tmp3;
wire [14:0] cr_tmp1, cr_tmp2, cr_tmp3;

assign y_tmp1 = ((r << 6) + (r << 1)) >> 8;
assign y_tmp2 = ((g << 7) + g) >> 8;
assign y_tmp3 = ((b << 4) + (b << 3) + b) >> 8;

assign cb_tmp1 = ((r << 5) + (r << 2) + (r << 1)) >> 8;
assign cb_tmp2 = ((g << 6) + (g << 3) + (g << 1)) >> 8;
assign cb_tmp3 = ((b << 7) - (b << 4)) >> 8;

assign cr_tmp1 = ((r << 7) - (r << 4)) >> 8;
assign cr_tmp2 = ((g << 6) + (g << 5)) >> 8;        // 64+32=96
assign cr_tmp3 = ((b << 4) + (b << 1)) >> 8;

// Color Transformation in fixed point
assign y_tmp  =  16 + y_tmp1 + y_tmp2 + y_tmp3;
assign cb_tmp = 128 - cb_tmp1 - cb_tmp2 + cb_tmp3;
assign cr_tmp = 128 + cr_tmp1 - cr_tmp2 - cr_tmp3;

// Rounding & limt, determined by first fractional bit
assign y_round   = |y_tmp[14:8] ? 8'd255 : y_tmp[7:0];
assign cb_round  = |cb_tmp[14:8] ? 8'd255 : cb_tmp[7:0];
assign cr_round  = |cr_tmp[14:8] ? 8'd255 : cr_tmp[7:0];

always @(posedge clk, negedge rstn) begin 
    if (!rstn) begin
        y <= 0;
        cb <= 0;
        cr <= 0;
        vld_o <= 0;
    end else begin
        if (vld_i) begin
            y  <= y_round;
            cb <= cb_round;
            cr <= cr_round;
            vld_o <= 1;
        end else begin
            y  <= 0;
            cb <= 0;
            cr <= 0;
            vld_o <= 0;
        end
    end
end

endmodule