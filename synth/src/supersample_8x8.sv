`include "sys_defs.svh"

module supersample_8x8 (
    input  logic [$clog2(`CH+1)-1:0] ch,      // Cb: 2'b01, Cr: 2'b10
    input  logic valid_in,
    input  logic [7:0] block_in [7:0][7:0],       // input: 4x4 block
    output logic [7:0] block_1_out [7:0][7:0],     // output: 8x8 block
    output logic [7:0] block_2_out [7:0][7:0],
    output logic [7:0] block_3_out [7:0][7:0],
    output logic [7:0] block_4_out [7:0][7:0],
    output logic [3:0] valid_out
);

    logic [7:0] block_1 [3:0][3:0];
    logic [7:0] block_2 [3:0][3:0];
    logic [7:0] block_3 [3:0][3:0];
    logic [7:0] block_4 [3:0][3:0];

    logic valid_1_out, valid_2_out, valid_3_out, valid_4_out;

    /*
    BLOCK 1 | BLOCK 2
    ------------------
    BLOCK 3 | BLOCK 4
    */

    /* Dividing a block into four sub-blocks */
    always_comb begin 
        // Initialize block to zero by default
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                block_1[i][j] = 0;
                block_2[i][j] = 0;
                block_3[i][j] = 0;
                block_4[i][j] = 0;
            end
        end
        valid_out = 0;

        if (valid_in && (ch == 2'b01 || ch == 2'b10)) begin
            // BLOCK 1
            block_1[3][3] = block_in[7][7];
            block_1[3][2] = block_in[7][6];
            block_1[3][1] = block_in[7][5];
            block_1[3][0] = block_in[7][4];

            block_1[2][3] = block_in[6][7];
            block_1[2][2] = block_in[6][6];
            block_1[2][1] = block_in[6][5];
            block_1[2][0] = block_in[6][4];

            block_1[1][3] = block_in[5][7];
            block_1[1][2] = block_in[5][6];
            block_1[1][1] = block_in[5][5];
            block_1[1][0] = block_in[5][4];

            block_1[0][3] = block_in[4][7];
            block_1[0][2] = block_in[4][6];
            block_1[0][1] = block_in[4][5];
            block_1[0][0] = block_in[4][4];

            // BLOCK 2
            block_2[3][3] = block_in[7][3];
            block_2[3][2] = block_in[7][2];
            block_2[3][1] = block_in[7][1];
            block_2[3][0] = block_in[7][0];

            block_2[2][3] = block_in[6][3];
            block_2[2][2] = block_in[6][2];
            block_2[2][1] = block_in[6][1];
            block_2[2][0] = block_in[6][0];

            block_2[1][3] = block_in[5][3];
            block_2[1][2] = block_in[5][2];
            block_2[1][1] = block_in[5][1];
            block_2[1][0] = block_in[5][0];

            block_2[0][3] = block_in[4][3];
            block_2[0][2] = block_in[4][2];
            block_2[0][1] = block_in[4][1];
            block_2[0][0] = block_in[4][0]; 

            // BLOCK 3
            block_3[3][3] = block_in[3][7];
            block_3[3][2] = block_in[3][6];
            block_3[3][1] = block_in[3][5];
            block_3[3][0] = block_in[3][4];

            block_3[2][3] = block_in[2][7];
            block_3[2][2] = block_in[2][6];
            block_3[2][1] = block_in[2][5];
            block_3[2][0] = block_in[2][4];

            block_3[1][3] = block_in[1][7];
            block_3[1][2] = block_in[1][6];
            block_3[1][1] = block_in[1][5];
            block_3[1][0] = block_in[1][4];

            block_3[0][3] = block_in[0][7];
            block_3[0][2] = block_in[0][6];
            block_3[0][1] = block_in[0][5];
            block_3[0][0] = block_in[0][4];

            // BLOCK 4
            block_4[3][3] = block_in[3][3];
            block_4[3][2] = block_in[3][2];
            block_4[3][1] = block_in[3][1];
            block_4[3][0] = block_in[3][0];

            block_4[2][3] = block_in[2][3];
            block_4[2][2] = block_in[2][2];
            block_4[2][1] = block_in[2][1];
            block_4[2][0] = block_in[2][0];

            block_4[1][3] = block_in[1][3];
            block_4[1][2] = block_in[1][2];
            block_4[1][1] = block_in[1][1];
            block_4[1][0] = block_in[1][0];

            block_4[0][3] = block_in[0][3];
            block_4[0][2] = block_in[0][2];
            block_4[0][1] = block_in[0][1];
            block_4[0][0] = block_in[0][0];

            valid_out[0] = valid_1_out;
            valid_out[1] = valid_2_out;
            valid_out[2] = valid_3_out;
            valid_out[3] = valid_4_out;
        end
    end

    // Block 1 supersample
    supersample_4x4 u0 (
        .ch(ch),
        .valid_in(valid_in),
        .block_in(block_1),
        .block_out(block_1_out),
        .valid_out(valid_1_out)
    );

    // Block 2 supersample
    supersample_4x4 u1 (
        .ch(ch),
        .valid_in(valid_in),
        .block_in(block_2),
        .block_out(block_2_out),
        .valid_out(valid_2_out)
    );

    // Block 3 supersample
    supersample_4x4 u2 (
        .ch(ch),
        .valid_in(valid_in),
        .block_in(block_3),
        .block_out(block_3_out),
        .valid_out(valid_3_out)
    );

    // Block 4 supersample
    supersample_4x4 u3 (
        .ch(ch),
        .valid_in(valid_in),
        .block_in(block_4),
        .block_out(block_4_out),
        .valid_out(valid_4_out)
    );

endmodule