`include "sys_defs.svh"

module jpeg_decoder_top (
    input  logic clk,
    input  logic rst,
    input  logic [`IN_BUS_WIDTH-1:0] data_in,
    input  logic valid_in,
    input  HUFF_PACKET hp,
    input  QUANT_PACKET qp,

    output logic request,
    output logic [7:0] r [7:0][7:0],
    output logic [7:0] g [7:0][7:0],
    output logic [7:0] b [7:0][7:0],
    output logic valid_out_Color
);

    // -----------------------------
    // Entropy Decoding → Dequantization
    // -----------------------------
    logic signed [11:0] block_entropy [7:0][7:0];
    logic valid_entropy;
    logic [$clog2(`CH+1)-1:0] ch_entropy;

    logic signed [11:0] block_dequant [7:0][7:0];
    logic valid_dequant;
    logic [$clog2(`CH+1)-1:0] ch_dequant;

    // -----------------------------
    // IDCT Output
    // -----------------------------
    logic [7:0] idct_out [7:0][7:0];
    logic valid_idct;
    logic [$clog2(`CH+1)-1:0] ch_idct;

    // -----------------------------
    // Supersample Output (4 blocks)
    // -----------------------------
    logic [7:0] block1 [7:0][7:0];
    logic [7:0] block2 [7:0][7:0];
    logic [7:0] block3 [7:0][7:0];
    logic [7:0] block4 [7:0][7:0];
    logic [3:0] valid_super;
    logic [$clog2(`CH+1)-1:0] ch_super;

    // -----------------------------
    // Channel Buffer Output
    // -----------------------------
    logic [`Q-1:0] blocks_in [3:0][7:0][7:0];
    logic [`Q-1:0] y [7:0][7:0];
    logic [`Q-1:0] cb [7:0][7:0];
    logic [`Q-1:0] cr [7:0][7:0];
    logic valid_buffer;

    // Block ordering (JPEG block scan order)
    assign blocks_in[0] = block4;
    assign blocks_in[1] = block3;
    assign blocks_in[2] = block2;
    assign blocks_in[3] = block1;

    // -----------------------------
    // Module Instances
    // -----------------------------

    // Entropy Decoding
    entropy_decoding deHuffer (
        .clk(clk), .rst(rst),
        .data_in(data_in),
        .valid_in(valid_in),
        .huff_packet(hp),

        .block(block_entropy),
        .valid_out(valid_entropy),
        .request(request),
        .ch_out(ch_entropy)
    );

    // Dequantization
    deQuant deQuantizer (
        .blockIn(block_entropy),
        .valid_in(valid_entropy),
        .ch(ch_entropy),
        .quant_packet(qp),

        .blockOut(block_dequant),
        .valid_out(valid_dequant),
        .chOut(ch_dequant)
    );

    // 2D IDCT
    loeffler2d_idct idct (
        .clk(clk), .rst(rst),
        .valid_in(valid_dequant),
        .channel_in(ch_dequant),
        .idct_in(block_dequant),

        .idct_out(idct_out),
        .channel_out(ch_idct),
        .valid_out(valid_idct)
    );

    // Supersampling
    supersample supersampling (
        .clk(clk), .rst(rst),
        .valid_in(valid_idct),
        .ch_in(ch_idct),
        .block_in(idct_out),

        .block_1_out(block1),
        .block_2_out(block2),
        .block_3_out(block3),
        .block_4_out(block4),
        .ch_out(ch_super),
        .valid_out(valid_super)
    );

    // Channel Buffering
    channel_buffer buffer (
        .clk(clk), .rst(rst),
        .blocks_in(blocks_in),
        .wr_en(valid_super[0]), // use only first valid bit
        .ch(ch_super),

        .y_out(y),
        .cb_out(cb),
        .cr_out(cr),
        .valid_out(valid_buffer)
    );

    // Final Color Conversion
    YCbCr_to_RGB_8x8 color_conversion (
        .clk(clk), .rst(rst),
        .valid_in(valid_buffer),
        .y(y),
        .cb(cb),
        .cr(cr),
        .r(r),
        .g(g),
        .b(b),
        .valid_out(valid_out_Color)
    );

endmodule
