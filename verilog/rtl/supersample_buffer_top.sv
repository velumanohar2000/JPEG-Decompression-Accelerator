`include "sys_defs.svh"
module supersample_buffer_top (
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [$clog2(`CH+1)-1:0] ch_in,     // 0=Y, 1=Cb, 2=Cr
    input  logic [7:0] block_in [7:0][7:0],
    output logic [`Q-1:0] y_out [7:0][7:0],
    output logic [`Q-1:0] cb_out [7:0][7:0],
    output logic [`Q-1:0] cr_out [7:0][7:0],
    output logic valid_out
);

logic [7:0] block_1_out [7:0][7:0];
logic [7:0] block_2_out [7:0][7:0];
logic [7:0] block_3_out [7:0][7:0];
logic [7:0] block_4_out [7:0][7:0];
logic [$clog2(`CH+1)-1:0] ch_out;
logic [3:0] valid;

logic [`Q-1:0] blocks_in [3:0][7:0][7:0];

assign blocks_in[0] = block_1_out;
assign blocks_in[1] = block_2_out;
assign blocks_in[2] = block_3_out;
assign blocks_in[3] = block_4_out;

supersample_top supersampling (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .ch_in(ch_in),
    .block_in(block_in),
    .block_1_out(block_1_out),
    .block_2_out(block_2_out),
    .block_3_out(block_3_out),
    .block_4_out(block_4_out),
    .ch_out(ch_out),
    .valid_out(valid)   // 4 bits
);

channel_buffer_copy buffer (
    .clk(clk),
    .rst(rst),
    .blocks_in(blocks_in),
    .wr_en(valid[0]),
    .ch(ch_out),
    .y_out(y_out),
    .cb_out(cb_out),
    .cr_out(cr_out),
    .valid_out(valid_out)
);


endmodule