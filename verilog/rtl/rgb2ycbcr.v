`include "define.vh"
module rgb2ycbcr (
    input clk, rstn,
    input unsigned [`RGB_N-1:0] r, g, b, // signed (N,R)=(16,7)
    input vld_i,
    output reg [7:0] y, cb, cr,      // unsigned 8 bits
    output reg vld_o
);

// Transformation Matrix LUT
wire unsigned [`TFORM_N-1:0] tform_lut [0:2][0:2];  // signed (N,R)=(15,14)
// R, G, B coefficient for Y 
assign tform_lut[0][0] = 4207;  // .2568
assign tform_lut[0][1] = 8260;  // .5041
assign tform_lut[0][2] = 1606;  // .0908
// R, G, B coefficient for Cb
assign tform_lut[1][0] = 2428;  // -.1482
assign tform_lut[1][1] = 4768;  // -.2910
assign tform_lut[1][2] = 7196;  // .4392
// R, G, B coefficient for Cr
assign tform_lut[2][0] = 7196; // .4392
assign tform_lut[2][1] = 6026; // -.3678
assign tform_lut[2][2] = 1170; // -.0714

wire [`TMP_N-1:0] y_tmp;      // (22,14)
wire [`TMP_N-1:0] cb_tmp;
wire [`TMP_N-1:0] cr_tmp;

wire [7:0] y_round;  // (8,0) all integer values
wire [7:0] cb_round;
wire [7:0] cr_round;

// Color Transformation in fixed point
assign y_tmp  =  22'd262144 + tform_lut[0][0] * r + tform_lut[0][1] * g + tform_lut[0][2] * b;
assign cb_tmp = 22'd2097152 - tform_lut[1][0] * r - tform_lut[1][1] * g + tform_lut[1][2] * b;
assign cr_tmp = 22'd2097152 + tform_lut[2][0] * r - tform_lut[2][1] * g - tform_lut[2][2] * b;

// Rounding & limt, determined by first fractional bit
assign y_round   =  y_tmp[13] && ( y_tmp[21:14]!=8'd255) ?  y_tmp[21:14] + 1 : y_tmp[21:14];
assign cb_round  = cb_tmp[13] && (cb_tmp[21:14]!=8'd255) ? cb_tmp[21:14] + 1 : cb_tmp[21:14];
assign cr_round  = cr_tmp[13] && (cr_tmp[21:14]!=8'd255) ? cr_tmp[21:14] + 1 : cr_tmp[21:14];

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