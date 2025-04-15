`include "sys_defs.svh"

module ycbcr2rgb_block (
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic unsigned [7:0] y  [7:0][7:0],
    input  logic unsigned [7:0] cb [7:0][7:0],
    input  logic unsigned [7:0] cr [7:0][7:0],
    output logic unsigned [7:0] r  [7:0][7:0],
    output logic unsigned [7:0] g  [7:0][7:0],
    output logic unsigned [7:0] b  [7:0][7:0],
    output logic valid_out
);

logic [7:0] internal_valid_out [7:0];

// Signals to the rows of the y input block
logic unsigned [7:0] y_row0 [7:0];
logic unsigned [7:0] y_row1 [7:0];
logic unsigned [7:0] y_row2 [7:0];
logic unsigned [7:0] y_row3 [7:0];
logic unsigned [7:0] y_row4 [7:0];
logic unsigned [7:0] y_row5 [7:0];
logic unsigned [7:0] y_row6 [7:0];
logic unsigned [7:0] y_row7 [7:0];

// Signals to separate the rows of the cb input block
logic unsigned [7:0] cb_row0 [7:0];
logic unsigned [7:0] cb_row1 [7:0];
logic unsigned [7:0] cb_row2 [7:0];
logic unsigned [7:0] cb_row3 [7:0];
logic unsigned [7:0] cb_row4 [7:0];
logic unsigned [7:0] cb_row5 [7:0];
logic unsigned [7:0] cb_row6 [7:0];
logic unsigned [7:0] cb_row7 [7:0];

// Signals to separate the rows of the cr input block
logic unsigned [7:0] cr_row0 [7:0];
logic unsigned [7:0] cr_row1 [7:0];
logic unsigned [7:0] cr_row2 [7:0];
logic unsigned [7:0] cr_row3 [7:0];
logic unsigned [7:0] cr_row4 [7:0];
logic unsigned [7:0] cr_row5 [7:0];
logic unsigned [7:0] cr_row6 [7:0];
logic unsigned [7:0] cr_row7 [7:0];

// Signals for the rows of the r output block
logic unsigned [7:0] r_row0  [7:0];
logic unsigned [7:0] r_row1  [7:0];
logic unsigned [7:0] r_row2  [7:0];
logic unsigned [7:0] r_row3  [7:0];
logic unsigned [7:0] r_row4  [7:0];
logic unsigned [7:0] r_row5  [7:0];
logic unsigned [7:0] r_row6  [7:0];
logic unsigned [7:0] r_row7  [7:0];

// Signals for the rows of the g output block
logic unsigned [7:0] g_row0  [7:0];
logic unsigned [7:0] g_row1  [7:0];
logic unsigned [7:0] g_row2  [7:0];
logic unsigned [7:0] g_row3  [7:0];
logic unsigned [7:0] g_row4  [7:0];
logic unsigned [7:0] g_row5  [7:0];
logic unsigned [7:0] g_row6  [7:0];
logic unsigned [7:0] g_row7  [7:0];

// Signals for the rows of the b output block
logic unsigned [7:0] b_row0  [7:0];
logic unsigned [7:0] b_row1  [7:0];
logic unsigned [7:0] b_row2  [7:0];
logic unsigned [7:0] b_row3  [7:0];
logic unsigned [7:0] b_row4  [7:0];
logic unsigned [7:0] b_row5  [7:0];
logic unsigned [7:0] b_row6  [7:0];
logic unsigned [7:0] b_row7  [7:0];

// Get get rows of y block
assign y_row0 = y[0][7:0];
assign y_row1 = y[1][7:0];
assign y_row2 = y[2][7:0];
assign y_row3 = y[3][7:0];
assign y_row4 = y[4][7:0];
assign y_row5 = y[5][7:0];
assign y_row6 = y[6][7:0];
assign y_row7 = y[7][7:0];

// Get get rows of cb block
assign cb_row0 = cb[0][7:0];
assign cb_row1 = cb[1][7:0];
assign cb_row2 = cb[2][7:0];
assign cb_row3 = cb[3][7:0];
assign cb_row4 = cb[4][7:0];
assign cb_row5 = cb[5][7:0];
assign cb_row6 = cb[6][7:0];
assign cb_row7 = cb[7][7:0];

// Get get rows of cr block
assign cr_row0 = cr[0][7:0];
assign cr_row1 = cr[1][7:0];
assign cr_row2 = cr[2][7:0];
assign cr_row3 = cr[3][7:0];
assign cr_row4 = cr[4][7:0];
assign cr_row5 = cr[5][7:0];
assign cr_row6 = cr[6][7:0];
assign cr_row7 = cr[7][7:0];

// Convert row 0 of input flow to RGB
ycbcr2rgb ycbcr2rgb_row0 [7:0] (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .y(y_row0),
    .cb(cb_row0),
    .cr(cr_row0),
    .r(r_row0),
    .g(g_row0),
    .b(b_row0),
    .valid_out(internal_valid_out[0])
);

// Convert row 1 of input flow to RGB
ycbcr2rgb ycbcr2rgb_row1 [7:0] (

    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .y(y_row1),
    .cb(cb_row1),
    .cr(cr_row1),
    .r(r_row1),
    .g(g_row1),
    .b(b_row1),
    .valid_out(internal_valid_out[1])
);

// Convert row 2 of input flow to RGB
ycbcr2rgb ycbcr2rgb_row2 [7:0] (

    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .y(y_row2),
    .cb(cb_row2),
    .cr(cr_row2),
    .r(r_row2),
    .g(g_row2),
    .b(b_row2),
    .valid_out(internal_valid_out[2])
);

// Convert row 3 of input flow to RGB
ycbcr2rgb ycbcr2rgb_row3 [7:0] (

    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .y(y_row3),
    .cb(cb_row3),
    .cr(cr_row3),
    .r(r_row3),
    .g(g_row3),
    .b(b_row3),
    .valid_out(internal_valid_out[3])
);

// Convert row 4 of input flow to RGB
ycbcr2rgb ycbcr2rgb_row4 [7:0] (

    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .y(y_row4),
    .cb(cb_row4),
    .cr(cr_row4),
    .r(r_row4),
    .g(g_row4),
    .b(b_row4),
    .valid_out(internal_valid_out[4])
);

// Convert row 5 of input flow to RGB
ycbcr2rgb ycbcr2rgb_row5 [7:0] (

    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .y(y_row5),
    .cb(cb_row5),
    .cr(cr_row5),
    .r(r_row5),
    .g(g_row5),
    .b(b_row5),
    .valid_out(internal_valid_out[5])
);

// Convert row 6 of input flow to RGB
ycbcr2rgb ycbcr2rgb_row6 [7:0] (

    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .y(y_row6),
    .cb(cb_row6),
    .cr(cr_row6),
    .r(r_row6),
    .g(g_row6),
    .b(b_row6),
    .valid_out(internal_valid_out[6])
);

// Convert row 7 of input flow to RGB
ycbcr2rgb ycbcr2rgb_row7 [7:0] (

    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .y(y_row7),
    .cb(cb_row7),
    .cr(cr_row7),
    .r(r_row7),
    .g(g_row7),
    .b(b_row7),
    .valid_out(internal_valid_out[7])
);

// Assemble rows for the R output block
assign r[0][7:0] = r_row0;
assign r[1][7:0] = r_row1;
assign r[2][7:0] = r_row2;
assign r[3][7:0] = r_row3;
assign r[4][7:0] = r_row4;
assign r[5][7:0] = r_row5;
assign r[6][7:0] = r_row6;
assign r[7][7:0] = r_row7;

// Assemble rows for the G output block
assign g[0][7:0] = g_row0;
assign g[1][7:0] = g_row1;
assign g[2][7:0] = g_row2;
assign g[3][7:0] = g_row3;
assign g[4][7:0] = g_row4;
assign g[5][7:0] = g_row5;
assign g[6][7:0] = g_row6;
assign g[7][7:0] = g_row7;

// Assemble rows for the B output block
assign b[0][7:0] = b_row0;
assign b[1][7:0] = b_row1;
assign b[2][7:0] = b_row2;
assign b[3][7:0] = b_row3;
assign b[4][7:0] = b_row4;
assign b[5][7:0] = b_row5;
assign b[6][7:0] = b_row6;
assign b[7][7:0] = b_row7;

assign valid_out = (&internal_valid_out[0]) & 
                   (&internal_valid_out[1]) & 
                   (&internal_valid_out[2]) & 
                   (&internal_valid_out[3]) & 
                   (&internal_valid_out[4]) & 
                   (&internal_valid_out[5]) & 
                   (&internal_valid_out[6]) & 
                   (&internal_valid_out[7]) ;

endmodule