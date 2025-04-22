
`include "sys_defs.svh"

`define FIFO_SIZE 4096
`define FIFO_BITS $clog2(`FIFO_SIZE)

module loeffler2d_idct (
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [$clog2(`CH+1)-1:0] channel_in,
    input  logic signed [11:0] idct_in [7:0][7:0],  // Full 8x8 block input
    output logic unsigned [7:0] idct_out [7:0][7:0], // Full 8x8 block output
    output logic [$clog2(`CH+1)-1:0] channel_out,
    output logic valid_out
);

    logic stage1_valid_out;
    logic stage2_valid_out;
    logic stage3_valid_out;


    logic [1:0] stage1_channel_out;
    logic [1:0] stage2_channel_out;
    logic [1:0] stage3_channel_out;

    logic stage1_valid_in;
    logic [1:0] stage1_channel_in;  

    // logic stage2_ready_out;
    // logic stage3_ready_out;

    logic signed [11:0] stage1_block_in [7:0][7:0];

    logic signed [11:0] stage1_block_out [7:0][7:0];
    logic signed [63:0] stage2_block_out [7:0][7:0];
    logic signed [63:0] stage3_block_out [7:0][7:0];


    always_ff @(posedge clk) begin
        if(rst) begin
            stage1_valid_in <= '0;
            stage1_channel_in <= '0;
        end else begin
            if (valid_in) begin
                stage1_valid_in <= 'd1;
                stage1_channel_in <= channel_in;
                for (int r = 0; r < 8; r++)
                    for (int c = 0; c < 8; c++)
                        stage1_block_in[r][c] <= idct_in[r][c];
            end else begin
                stage1_valid_in <= 'd0;
                stage1_channel_in <= 'd0;
            end
        end
    end

    /****************** STAGE 1 *******************/
    loeffler_2d_stage_1 stage1 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage1_valid_in),
        .channel_in(stage1_channel_in),
        .block_in(stage1_block_in),
        // .stage2_ready(stage2_ready_out),
        

        .stage1_block_out(stage1_block_out),
        .stage1_channel_out(stage1_channel_out),
        .stage1_valid_out(stage1_valid_out)
    );

    /****************** STAGE 2 *******************/
    loeffler_2d_stage_2 stage2 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage1_valid_out),
        .channel_in(stage1_channel_out),
        .block_in(stage1_block_out),

        // .stage3_ready(stage3_ready_out),
        // .stage2_ready_out(stage2_ready_out),

        .stage2_block_out(stage2_block_out),
        .stage2_channel_out(stage2_channel_out),
        .stage2_valid_out(stage2_valid_out)
    );

    /****************** STAGE 3 *******************/
    loeffler_2d_stage_3 stage3 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage2_valid_out),
        .channel_in(stage2_channel_out),
        .block_in(stage2_block_out),
        
        // .stage3_ready_out(stage3_ready_out),

        .stage3_block_out(stage3_block_out),
        .stage3_channel_out(stage3_channel_out),
        .stage3_valid_out(stage3_valid_out)
    );

    /****************** STAGE 4 *******************/
    loeffler2d_stage_4 stage4 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage3_valid_out),
        .channel_in(stage3_channel_out),
        .block_in(stage3_block_out),

        .stage4_block_out(idct_out),
        .stage4_channel_out(channel_out),
        .stage4_valid_out(valid_out)
    );
endmodule

// store 8x8 block in fifo on valid in
module loeffler_2d_stage_1
    (
        input  logic clk,
        input  logic rst,
        input  logic valid_in,
        input  logic [1:0] channel_in,
        // input  logic stage2_ready, 
        input  logic signed [11:0] block_in [7:0][7:0], 
        output logic signed [11:0] stage1_block_out [7:0][7:0],
        output logic [1:0] stage1_channel_out,
        output logic stage1_valid_out
    );

    typedef struct {
        logic signed [11:0] data [7:0][7:0];
        logic [$clog2(`CH+1)-1:0] channel;
    } idct_block_t;

    idct_block_t input_fifo [`FIFO_SIZE-1:0];
    logic [`FIFO_BITS-1:0] fifo_head, fifo_tail;
    logic [`FIFO_BITS-1:0] fifo_count;


    logic will_enqueue, will_dequeue;

    logic [3:0] cycle_wait_cnt, cycle_wait_cnt_n;


    assign will_enqueue = valid_in && (fifo_count < `FIFO_SIZE);
    assign will_dequeue = (fifo_count > 0) && (cycle_wait_cnt == 'd9);

    assign cycle_wait_cnt_n = (cycle_wait_cnt < 'd9) ? cycle_wait_cnt + 1 : cycle_wait_cnt;

    always_ff @(posedge clk) begin
        if (rst) begin
            fifo_head <= 'd0;
            fifo_tail <= 'd0;
            fifo_count <= 'd0;
            stage1_valid_out <= 'd0;
            stage1_channel_out <= 'd0;
            cycle_wait_cnt <= 'd8;
        end else begin
            cycle_wait_cnt <= cycle_wait_cnt_n;
            // --- ENQUEUE ---
            if (will_enqueue) begin
                input_fifo[fifo_tail].data <= block_in;
                input_fifo[fifo_tail].channel <= channel_in;
                fifo_tail <= (fifo_tail + 1) & (`FIFO_SIZE - 1);
            end

            // --- DEQUEUE ---
            if (will_dequeue) begin
                cycle_wait_cnt <= 0;
                stage1_valid_out <= 1;
                stage1_channel_out <= input_fifo[fifo_head].channel;
                for (int r = 0; r < 8; r++)
                    for (int c = 0; c < 8; c++)
                        stage1_block_out[r][c] <= input_fifo[fifo_head].data[r][c];
                fifo_head <= (fifo_head + 1) & (`FIFO_SIZE - 1);
            end else begin
                stage1_valid_out <= 0;
            end

            // --- FIXED COUNT UPDATE ---
            case ({will_enqueue, will_dequeue})
                2'b10: fifo_count <= fifo_count + 1; // Only enqueue
                2'b01: fifo_count <= fifo_count - 1; // Only dequeue
                2'b11: fifo_count <= fifo_count;     // Enqueue and dequeue cancel out
                default: fifo_count <= fifo_count;   // Neither
            endcase
        end
    end
endmodule

// Process Rows
module loeffler_2d_stage_2 (
        input  logic clk,
        input  logic rst,
        input  logic valid_in,
        input  logic [1:0] channel_in,
        input  logic signed [11:0] block_in [7:0][7:0], 

        output logic signed [63:0] stage2_block_out [7:0][7:0],
        output logic [1:0] stage2_channel_out,
        output logic stage2_valid_out
    );
    logic signed [63:0] idct_in_extended [7:0][7:0];


    logic row_idct_valid;
    logic [3:0] row_input_cnt;
    logic [3:0] row_input_cnt_n;
    logic signed [63:0] row_idct_input [7:0];
    logic [1:0] channel_in_reg;

    logic valid_row_out;
    logic [3:0] valid_row_out_cnt;
    logic [3:0] valid_row_out_cnt_n;
    logic signed [63:0] row_idct_output [7:0];
    logic signed [63:0] mem_rows [7:0][7:0];
    logic [1:0] channel_out; 

    logic busy;

    // handling input
    always_comb begin
        row_input_cnt_n = 'd0;
        row_idct_valid = 'd0; 
        if (busy && row_input_cnt < 'd8) begin
            row_idct_input = idct_in_extended[row_input_cnt];
            row_input_cnt_n = row_input_cnt + 'd1;    
            row_idct_valid = 'd1;           
        end 
    end

    always_comb begin
        valid_row_out_cnt_n = 'd0;    // default: 0
        if (valid_row_out) 
            valid_row_out_cnt_n = valid_row_out_cnt + 1;
    end


    always_ff @(posedge clk) begin
        if (rst) begin
            stage2_valid_out <= 'd0;
            stage2_channel_out <= 'd0;
            row_input_cnt <= 'd0;
            valid_row_out_cnt <= '0;
            busy <= 'd0;
        end
        else begin
            stage2_valid_out <= 'd0;
            stage2_channel_out <= 'd0;
            row_input_cnt <= row_input_cnt_n;
            valid_row_out_cnt <= valid_row_out_cnt_n;
        
            if (valid_in) begin
                if (row_input_cnt == 'd0) begin
                    busy <= 'd1;

                    for (int r = 0; r < 8; r++)
                        for (int c = 0; c < 8; c++)
                            idct_in_extended[r][c] <= block_in[r][c];   
                    channel_in_reg <= channel_in; 
                end else begin
                    $display("Row input cnt is not 0: %d", row_input_cnt);
                end
            end

            if (row_input_cnt == 'd8)
                busy <= 'd0;

            // handling output
            if (valid_row_out_cnt == 'd8) begin
                for (int r = 0; r < 8; r++)
                    for (int c = 0; c < 8; c++)
                        stage2_block_out[r][c] <= mem_rows[r][c];
                stage2_valid_out <= 'd1;
                stage2_channel_out <= channel_out;
            end 

            if (valid_row_out) begin
                for (int i = 0; i < 8; i++) begin
                    mem_rows[i][valid_row_out_cnt] <= row_idct_output[i];
                end
            end
        end
    end

    // Row IDCT instance
    loeffler_idct row_idct_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(row_idct_valid),
        .channel_in(channel_in_reg),
        .idct_in(row_idct_input),
        .idct_out(row_idct_output),
        .channel_out(channel_out),
        .valid_out(valid_row_out)
    );
endmodule

module loeffler_2d_stage_3 (
        input  logic clk,
        input  logic rst,
        input  logic valid_in,
        input  logic [1:0] channel_in,
        input  logic signed [63:0] block_in [7:0][7:0], 

        output logic signed [63:0] stage3_block_out [7:0][7:0],
        output logic [1:0] stage3_channel_out,
        output logic stage3_valid_out

    );
    logic signed [63:0] idct_in_reg [7:0][7:0];
    logic col_idct_valid;

    logic [3:0] col_input_cnt;
    logic [3:0] col_input_cnt_n;
    logic signed [63:0] col_idct_input [7:0];
    logic [1:0] channel_in_reg;

    logic valid_col_out;
    logic [3:0] valid_col_out_cnt;
    logic [3:0] valid_col_out_cnt_n;

    logic signed [63:0] col_idct_output [7:0];
    logic signed [63:0] mem_cols [7:0][7:0];
    logic [1:0] channel_out; 

    logic busy;

    // handling input
    always_comb begin
        col_input_cnt_n = 'd0;
        col_idct_valid = 'd0; 
        if (busy && col_input_cnt < 'd8) begin
            col_idct_input = idct_in_reg[col_input_cnt];
            col_input_cnt_n = col_input_cnt + 'd1;    
            col_idct_valid = 'd1;           
        end 
    end

    always_comb begin
        valid_col_out_cnt_n = 'd0;    // default: hold
        if (valid_col_out) 
            valid_col_out_cnt_n = valid_col_out_cnt + 1;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            stage3_valid_out <= 'd0;
            stage3_channel_out <= 'd0;
            col_input_cnt <= 'd0;
            valid_col_out_cnt <= 'd0;
            busy <= 'd0;

        end else begin
            stage3_valid_out <= 'd0;
            stage3_channel_out <= 'd0;
            valid_col_out_cnt <= valid_col_out_cnt_n;
            col_input_cnt <= col_input_cnt_n;

            // Start new block if input is valid and we're not currently processing
            if (valid_in) begin
                busy <= 'd1;
                if (col_input_cnt == 'd0) begin
                    for (int r = 0; r < 8; r++)
                        for (int c = 0; c < 8; c++)
                            idct_in_reg[r][c] <= block_in[r][c];
                    channel_in_reg <= channel_in;
                end else begin
                    $display("Error active and got data in stage 3");
                end
            end

            if (col_input_cnt == 'd8)
                busy <= 'd0;
            
           if (valid_col_out_cnt == 'd8) begin
                for (int r = 0; r < 8; r++)
                    for (int c = 0; c < 8; c++)
                        stage3_block_out[r][c] <= mem_cols[r][c];
                stage3_valid_out <= 'd1;
                stage3_channel_out <= channel_out;
            end 
            if (valid_col_out) begin
                for (int i = 0; i < 8; i++) begin
                    mem_cols[i][valid_col_out_cnt] <= col_idct_output[i];
                end
            end
        end
    end
    // Column IDCT instance
    loeffler_idct col_idct_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(col_idct_valid),
        .channel_in(channel_in_reg),
        .idct_in(col_idct_input),
        .idct_out(col_idct_output),
        .channel_out(channel_out),
        .valid_out(valid_col_out)
    );
endmodule

// Normalize
module loeffler2d_stage_4 (
        input  logic clk,
        input  logic rst,
        input  logic valid_in,
        input  logic [1:0] channel_in,
        input  logic signed [63:0] block_in [7:0][7:0], 

        output logic unsigned [7:0] stage4_block_out [7:0][7:0],
        output logic [1:0] stage4_channel_out,
        output logic stage4_valid_out
    );

    logic signed [63:0] idct_out_normalized [7:0][7:0];


    always_ff @(posedge clk) begin
        if (rst) begin
            stage4_valid_out <= 'd0;
            stage4_channel_out <= 'd0;
        end else begin
            if (valid_in) begin 
                stage4_valid_out <= 'd1;
                stage4_channel_out <= channel_in;
                for (int r = 0; r < 8; r++) begin
                    for (int c = 0; c < 8; c++) begin
                        // Normalize: shift right by 3 (divide by 8) and add 128.
                        idct_out_normalized[r][c] = (block_in[r][c] >>> 3) + 128;
                        if (idct_out_normalized[r][c] > 255)
                            stage4_block_out[r][c] = 255;
                        else if (idct_out_normalized[r][c] < 0)
                            stage4_block_out[r][c] = 0;
                        else
                            stage4_block_out[r][c] = idct_out_normalized[r][c];
                    end
                end                 
            end else begin
                stage4_valid_out <= 'd0;
                stage4_channel_out <= 'd0;
            end
        end
    end
endmodule
