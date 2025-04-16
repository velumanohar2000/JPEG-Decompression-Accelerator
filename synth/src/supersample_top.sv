`include "sys_defs.svh"

module supersample_top (
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [$clog2(`CH+1)-1:0] ch_in,     // 0=Y, 1=Cb, 2=Cr
    input  logic [7:0] block_in [7:0][7:0],
    output logic [7:0] block_1_out [7:0][7:0],
    output logic [7:0] block_2_out [7:0][7:0],
    output logic [7:0] block_3_out [7:0][7:0],
    output logic [7:0] block_4_out [7:0][7:0],
    output logic [$clog2(`CH+1)-1:0] ch_out,
    output logic [3:0] valid_out
);

logic [7:0] block_1 [7:0][7:0];
logic [7:0] block_2 [7:0][7:0];
logic [7:0] block_3 [7:0][7:0];
logic [7:0] block_4 [7:0][7:0];

logic [7:0] sup_block_1 [7:0][7:0];
logic [7:0] sup_block_2 [7:0][7:0];
logic [7:0] sup_block_3 [7:0][7:0];
logic [7:0] sup_block_4 [7:0][7:0];

logic [3:0] valid;
logic [3:0] sup_valid;
logic [$clog2(`CH+1)-1:0] ch;

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < 8; i = i + 1) begin
            for (int j = 0; j < 8; j = j + 1) begin
                block_1_out[i][j] <= 0; 
                block_2_out[i][j] <= 0; 
                block_3_out[i][j] <= 0; 
                block_4_out[i][j] <= 0;
            end
        end
        valid_out <= 0;
        ch_out <= 0;
    end else begin
        if (valid_in) begin
            block_1_out <= block_1;
            block_2_out <= block_2;
            block_3_out <= block_3;
            block_4_out <= block_4;
            valid_out <= valid;
            ch_out <= ch;
        end 
        else begin
            valid_out <= 0;
        end
    end
end

always_comb begin
    // Initialize block to zero by default
    for (int i = 0; i < 8; i = i + 1) begin
        for (int j = 0; j < 8; j = j + 1) begin
            block_1[i][j] = 0;
            block_2[i][j] = 0;
            block_3[i][j] = 0;
            block_4[i][j] = 0;
        end
    end

    valid = 0;
    ch = 0;

    /* Y channel */
    if (ch_in == 2'b00) begin
        for (int i = 0; i < 8; i = i + 1) begin
            for (int j = 0; j < 8; j = j + 1) begin
                block_1[i][j] = block_in[i][j];
                block_2[i][j] = 0;
                block_3[i][j] = 0;
                block_4[i][j] = 0;
            end
        end
        valid = 4'b0001;
        ch = ch_in;
    end 

    /* Cb, Cr channel*/
    else if (ch_in == 2'b01 || ch_in == 2'b10) begin  
        for (int i = 0; i < 8; i = i + 1) begin
            for (int j = 0; j < 8; j = j + 1) begin
                block_1[i][j] = sup_block_1[i][j];
                block_2[i][j] = sup_block_2[i][j];
                block_3[i][j] = sup_block_3[i][j];
                block_4[i][j] = sup_block_4[i][j];
            end
        end
        valid = sup_valid;
        ch = ch_in;
    end
end

supersample_8x8 u0 (
    .ch(ch_in),
    .valid_in(valid_in),
    .block_in(block_in),
    .block_1_out(sup_block_1),
    .block_2_out(sup_block_2),
    .block_3_out(sup_block_3),
    .block_4_out(sup_block_4),
    .valid_out(sup_valid)
);

endmodule