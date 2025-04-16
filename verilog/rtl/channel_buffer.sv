`include "sys_defs.svh"

module channel_buffer (
    input logic clk, rst,
    input logic [`Q-1:0] blocks_in [3:0][7:0][7:0],
    input logic wr_en,
    input logic [$clog2(`CH+1)-1:0] ch,
    output logic [`Q-1:0] y_out [7:0][7:0],
    output logic [`Q-1:0] cb_out [7:0][7:0],
    output logic [`Q-1:0] cr_out [7:0][7:0],
    output logic valid_out
);

BLOCK y [3:0];
BLOCK y_n [3:0];
BLOCK cb [3:0]; 
BLOCK cb_n [3:0];
BLOCK cr [3:0];
BLOCK cr_n [3:0];

logic [1:0] tail; 
logic [1:0] tail_n;
logic [2:0] count;
logic [2:0] count_n;
logic [2:0] index;

always_comb 
begin
    count_n = count;
    tail_n = tail;
    valid_out = 0;

    for (int r = 0; r < 8; ++r) 
    begin
        for (int c = 0; c < 8; ++c) 
        begin
            y_out[r][c] = 0;
            cb_out[r][c] = 0;
            cr_out[r][c] = 0;
        end
    end
    
    for (int i = 0; i < 4; ++i) 
    begin
        for (int r = 0; r < 8; ++r) 
        begin
            for (int c = 0; c < 8; ++c) 
            begin
                y_n[i].block[r][c] = y[i].block[r][c];
                cb_n[i].block[r][c] = cb[i].block[r][c];
                cr_n[i].block[r][c] = cr[i].block[r][c];
            end
        end
    end

    if (wr_en) begin
        if (ch == 0) 
        begin
            for (int r = 0; r < 8; ++r) begin
                for (int c = 0; c < 8; ++c) begin
                    y_n[tail].block[r][c] = blocks_in[3][r][c];
                end
            end
            tail_n = tail + 1;
        end
        if (ch == 1)
        begin
            for (int i = 0; i < 4; ++i) begin
                for (int r = 0; r < 8; ++r) begin
                    for (int c = 0; c < 8; ++c) begin
                        cb_n[i].block[r][c] = blocks_in[i][r][c];
                    end
                end
            end
        end

        if (ch == 2)
        begin
            for (int i = 0; i < 4; ++i) begin
                for (int r = 0; r < 8; ++r) begin
                    for (int c = 0; c < 8; ++c) begin
                        cr_n[i].block[r][c] = blocks_in[i][r][c];
                        count_n = 4;
                    end
                end
            end
        end
    end

    if (count > 0) begin
        for (int r = 0; r < 8; ++r) begin
            for (int c = 0; c < 8; ++c) begin
                y_out[r][c] = y[4 - count].block[r][c];
                cb_out[r][c] = cb[4 - count].block[r][c];
                cr_out[r][c] = cr[4 - count].block[r][c];
            end
        end
        valid_out = 1;
        count_n = count - 1;
    end
end

always_ff @ (posedge clk) 
begin
    if (rst) 
    begin
        for (int i = 0; i < 4; ++i) 
        begin
            for (int r = 0; r < 8; ++r) 
            begin
                for (int c = 0; c < 8; ++c) 
                begin
                    y[i].block[r][c] <= 0;
                    cb[i].block[r][c] <= 0;
                    cr[i].block[r][c] <= 0;
                end
            end
        end
        count <= 0;
        tail <= 0;
    end 
    
    else 
    begin
        for (int i = 0; i < 4; ++i) 
        begin
            for (int r = 0; r < 8; ++r) 
            begin
                for (int c = 0; c < 8; ++c) 
                begin
                    y[i].block[r][c] <= y_n[i].block[r][c];
                    cb[i].block[r][c] <= cb_n[i].block[r][c];
                    cr[i].block[r][c] <= cr_n[i].block[r][c];
                end
            end
        end
        count <= count_n;
        tail <= tail_n;
    end
end

endmodule
