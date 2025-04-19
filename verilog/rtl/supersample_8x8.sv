`include "sys_defs.svh"
module supersample_8x8 (
    input  logic [$clog2(`CH+1)-1:0] ch,
    input  logic valid_in,
    input  logic [7:0] block_in [7:0][7:0],
    output logic [7:0] block_1_out [7:0][7:0],
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

    always_comb begin
        valid_out = 0;
        // Extract four 4x4 blocks from the 8x8 input
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                block_1[i][j] = block_in[i + 4][j + 4]; // Bottom-right
                block_2[i][j] = block_in[i + 4][j];     // Bottom-left
                block_3[i][j] = block_in[i][j + 4];     // Top-right
                block_4[i][j] = block_in[i][j];         // Top-left
            end
        end

        valid_out = {valid_4_out, valid_3_out, valid_2_out, valid_1_out};
    end

    supersample_4x4_bilinear u0 (
        .ch(ch),
        .valid_in(valid_in),
        .block_in(block_1),
        .block_out(block_1_out),
        .valid_out(valid_1_out)
    );

    supersample_4x4_bilinear u1 (
        .ch(ch),
        .valid_in(valid_in),
        .block_in(block_2),
        .block_out(block_2_out),
        .valid_out(valid_2_out)
    );

    supersample_4x4_bilinear u2 (
        .ch(ch),
        .valid_in(valid_in),
        .block_in(block_3),
        .block_out(block_3_out),
        .valid_out(valid_3_out)
    );

    supersample_4x4_bilinear u3 (
        .ch(ch),
        .valid_in(valid_in),
        .block_in(block_4),
        .block_out(block_4_out),
        .valid_out(valid_4_out)
    );

endmodule

// // 4x4 sub-block -> 8x8 block
// module supersample_4x4 (
//     input  logic [$clog2(`CH+1)-1:0] ch,                  
//     input  logic valid_in,
//     input  logic [7:0] block_in [3:0][3:0],
//     output logic [7:0] block_out [7:0][7:0],
//     output logic valid_out
// );

//     always_comb begin
//         // Default output
//         valid_out = 0;
//         for (int i = 0; i < 8; i++) begin
//             for (int j = 0; j < 8; j++) begin
//                 block_out[i][j] = 0;
//             end
//         end

//         if (valid_in && (ch == 2'b01 || ch == 2'b10)) begin
//             for (int i = 0; i < 4; i++) begin
//                 for (int j = 0; j < 4; j++) begin
//                     block_out[2*i][2*j]     = block_in[i][j];
//                     block_out[2*i][2*j+1]   = block_in[i][j];
//                     block_out[2*i+1][2*j]   = block_in[i][j];
//                     block_out[2*i+1][2*j+1] = block_in[i][j];
//                 end
//             end
//             valid_out = 1;
//         end
//     end

// endmodule
