`include "sys_defs.svh"

module top (
    //Inputs
    input logic clk, rst,
    input logic [`IN_BUS_WIDTH-1:0] data_in,
    input logic valid_in,
    input HUFF_PACKET hp,
    input QUANT_PACKET qp,
    //Outputs
    output logic request,
    output logic unsigned [7:0] r [7:0][7:0],
    output logic unsigned [7:0] g [7:0][7:0],
    output logic unsigned [7:0] b [7:0][7:0],
    output logic valid_out_Color
);

//Internal connections
logic signed [11:0] blockOut_Entropy [7:0][7:0];
logic valid_out_Entropy;
logic [$clog2(`CH+1)-1:0] ch_Entropy;

//Block instances
entropy_decoding deHuffer(
    // in
    .clk(clk), .rst(rst),
    .data_in(data_in), .valid_in(valid_in),
    .huff_packet(hp),
    // out
    .block(blockOut_Entropy), 
    .valid_out(valid_out_Entropy),
    .request(request),
    .ch_out(ch_Entropy)
);

logic signed [11:0] blockOut_Quant [7:0][7:0];
logic valid_out_Quant;
logic [$clog2(`CH+1)-1:0] ch_Quant;

deQuant deQuantizer (
    // in
    .blockIn(blockOut_Entropy), .valid_in(valid_out_Entropy), .ch(ch_Entropy), .quant_packet(qp),
    // out
    .blockOut(blockOut_Quant), .valid_out(valid_out_Quant), .chOut(ch_Quant)
);

logic unsigned [7:0] idct_out [7:0][7:0];
logic [$clog2(`CH+1)-1:0] ch_Idct;
logic valid_out_Idct;

loeffler2d_idct idct(
    //in
    .clk(clk), .rst(rst), .valid_in(valid_out_Quant), .channel_in(ch_Quant), .idct_in(blockOut_Quant),
    //out
    .idct_out(idct_out), .channel_out(ch_Idct), .valid_out(valid_out_Idct)
);

logic [7:0] block_1_out [7:0][7:0];
logic [7:0] block_2_out [7:0][7:0];
logic [7:0] block_3_out [7:0][7:0];
logic [7:0] block_4_out [7:0][7:0];
logic [$clog2(`CH+1)-1:0] ch_out_Super;
logic [3:0] valid_out_Super;

logic [`Q-1:0] blocks_in [3:0][7:0][7:0];

assign blocks_in[0] = block_4_out;
assign blocks_in[1] = block_3_out;
assign blocks_in[2] = block_2_out;
assign blocks_in[3] = block_1_out;

supersample_top supersampling (
    //in
    .clk(clk),
    .rst(rst),
    .valid_in(valid_out_Idct),
    .ch_in(ch_Idct),
    .block_in(idct_out),
    //out
    .block_1_out(block_1_out),
    .block_2_out(block_2_out),
    .block_3_out(block_3_out),
    .block_4_out(block_4_out),
    .ch_out(ch_out_Super),
    .valid_out(valid_out_Super)   // 4 bits
);

logic [`Q-1:0] y_out [7:0][7:0];
logic [`Q-1:0] cb_out [7:0][7:0];
logic [`Q-1:0] cr_out [7:0][7:0];
logic valid_out_Buffer;

channel_buffer_copy buffer (
    //in
    .clk(clk),
    .rst(rst),
    .blocks_in(blocks_in),
    .wr_en(valid_out_Super[0]),
    .ch(ch_out_Super),
    //out
    .y_out(y_out),
    .cb_out(cb_out),
    .cr_out(cr_out),
    .valid_out(valid_out_Buffer)
);

ycbcr2rgb_block color_conversion (
    //in
    .clk(clk),
    .rst(rst),
    .valid_in(valid_out_Buffer),
    .y(y_out),
    .cb(cb_out),
    .cr(cr_out),
    //out
    .r(r),
    .g(g),
    .b(b),
    .valid_out(valid_out_Color)
);

// assign r = y_out;
// assign g = cb_out;
// assign b = cr_out;
// assign valid_out_Color = valid_out_Buffer;


endmodule