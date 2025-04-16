`include "sys_defs.svh"
module ycbcr2rgb (
    input  logic clk,
    input  logic rst,
    input  logic [7:0] y, cb, cr, // signed (N,R)=(16,7)
    input  logic valid_in,
    output logic [7:0] r, g, b,   // unsigned 8 bits
    output logic valid_out
);

logic signed [16:0] r_tmp;      // (22,14)
logic signed [16:0] g_tmp;
logic signed [16:0] b_tmp;

logic [7:0] r_round;  // (8,0) all integer values
logic [7:0] g_round;
logic [7:0] b_round;

logic signed [16:0] r_tmp1, r_tmp3;
logic signed [16:0] g_tmp1, g_tmp2, g_tmp3;
logic signed [16:0] b_tmp1, b_tmp2; 

assign r_tmp1 = ((y << 8) + (y << 5) + (y << 3) + (y << 1)) >> 8;  // 256+32+8+2 = 298
assign r_tmp3 = ((cr << 8) + (cr << 7) + (cr << 4) + (cr << 3)) >> 8; // 256+128+16+8 = 408

assign g_tmp1 = ((y << 8) + (y << 5) + (y << 3) + (y << 1)) >> 8; 
assign g_tmp2 = ((cb << 6) + (cb << 5) + (cb << 2)) >> 8;   // 64+32+4=100
assign g_tmp3 = ((cr << 7) + (cr << 6) + (cr << 4)) >> 8; // 128+64+16=208

assign b_tmp1 = ((y << 8) + (y << 5) + (y << 3) + (y << 1)) >> 8; // 298
assign b_tmp2 = ((cb << 9) + (cb << 2)) >> 8; // 512+4=516

// Color Transformation
assign r_tmp  = r_tmp1 + r_tmp3 - 223;
assign g_tmp  = g_tmp1 - g_tmp2 - g_tmp3 + 136;
assign b_tmp  = b_tmp1 + b_tmp2 - 277;

// Set max value to 255
// assign r_round  = |r_tmp[16:8] ? 8'd255 : r_tmp[7:0];
// assign g_round  = |g_tmp[16:8] ? 8'd255 : g_tmp[7:0];
// assign b_round  = |b_tmp[16:8] ? 8'd255 : b_tmp[7:0];

always_comb begin
    if (r_tmp > 255) r_round = 255;
    else if (r_tmp < 0) r_round = 0;
    else r_round = r_tmp;
    if (g_tmp > 255) g_round = 255;
    else if (g_tmp < 0) g_round = 0;
    else g_round = g_tmp;
    if (b_tmp > 255) b_round = 255;
    else if (b_tmp < 0) b_round = 0;
    else b_round = b_tmp;
end

always @(posedge clk) begin 
    if (rst) begin
        r <= 0;
        g <= 0;
        b <= 0;
        valid_out <= 0;
    end else begin
        if (valid_in) begin
            r <= r_round;
            g <= g_round;
            b <= b_round;
            valid_out <= 1;
        end else begin
            r <= 0;
            g <= 0;
            b <= 0;
            valid_out <= 0;
        end
    end
end

endmodule