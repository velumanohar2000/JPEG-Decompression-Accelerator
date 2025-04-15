`include "sys_defs.svh"

// For Cb, Cr block
// 4x4 sub-block -> 8x8 block
module supersample_4x4 (
    input  logic [$clog2(`CH+1)-1:0] ch,      // Cb: 2'b01, Cr: 2'b10
    input  logic valid_in,
    input  logic [7:0] block_in [3:0][3:0],       // input: 4x4 block
    output logic [7:0] block_out [7:0][7:0],     // output: 8x8 block
    output logic valid_out
);

logic [7:0] block [7:0][7:0];
logic valid;
int row_offset, col_offset;

assign block_out = block;
assign valid_out = valid;

always_comb begin
    // Initialize block to zero by default
    for (int i = 0; i < 8; i++) begin
        for (int j = 0; j < 8; j++) begin
            block[i][j] = 0;
        end
    end
    valid = 0;

    if (valid_in && (ch == 2'b01 || ch == 2'b10)) begin
        block[7][7] = block_in[3][3];
        block[7][6] = block_in[3][3];
        block[6][7] = block_in[3][3];
        block[6][6] = block_in[3][3];

        block[7][5] = block_in[3][2];
        block[7][4] = block_in[3][2];
        block[6][5] = block_in[3][2];
        block[6][4] = block_in[3][2];

        block[7][3] = block_in[3][1];
        block[7][2] = block_in[3][1];
        block[6][3] = block_in[3][1];
        block[6][2] = block_in[3][1];

        block[7][1] = block_in[3][0];
        block[7][0] = block_in[3][0];
        block[6][1] = block_in[3][0];
        block[6][0] = block_in[3][0];

        //
        block[5][7] = block_in[2][3];
        block[5][6] = block_in[2][3];
        block[4][7] = block_in[2][3];
        block[4][6] = block_in[2][3];

        block[5][5] = block_in[2][2];
        block[5][4] = block_in[2][2];
        block[4][5] = block_in[2][2];
        block[4][4] = block_in[2][2];

        block[5][3] = block_in[2][1];
        block[5][2] = block_in[2][1];
        block[4][3] = block_in[2][1];
        block[4][2] = block_in[2][1];

        block[5][1] = block_in[2][0];
        block[5][0] = block_in[2][0];
        block[4][1] = block_in[2][0];
        block[4][0] = block_in[2][0];

        //
        block[3][7] = block_in[1][3];
        block[3][6] = block_in[1][3];
        block[2][7] = block_in[1][3];
        block[2][6] = block_in[1][3];

        block[3][5] = block_in[1][2];
        block[3][4] = block_in[1][2];
        block[2][5] = block_in[1][2];
        block[2][4] = block_in[1][2];

        block[3][3] = block_in[1][1];
        block[3][2] = block_in[1][1];
        block[2][3] = block_in[1][1];
        block[2][2] = block_in[1][1];

        block[3][1] = block_in[1][0];
        block[3][0] = block_in[1][0];
        block[2][1] = block_in[1][0];
        block[2][0] = block_in[1][0];

        //
        block[1][7] = block_in[0][3];
        block[1][6] = block_in[0][3];
        block[0][7] = block_in[0][3];
        block[0][6] = block_in[0][3];

        block[1][5] = block_in[0][2];
        block[1][4] = block_in[0][2];
        block[0][5] = block_in[0][2];
        block[0][4] = block_in[0][2];

        block[1][3] = block_in[0][1];
        block[1][2] = block_in[0][1];
        block[0][3] = block_in[0][1];
        block[0][2] = block_in[0][1];

        block[1][1] = block_in[0][0];
        block[1][0] = block_in[0][0];
        block[0][1] = block_in[0][0];
        block[0][0] = block_in[0][0];

        valid = 1;
    end
end

endmodule