`include "sys_defs.svh"

module deQuant (
    input logic signed [11:0] blockIn [7:0][7:0],
    input logic valid_in,
    input logic [$clog2(`CH+1)-1:0] ch,
    input QUANT_PACKET quant_packet,
    output logic signed [11:0] blockOut [7:0][7:0],
    output logic valid_out,
    output logic [$clog2(`CH+1)-1:0] chOut
);

QUANT_TABLE quant_table;

always_comb begin
    for (int r = 0; r < 8; ++r) begin
        for (int c = 0; c < 8; ++c) begin
            quant_table = quant_packet.tabs[quant_packet.map[ch]];
            blockOut[r][c] = blockIn[r][c] * quant_table.tab[r][c];
        end
    end
end

assign valid_out = valid_in;
assign chOut = ch;

endmodule