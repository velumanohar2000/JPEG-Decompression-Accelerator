`include "sys_defs.svh"

module block_buffer (
    input logic clk, rst,
    input logic signed [11:0] vli_value,
    input logic [3:0] run,
    input logic wr_en, freq,
    output logic [`BLOCK_BUFF_SIZE-1:0][11:0]data_out,
    output logic valid_out,
    output logic clear_n
);

logic [`BLOCK_BUFF_SIZE-1:0] [11:0] buffer, buffer_n;
logic [$clog2(`BLOCK_BUFF_SIZE+1)-1:0] head, head_n;
logic clear;

assign valid_out = clear;
assign data_out = buffer;

always_comb begin
    buffer_n = buffer;
    head_n = head;
    clear_n = 0;

    if (clear) begin
        buffer_n = 0;
    end

    if (wr_en) begin
        buffer_n[(head + run) % `BLOCK_BUFF_SIZE] = vli_value;
        head_n = (head + run + 1) % `BLOCK_BUFF_SIZE; 
        if ((!run && !vli_value) || (!head_n)) begin
            // guarantee AC freq (account for 0 DC value case)
            if (freq) begin
                clear_n = 1;
                head_n = 0;
            end
        end
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        buffer <= 0;
        head <= 0;
        clear <= 0;
    end else begin
        buffer <= buffer_n;
        head <= head_n;
        clear <= clear_n;
    end
end

endmodule
