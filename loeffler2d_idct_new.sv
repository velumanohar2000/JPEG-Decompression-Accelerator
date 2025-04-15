
`include "sys_defs.svh"

`define FIFO_SIZE 524288

module loeffler2d_idct_new (
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [$clog2(`CH+1)-1:0] channel_in,
    input  logic signed [11:0] idct_in [7:0][7:0],  // Full 8x8 block input
    output logic unsigned [7:0] idct_out [7:0][7:0], // Full 8x8 block output
    output logic [$clog2(`CH+1)-1:0] channel_out,
    output logic valid_out
);

    typedef struct {
        logic signed [11:0] data [7:0][7:0];
        logic [$clog2(`CH+1)-1:0] channel;
    } idct_block_t;
    
    idct_block_t input_fifo [`FIFO_SIZE-1:0];
    logic [63:0] fifo_head, fifo_tail;
    logic [63:0] fifo_count;

    // FSM state encoding
    enum logic [2:0] {IDLE, PROCESS_ROWS, PROCESS_COLS, DONE, LOAD} state, next_state;

    // Internal buffers and signals
    logic signed [63:0] idct_in_extended [7:0][7:0];
    logic signed [63:0] row_idct_input [7:0];
    logic signed [63:0] col_idct_input [7:0];
    logic signed [63:0] row_idct_output [7:0];
    logic signed [63:0] col_idct_output [7:0];

    logic [3:0] valid_row_out_cnt;
    logic [3:0] valid_col_out_cnt;

    // Memories to store intermediate results for transposition
    logic signed [63:0] mem_rows [7:0][7:0];
    logic signed [63:0] mem_cols [7:0][7:0];

    // Normalization signals
    logic signed [63:0] idct_out_normalized [7:0][7:0];
    logic signed [63:0] idct_out_norm_before_transpose [7:0][7:0];
    logic [1:0] internal_channel;
    logic [1:0] channel_reg;

    logic valid_row_out;
    logic valid_col_out;

    logic [3:0] col_input_cnt;
    logic [3:0] row_input_cnt;


   // Next state and normalization logic (combinational)
    always_comb begin
        next_state = state; // default assignment
        case (state)
            IDLE: begin
                if (fifo_count > 0) begin
                    // for (int row = 0; row < 8; row++) begin
                    //     for (int col = 0; col < 8; col++) begin
                    //         idct_in_extended[row][col] = input_fifo[fifo_head].data[row][col];
                    //     end
                    // end
                    next_state = LOAD;
                end else begin
                    next_state = IDLE;
                end
            end
            LOAD: next_state = PROCESS_ROWS;
            PROCESS_ROWS: begin
                // If we have captured all 8 rows, proceed to process columns.
                if (valid_row_out_cnt == 'd7)
                    next_state = PROCESS_COLS;
                else begin
                    // Set row_idct_input using the current row index.
                    if (row_input_cnt < 'd8)
                        row_idct_input = idct_in_extended[row_input_cnt];
                    next_state = PROCESS_ROWS;
                end
            end
            PROCESS_COLS: begin
                // If we have captured all 8 columns, proceed to DONE state.
                if (valid_col_out_cnt == 'd7)
                    next_state = DONE;
                else begin
                    // Set col_idct_input using stored intermediate results.
                    if (col_input_cnt < 'd8)
                        col_idct_input = mem_rows[col_input_cnt];
                    next_state = PROCESS_COLS;
                end
            end
            DONE: begin
                // Perform normalization for the full block.
                for (int row = 0; row < 8; row++) begin
                    for (int col = 0; col < 8; col++) begin
                        // Normalize: shift right by 3 (divide by 8) and add 128.
                        idct_out_normalized[row][col] = (mem_cols[row][col] >>> 3) + 128;
                        if (idct_out_normalized[row][col] > 255)
                            idct_out[row][col] = 255;
                        else if (idct_out_normalized[row][col] < 0)
                            idct_out[row][col] = 0;
                        else
                            idct_out[row][col] = idct_out_normalized[row][col];
                    end
                end
                // Transition back to IDLE for the next block.
                // if (!valid_in)
                next_state = IDLE;
                // else
                //     next_state = DONE;
            end

        endcase
    end

// FSM state update and output assignment (sequential)
always_ff @(posedge clk) begin
    if (rst) begin
        state  <= IDLE;
        valid_row_out_cnt <= 3'd0;
        row_input_cnt <= '0;
        col_input_cnt <= '0;
        valid_col_out_cnt <= 3'd0;
        valid_out         <= 1'b0;
        channel_out <= '0;
        channel_reg <= '0;
        fifo_head <= 'd0; fifo_tail <= 'd0; fifo_count <= 'd0;

    end else begin
        state <= next_state;
        if (valid_in) begin 
            if ( fifo_count < `FIFO_SIZE-1) begin
                input_fifo[fifo_tail].data <= idct_in;
                input_fifo[fifo_tail].channel <= channel_in;
                fifo_tail <= fifo_tail + 'd1;
                fifo_count <= fifo_count + 'd1;
            end
            else 
                $display("fifo for the win");
        end
        case (state)
            IDLE: begin
                //$display("IDLE state");
                valid_out         <= 1'b0;   
                valid_row_out_cnt <= 3'd0;
                valid_col_out_cnt <= 3'd0;

                row_input_cnt <= '0;
                col_input_cnt <= '0;

                channel_out <= '0;
                channel_reg <= '0;

            end
            LOAD: begin
                for (int r = 0; r < 8; r++)
                    for (int c = 0; c < 8; c++)
                        idct_in_extended[r][c] <= input_fifo[fifo_head].data[r][c];
                channel_reg <= input_fifo[fifo_head].channel;
                fifo_head <= fifo_head + 'd1;
                fifo_count <= fifo_count - 'd1;
            end
            PROCESS_ROWS: begin
                if (valid_row_out) begin
                    // Capture the output of the row-IDCT for the current row.
                    mem_rows[0][valid_row_out_cnt] <= row_idct_output[0];
                    mem_rows[1][valid_row_out_cnt] <= row_idct_output[1];
                    mem_rows[2][valid_row_out_cnt] <= row_idct_output[2];
                    mem_rows[3][valid_row_out_cnt] <= row_idct_output[3];
                    mem_rows[4][valid_row_out_cnt] <= row_idct_output[4];
                    mem_rows[5][valid_row_out_cnt] <= row_idct_output[5];
                    mem_rows[6][valid_row_out_cnt] <= row_idct_output[6];
                    mem_rows[7][valid_row_out_cnt] <= row_idct_output[7];
                    valid_row_out_cnt <= valid_row_out_cnt + 'd1;
                end
                row_input_cnt <= row_input_cnt + 'd1;
            end
            PROCESS_COLS: begin
                if (valid_col_out) begin
                    // Capture the output of the column-IDCT and transpose
                    mem_cols[0][valid_col_out_cnt] <= col_idct_output[0];
                    mem_cols[1][valid_col_out_cnt] <= col_idct_output[1];
                    mem_cols[2][valid_col_out_cnt] <= col_idct_output[2];
                    mem_cols[3][valid_col_out_cnt] <= col_idct_output[3];
                    mem_cols[4][valid_col_out_cnt] <= col_idct_output[4];
                    mem_cols[5][valid_col_out_cnt] <= col_idct_output[5];
                    mem_cols[6][valid_col_out_cnt] <= col_idct_output[6];
                    mem_cols[7][valid_col_out_cnt] <= col_idct_output[7];
                    valid_col_out_cnt <= valid_col_out_cnt + 'd1;
                end
                col_input_cnt <= col_input_cnt + 'd1;
            end
            DONE: begin
                valid_out   <= 1'b1;
                channel_out <= channel_reg;
            end
           
            default: valid_out <= 1'b0;

        endcase
    end
end

    assign row_idct_valid = (state == PROCESS_ROWS);
    assign col_idct_valid = (state == PROCESS_COLS);

    // Row IDCT instance
    loeffler_idct_old row_idct_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(row_idct_valid),
        .channel_in(channel_in),
        .idct_in(row_idct_input),
        .idct_out(row_idct_output),
        .channel_out(),
        .valid_out(valid_row_out)
    );

    // Column IDCT instance
    loeffler_idct_old col_idct_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(col_idct_valid),
        .channel_in(channel_in),
        .idct_in(col_idct_input),
        .idct_out(col_idct_output),
        .channel_out(internal_channel),
        .valid_out(valid_col_out)
    );

endmodule
