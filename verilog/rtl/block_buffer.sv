`include "sys_defs.svh"

module block_buffer (
    input  logic clk,
    input  logic rst,
    input  logic signed [11:0] vli_value,
    input  logic [3:0] run,
    input  logic wr_en,
    input  logic freq,
    output logic [`BLOCK_BUFF_SIZE-1:0][11:0] data_out,
    output logic valid_out,
    output logic clear_n
);

    // Internal registers
    logic [`BLOCK_BUFF_SIZE-1:0][11:0] buffer_q, buffer_d;
    logic [$clog2(`BLOCK_BUFF_SIZE+1)-1:0] head_q, head_d, index;
    logic clear_q, clear_d;

    // Outputs
    assign data_out  = buffer_q;
    assign valid_out = clear_q;
    assign clear_n   = clear_d;

    // Combinational logic
    always_comb begin
        buffer_d = buffer_q;
        head_d   = head_q;
        clear_d  = 1'b0;

        // Clear the buffer if requested
        if (clear_q) begin
            buffer_d = '0;
        end

        if (wr_en) begin
            // Insert value at the appropriate index
            index = (head_q + run) % `BLOCK_BUFF_SIZE;
            buffer_d[index] = vli_value;

            // Update head pointer
            head_d = (head_q + run + 1) % `BLOCK_BUFF_SIZE;

            // Check end-of-block condition
            if ((vli_value == 12'sd0 && run == 4'd0) || (head_d == 0)) begin
                if (freq) begin
                    clear_d = 1'b1;
                    head_d  = '0;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            buffer_q <= '0;
            head_q   <= '0;
            clear_q  <= 1'b0;
        end 
        
        else 
        begin
            buffer_q <= buffer_d;
            head_q   <= head_d;
            clear_q  <= clear_d;
        end
    end

endmodule
