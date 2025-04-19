`include "sys_defs.svh"
module supersample_4x4_bilinear (
    input  logic [$clog2(`CH+1)-1:0] ch,
    input  logic valid_in,
    input  logic [7:0] block_in [3:0][3:0],      // 4x4 input
    output logic [7:0] block_out [7:0][7:0],     // 8x8 output
    output logic valid_out
);

    logic valid;

    assign valid_out = valid;

    integer src_i, src_j;
    integer i1, j1, dx, dy;

    logic [7:0] A;
    logic [7:0] B;
    logic [7:0] C;
    logic [7:0] D;

    logic [9:0] R1, R2, P;

    always_comb begin
        valid = 0;
        A = '{default: '0};
        B = '{default: '0};
        C = '{default: '0};
        D = '{default: '0};

        R1 = '{default: '0};
        R2 = '{default: '0};
        P  = '{default: '0};

        if (valid_in && (ch == 2'b01 || ch == 2'b10)) begin
            for (int i = 0; i < 8; i++) begin
                for (int j = 0; j < 8; j++) begin
                    src_i = i >> 1;
                    src_j = j >> 1;

                    // boundary clamp
                    i1 = (src_i < 3) ? src_i + 1 : src_i;
                    j1 = (src_j < 3) ? src_j + 1 : src_j;

                    // fetch pixels A B C D
                    A = block_in[src_i][src_j];
                    B = block_in[src_i][j1];
                    C = block_in[i1][src_j];
                    D = block_in[i1][j1];

                    // dy, dx : 0 (even) or 1 (odd)
                    dy = i % 2;
                    dx = j % 2;

                    if (dx == 0)
                        R1 = A;
                    else
                        R1 = (A + B) >> 1;

                    if (dx == 0)
                        R2 = C;
                    else
                        R2 = (C + D) >> 1;

                    if (dy == 0)
                        P = R1;
                    else
                        P = (R1 + R2) >> 1;

                    block_out[i][j] = P[7:0];
                end
            end
            valid = 1;
        end
    end

endmodule
