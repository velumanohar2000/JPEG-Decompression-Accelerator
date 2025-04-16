module sup_buf_ycbcr2rgb (
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [$clog2(`CH+1)-1:0] ch_in,     // 0=Y, 1=Cb, 2=Cr
    input  logic [7:0] block_in [7:0][7:0],
    output logic unsigned [7:0] r [7:0][7:0],
    output logic unsigned [7:0] g [7:0][7:0],
    output logic unsigned [7:0] b [7:0][7:0],
    output logic valid_out
);

logic [7:0] block_1_out [7:0][7:0];
logic [7:0] block_2_out [7:0][7:0];
logic [7:0] block_3_out [7:0][7:0];
logic [7:0] block_4_out [7:0][7:0];
logic [$clog2(`CH+1)-1:0] ch_out;
logic [3:0] valid_1;
logic valid_2;

logic [`Q-1:0] blocks_in [3:0][7:0][7:0];

assign blocks_in[0] = block_1_out;
assign blocks_in[1] = block_2_out;
assign blocks_in[2] = block_3_out;
assign blocks_in[3] = block_4_out;

logic [7:0]  y_out [7:0][7:0];
logic [7:0] cb_out [7:0][7:0];
logic [7:0] cr_out [7:0][7:0];

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
    .valid_out(valid_1)   // 4 bits
);

channel_buffer_copy buffer (
    .clk(clk),
    .rst(rst),
    .blocks_in(blocks_in),
    .wr_en(valid_1[0]),
    .ch(ch_out),
    .y_out(y_out),
    .cb_out(cb_out),
    .cr_out(cr_out),
    .valid_out(valid_2)
);

ycbcr2rgb_block color_conversion (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_2),
    .y(y_out),
    .cb(cb_out),
    .cr(cr_out),
    .r(r),
    .g(g),
    .b(b),
    .valid_out(valid_out)
);

endmodule