`include "sys_defs.svh"

module huffman_decoder (
    input  HUFF_PACKET huff_packet,
    input  logic [15:0] code,
    input  logic        valid_in,
    input  logic        freq,
    input  logic [$clog2(`CH+1)-1:0] ch,

    output logic [3:0]  run,
    output logic [3:0]  vli_size,
    output logic [4:0]  code_size,
    output logic        valid_out
);

logic signed [$clog2(`H)+1:0] index;
logic [`MAX_HUFF_CODE_WIDTH-1:0] mask;
int size;
int tab_size;

always_comb begin
    index     = -1;
    run       = 0;
    vli_size  = 0;
    code_size = 0;
    valid_out = 0;

    if (valid_in) begin
        // Choose AC or DC table size
        tab_size = (!freq)
            ? huff_packet.tabs[huff_packet.map[ch]].dc_size
            : huff_packet.tabs[huff_packet.map[ch]].ac_size;

        // Loop and match Huffman code
        for (int i = 0; i < tab_size; ++i) begin
            size = (!freq)
                ? huff_packet.tabs[huff_packet.map[ch]].dc_tab[i].size
                : huff_packet.tabs[huff_packet.map[ch]].ac_tab[i].size;

            mask = {`MAX_HUFF_CODE_WIDTH{1'b1}} >> (`MAX_HUFF_CODE_WIDTH - size);

            if (((!freq)
                 ? huff_packet.tabs[huff_packet.map[ch]].dc_tab[i].code
                 : huff_packet.tabs[huff_packet.map[ch]].ac_tab[i].code) == (code & mask)) begin
                index = i;
                break;
            end
        end

        if (index >= 0) begin
            run       = (!freq)
                ? huff_packet.tabs[huff_packet.map[ch]].dc_tab[index].symbol[7:4]
                : huff_packet.tabs[huff_packet.map[ch]].ac_tab[index].symbol[7:4];

            vli_size  = (!freq)
                ? huff_packet.tabs[huff_packet.map[ch]].dc_tab[index].symbol[3:0]
                : huff_packet.tabs[huff_packet.map[ch]].ac_tab[index].symbol[3:0];

            code_size = (!freq)
                ? huff_packet.tabs[huff_packet.map[ch]].dc_tab[index].size
                : huff_packet.tabs[huff_packet.map[ch]].ac_tab[index].size;

            valid_out = 1;
        end
    end
end

endmodule
