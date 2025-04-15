`include "sys_defs.svh"

module deQuant (
    input logic signed [11:0] blockIn [7:0][7:0], // from entropy decoder
    input logic valid_in, // from entropy decoder
    input logic [$clog2(`CH+1)-1:0] ch, //channel of the block from the entropy decoder (y,cb,cr)
    input QUANT_PACKET quant_packet, // from quant table (loaded in testbench)

    output logic signed [11:0] blockOut [7:0][7:0], // to quant/IDCT
    output logic valid_out, // to quant/IDCT
    output logic [$clog2(`CH+1)-1:0] chOut // To huff and dequant
);


always_comb begin
    //Multiply each element in the block with correct channel's quantization table element
    for (int r = 0; r < 8; ++r) begin
        for (int c = 0; c < 8; ++c) begin
            blockOut[r][c] = blockIn[r][c] * quant_packet.tabs[quant_packet.map[ch]].tab[r][c];
        end
    end
    //Pass valid and channel signals through
    valid_out = valid_in;
    chOut = ch;
end

endmodule