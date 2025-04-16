`include "sys_defs.svh"

module entropy_decoding (
    input logic clk, rst,
    input logic [`IN_BUS_WIDTH-1:0] data_in,
    input logic valid_in,
    input HUFF_PACKET huff_packet,

    output logic signed [11:0] block [7:0][7:0],
    output logic valid_out,
    output logic request,
    output logic [$clog2(`CH+1)-1:0] ch_out
);

logic [3:0] vli_size;
logic [4:0] huff_size;
logic [15:0] top_bits;
logic [10:0] vli_symbol;
logic ibuff_valid;
logic signed [11:0] vli_value, diff_value;
logic [3:0] run;
logic huff_valid; 
logic signed [`BLOCK_BUFF_SIZE-1:0][11:0] line;
logic freq;
logic clear_n;
logic [$clog2(`CH+1)-1:0] ch;



diff_decoder diff (
    clk,
    rst,
    vli_value,
    freq,
    ch,
    diff_value
);

block_buffer block_buff 
(
    clk, 
    rst,
    diff_value,
    run, 
    huff_valid,
    freq,
    line,
    valid_out,
    clear_n
);

unzigzag unzig (line, block);

input_buffer ibuff (
    clk, 
    rst,
    data_in, 
    huff_size,
    vli_size, 
    valid_in,
    1'b1,
    top_bits,
    vli_symbol,
    request,
    ibuff_valid
);

vli_decoder vli (vli_size, vli_symbol, vli_value);

huffman_decoder huff (
    huff_packet,
    top_bits,
    ibuff_valid,
    freq, 
    ch,
    run,
    vli_size,
    huff_size,
    huff_valid
);

logic start, start_n;
logic [3:0] ch_cnt, ch_cnt_n;
logic [5:0][$clog2(`CH+1)-1:0] ch_order = {
    2'd2, 2'd1, 2'd0, 2'd0, 2'd0, 2'd0
};

assign ch = ch_order[ch_cnt];
assign freq = !valid_out && start;
assign ch_cnt_n = (ch_cnt + clear_n) % 6;

always_comb begin
    if (!start) 
        start_n = ibuff_valid;
    else 
        start_n = start;
end

always_ff @(posedge clk) 
begin
    if (rst) 
    begin
        ch_cnt <= 0;
        ch_out <= 0;
        start <= 0;
    end 

    else 
    begin
        ch_cnt <= ch_cnt_n;
        ch_out <= ch;
        start <= start_n;
    end
end

endmodule

module diff_decoder (
    input  logic clk, rst,
    input  logic signed [11:0] value_in,
    input  logic freq,
    input  logic [$clog2(`CH+1)-1:0] ch,
    output logic signed [11:0] value_out
);

    logic signed [11:0] prev_value [`CH-1:0];
    logic signed [11:0] prev_value_n [`CH-1:0];

    // Determine next value_out and update for DC case
    assign value_out = freq ? value_in : value_in + prev_value[ch];

    // Update all channels (only change the one matching `ch`)
    genvar i;
    generate
        for (i = 0; i < `CH; ++i) begin : gen_prev
            assign prev_value_n[i] = (!freq && ch == i) ? value_out : prev_value[i];
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (rst)
            for (int i = 0; i < `CH; ++i)
                prev_value[i] <= '0;
        else
            for (int i = 0; i < `CH; ++i)
                prev_value[i] <= prev_value_n[i];
    end

endmodule

module block_buffer (
    input  logic clk,
    input  logic rst,
    input  logic signed [11:0] vli_value,
    input  logic [3:0] run,
    input  logic wr_en,
    input  logic freq,
    output logic [`BLOCK_BUFF_SIZE-1:0][11:0] data_out,
    output logic valid_out,
    output logic clear_n
);

    // Internal registers
    logic [`BLOCK_BUFF_SIZE-1:0][11:0] buffer_q, buffer_d;
    logic [$clog2(`BLOCK_BUFF_SIZE+1)-1:0] head_q, head_d, index;
    logic clear_q, clear_d;

    // Outputs
    assign data_out  = buffer_q;
    assign valid_out = clear_q;
    assign clear_n   = clear_d;

    always_comb begin
        buffer_d = buffer_q;
        head_d   = head_q;
        clear_d  = 1'b0;

        // Clear the buffer if requested
        if (clear_q) begin
            buffer_d = '0;
        end

        if (wr_en) begin
            // Insert value at the appropriate index
            index = (head_q + run) % `BLOCK_BUFF_SIZE;
            buffer_d[index] = vli_value;

            // Update head pointer
            head_d = (head_q + run + 1) % `BLOCK_BUFF_SIZE;

            // Check end-of-block condition
            if ((vli_value == 12'sd0 && run == 4'd0) || (head_d == 0)) begin
                if (freq) begin
                    clear_d = 1'b1;
                    head_d  = '0;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            buffer_q <= '0;
            head_q   <= '0;
            clear_q  <= 1'b0;
        end 
        
        else 
        begin
            buffer_q <= buffer_d;
            head_q   <= head_d;
            clear_q  <= clear_d;
        end
    end

endmodule

module unzigzag(
    input logic [`BLOCK_BUFF_SIZE-1:0][11:0] line,
    output logic signed [11:0] block [7:0][7:0]
);

logic [3:0] r_lut [0:63] = {
    4'd0, 4'd0, 4'd1, 4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd3, 
    4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd5, 4'd4, 
    4'd3, 4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 
    4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 
    4'd7, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd7, 4'd6, 
    4'd5, 4'd6, 4'd7, 4'd7
};

logic [3:0] c_lut [0:63] = {
    4'd0, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 4'd3, 4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 
    4'd2, 4'd3, 4'd4, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 
    4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd0, 
    4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 
    4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd7, 4'd6, 4'd5, 4'd4, 4'd5, 4'd6, 
    4'd7, 4'd7, 4'd6, 4'd7
};

always_comb begin
    for (int i = 0; i < 64; ++i) begin
        block[r_lut[i]][c_lut[i]] = line[i];
    end
end

endmodule

module vli_decoder (
    input  logic [3:0]  size,
    input  logic [10:0] symbol_in,
    output logic signed [11:0] value
);

logic signed [11:0] temp_symbol;

always_comb begin
    value = 12'sd0;

    if (size != 0) begin
        // Reverse the bits
        temp_symbol = 0;
        for (int i = 0; i < size; i++) begin
            temp_symbol[size - 1 - i] = symbol_in[i];
        end

        if (!temp_symbol[size - 1]) begin
            // Negative number: perform proper sign-extension of (symbol + 1), negate
            value = -((12'sd1 << size) - 1 - temp_symbol);
        end else begin
            // Positive number: just forward it
            value = temp_symbol;
        end
    end
end

endmodule

