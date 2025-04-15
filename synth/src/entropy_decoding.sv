`include "sys_defs.svh"

module entropy_decoding (
    input logic clk, rst,
    input logic [`IN_BUS_WIDTH-1:0] data_in, // from input mem
    input logic valid_in, // from input mem
    input HUFF_PACKET huff_packet, // from huff table (loaded in testbench)

    output logic signed [11:0] block [7:0][7:0], // to quant/IDCT
    output logic valid_out, // to quant/IDCT
    output logic request, // to input mem
    output logic [$clog2(`CH+1)-1:0] ch_out // To huff and dequant (sequential)
);

logic [3:0] vli_size;
logic [4:0] huff_size;
logic [15:0] top_bits;
logic [10:0] vli_symbol;
logic ibuff_valid;
logic signed [11:0] vli_value, diff_value;
logic [3:0] run;
logic huff_valid; 
logic signed [`BLOCK_BUFF_SIZE-1:0][11:0] line; // Output in line form
// logic freq, freq_n; // Frequency of current block: 0 for DC, 1 for AC
logic freq;
logic clear_n;
logic [$clog2(`CH+1)-1:0] ch; // (combinational)


input_buffer ibuff (
    // in
    clk, rst,
    data_in, // from input mem
    huff_size, // from huff
    vli_size, // from huff
    valid_in, // from input mem
    1'b1, // rd_en from ?
    // out
    top_bits, // to huff
    vli_symbol, // to VLI
    request, // to input mem
    ibuff_valid // to huff dec
);

vli_decoder vli (
    // in
    vli_size, // from huff
    vli_symbol, // from ibuff
    // out
    vli_value // to diff decoder
);

huffman_decoder huff (
    // in
    huff_packet, // from huff tab
    top_bits, // from ibuff
    ibuff_valid, // from ibuff
    freq, ch, // from entrop contr.
    // out
    run, // to pixel buff
    vli_size, // to vli and ibuff
    huff_size, // to ibuff
    huff_valid // to pixel buff
);

diff_decoder diff (
    // in
    clk, rst,
    vli_value, // from vli dec
    freq, // from entrop contr.
    ch, // from entrop contr.
    // out
    diff_value // to pixel buff
);

block_buffer block_buff (
    // in
    clk, rst,
    diff_value,  // from vli
    run, huff_valid, // from huff
    freq, // from entropy controller (this module)
    // out
    line,  // to unzig
    valid_out, // to output
    clear_n // to entrp conrt. (ch counter)
);

unzigzag unzig (
    // in
    line, // from block buff
    // out
    block // to output
);

// Assume ch1 ch1 ch1 ch1 ch2 ch3 interleaved block order
logic [3:0] ch_cnt, ch_cnt_n;
logic [5:0][$clog2(`CH+1)-1:0] ch_order = {
    2'd2, 2'd1, 2'd0, 2'd0, 2'd0, 2'd0
};

assign ch = ch_order[ch_cnt];

logic start, start_n;

assign freq = !valid_out && start;

always_comb begin
    //freq_n = !valid_out && start;
    //ch_cnt_n = (ch_cnt + (valid_out && start)) % 6; // assume ch1 (4x) ch2 ch3 order
    ch_cnt_n = (ch_cnt + clear_n) % 6; // assume ch1 (4x) ch2 ch3 order
    if (!start) start_n = ibuff_valid;
    else start_n = start;
end

always_ff @(posedge clk) begin
    if (rst) begin
        //freq <= 0;
        ch_cnt <= 0;
        ch_out <= 0;
        start <= 0;
    end else begin
        ch_cnt <= ch_cnt_n;
        ch_out <= ch;
        //freq <= freq_n;
        start <= start_n;
    end
end

endmodule



