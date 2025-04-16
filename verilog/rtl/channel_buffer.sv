`include "sys_defs.svh"

module channel_buffer (
    input logic clk, rst,
    input logic signed [`Q-1:0] blocks_in [3:0][7:0][7:0],
    input logic wr_en,
    input logic [$clog2(`CH+1)-1:0] ch,
    output logic signed [`Q-1:0] y_out [7:0][7:0],
    output logic signed [`Q-1:0] cb_out [7:0][7:0],
    output logic signed [`Q-1:0] cr_out [7:0][7:0],
    output logic valid_out
);

BLOCK y_buff [3:0], y_buff_n [3:0];
BLOCK cb_buff [3:0], cb_buff_n [3:0];
BLOCK cr_buff [3:0], cr_buff_n [3:0];

logic [1:0] tail, tail_n; 
logic [2:0] count, count_n;

always_comb begin
    // default values
    tail_n = tail;
    count_n = count;
    valid_out = 0;
    for (int r = 0; r < 8; ++r) begin
        for (int c = 0; c < 8; ++c) begin
            y_out[r][c] = 0;
            cb_out[r][c] = 0;
            cr_out[r][c] = 0;
        end
    end
    for (int i = 0; i < 4; ++i) begin
        for (int r = 0; r < 8; ++r) begin
            for (int c = 0; c < 8; ++c) begin
                y_buff_n[i].block[r][c] = y_buff[i].block[r][c];
                cb_buff_n[i].block[r][c] = cb_buff[i].block[r][c];
                cr_buff_n[i].block[r][c] = cr_buff[i].block[r][c];
            end
        end
    end


    if (wr_en) begin
        case (ch)
        0: begin
            for (int r = 0; r < 8; ++r) begin
                for (int c = 0; c < 8; ++c) begin
                    y_buff_n[tail].block[r][c] = blocks_in[0][r][c];
                end
            end
            tail_n = tail + 1;
        end
        1: begin
            for (int i = 0; i < 4; ++i) begin
                for (int r = 0; r < 8; ++r) begin
                    for (int c = 0; c < 8; ++c) begin
                        cb_buff_n[i].block[r][c] = blocks_in[i][r][c];
                    end
                end
            end
        end
        2: begin
            for (int i = 0; i < 4; ++i) begin
                for (int r = 0; r < 8; ++r) begin
                    for (int c = 0; c < 8; ++c) begin
                        cr_buff_n[i].block[r][c] = blocks_in[i][r][c];
                        count_n = 4;
                    end
                end
            end
        end
        endcase
    end

    if (count > 0) begin
        for (int r = 0; r < 8; ++r) begin
            for (int c = 0; c < 8; ++c) begin
                y_out[r][c] = y_buff[4 - count].block[r][c];
                cb_out[r][c] = cb_buff[4 - count].block[r][c];
                cr_out[r][c] = cr_buff[4 - count].block[r][c];
            end
        end
        valid_out = 1;
        count_n = count - 1;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < 4; ++i) begin
            for (int r = 0; r < 8; ++r) begin
                for (int c = 0; c < 8; ++c) begin
                    y_buff[i].block[r][c] <= 0;
                    cb_buff[i].block[r][c] <= 0;
                    cr_buff[i].block[r][c] <= 0;
                end
            end
        end
        tail <= 0;
        count <= 0;
    end else begin
        for (int i = 0; i < 4; ++i) begin
            for (int r = 0; r < 8; ++r) begin
                for (int c = 0; c < 8; ++c) begin
                    y_buff[i].block[r][c] <= y_buff_n[i].block[r][c];
                    cb_buff[i].block[r][c] <= cb_buff_n[i].block[r][c];
                    cr_buff[i].block[r][c] <= cr_buff_n[i].block[r][c];
                end
            end
        end
        tail <= tail_n;
        count <= count_n;
    end
end

endmodule
