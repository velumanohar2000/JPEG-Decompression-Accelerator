`include "sys_defs.svh"

module huffman_decoder(
    input  HUFF_PACKET huff_packet,
    input  logic [15:0]     code,
    input logic             valid_in,
    input logic freq,
    input logic [$clog2(`CH+1)-1:0] ch,

    output logic [3:0]      run, vli_size, 
    output logic [4:0]      code_size,
    output logic            valid_out
);

logic signed [$clog2(`H)+1:0] index;
logic [`H:0][16:0] mask;

always_comb begin
    index = -1;
    mask = 0;
    if (valid_in) begin
        if (!freq) begin
            for (int i = 0; i < huff_packet.tabs[huff_packet.map[ch]].dc_size; ++i) begin
                for (int j = 0; j < huff_packet.tabs[huff_packet.map[ch]].dc_tab[i].size; ++j) begin
                    mask[i][j] = 1'b1;
                end
                if (huff_packet.tabs[huff_packet.map[ch]].dc_tab[i].code == (code & mask[i])) begin
                    index = i;
                end
            end
            run       = huff_packet.tabs[huff_packet.map[ch]].dc_tab[index].symbol[7:4];
            vli_size  = huff_packet.tabs[huff_packet.map[ch]].dc_tab[index].symbol[3:0];
            code_size = huff_packet.tabs[huff_packet.map[ch]].dc_tab[index].size;
        end else begin
            for (int i = 0; i < huff_packet.tabs[huff_packet.map[ch]].ac_size; ++i) begin
                for (int j = 0; j < huff_packet.tabs[huff_packet.map[ch]].ac_tab[i].size; ++j) begin
                    mask[i][j] = 1'b1;
                end
                if (huff_packet.tabs[huff_packet.map[ch]].ac_tab[i].code == (code & mask[i])) begin
                    index = i;
                end
            end
            run       = huff_packet.tabs[huff_packet.map[ch]].ac_tab[index].symbol[7:4];
            vli_size  = huff_packet.tabs[huff_packet.map[ch]].ac_tab[index].symbol[3:0];
            code_size = huff_packet.tabs[huff_packet.map[ch]].ac_tab[index].size;
        end
    end else begin
        run = 0;
        vli_size = 0;
        code_size = 0;
    end
    valid_out = index >= 0;
end

endmodule

