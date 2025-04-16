module loeffler_idct
(
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [1:0] channel_in,
    input  logic signed [63:0] idct_in  [7:0],
    output logic signed [63:0] idct_out [7:0],
    output logic [1:0] channel_out,
    output logic valid_out
);

    logic stage1_valid_out;
    logic stage2_valid_out;
    logic stage3_valid_out;
    logic stage4_valid_out;
    logic stage5_valid_out;
    logic stage6_valid_out;
    logic stage7_valid_out;

    logic [1:0] stage1_channel_out;
    logic [1:0] stage2_channel_out;
    logic [1:0] stage3_channel_out;
    logic [1:0] stage4_channel_out;
    logic [1:0] stage5_channel_out;
    logic [1:0] stage6_channel_out;
    logic [1:0] stage7_channel_out;

    logic stage1_valid_in;
    logic [1:0] channel_in_reg;

    logic signed [63:0] stage1_in  [7:0];
    logic signed [63:0] stage1_out [7:0];
    logic signed [63:0] stage2_out [8:0];
    logic signed [63:0] stage3_out [8:0];
    logic signed [63:0] stage4_out [8:0];
    logic signed [63:0] stage5_out [9:0];
    logic signed [63:0] stage6_out [9:0];
    logic signed [63:0] stage7_out [7:0];

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 8; i++) stage1_in[i] <= '0;
            stage1_valid_in <= '0;
            channel_in_reg <= '0;
        end
        else begin
            stage1_valid_in <= valid_in;
            for(int i = 0; i < 8; i++) begin
                stage1_in[i] <= idct_in[i];
            end
            channel_in_reg <= channel_in;
        end
    end

    /****************** STAGE 1 *******************/

    loeffler_idct_stage_1 #(.INPUT_WIDTH(64), .OUTPUT_WIDTH(64)) stage1 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage1_valid_in),
        .channel_in(channel_in_reg),
        .x_in_reversed(stage1_in),
        .y_out(stage1_out),
        .channel_out(stage1_channel_out),
        .valid_out(stage1_valid_out)
    );


    /****************** STAGE 2 *******************/

    loeffler_idct_stage_2 #(.INPUT_WIDTH(64), .OUTPUT_WIDTH(64)) stage2 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage1_valid_out),
        .channel_in(stage1_channel_out),
        .x_in(stage1_out),
        .y_out(stage2_out),
        .channel_out(stage2_channel_out),
        .valid_out(stage2_valid_out)
    );

    /****************** STAGE 3 *******************/

    loeffler_idct_stage_3 #(.INPUT_WIDTH(64), .OUTPUT_WIDTH(64)) stage3 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage2_valid_out),
        .channel_in(stage2_channel_out),
        .x_in(stage2_out),
        .y_out(stage3_out),
        .channel_out(stage3_channel_out),
        .valid_out(stage3_valid_out)
    );

    /****************** STAGE 4 *******************/

    loeffler_idct_stage_4 #(.INPUT_WIDTH(64), .OUTPUT_WIDTH(64)) stage4 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage3_valid_out),
        .channel_in(stage3_channel_out),
        .x_in(stage3_out),
        .y_out(stage4_out),
        .channel_out(stage4_channel_out),
        .valid_out(stage4_valid_out)
    );

    /****************** STAGE 5 *******************/

    loeffler_idct_stage_5 #(.INPUT_WIDTH(64), .OUTPUT_WIDTH(64)) stage5 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage4_valid_out),
        .channel_in(stage4_channel_out),
        .x_in(stage4_out),
        .y_out(stage5_out),
        .channel_out(stage5_channel_out),
        .valid_out(stage5_valid_out)
    );

    /****************** STAGE 6 *******************/

    loeffler_idct_stage_6 #(.INPUT_WIDTH(64), .OUTPUT_WIDTH(64)) stage6 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage5_valid_out),
        .channel_in(stage5_channel_out),
        .x_in(stage5_out),
        .y_out(stage6_out),
        .channel_out(stage6_channel_out),
        .valid_out(stage6_valid_out)
    );

    /****************** STAGE 7 *******************/

    loeffler_idct_stage_7 #(.INPUT_WIDTH(64), .OUTPUT_WIDTH(64)) stage7 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage6_valid_out),
        .channel_in(stage6_channel_out),
        .x_in(stage6_out),
        .y_out(stage7_out),
        .channel_out(stage7_channel_out),
        .valid_out(stage7_valid_out)
    );

    /****************** STAGE 8 *******************/

    loeffler_idct_stage_8 #(.INPUT_WIDTH(64), .OUTPUT_WIDTH(64)) stage8 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage7_valid_out),
        .channel_in(stage7_channel_out),
        .x_in(stage7_out),
        .y_out(idct_out),
        .channel_out(channel_out),
        .valid_out(valid_out)
    );

endmodule: loeffler_idct

// Checked
module loeffler_idct_stage_1 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [1:0] channel_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in_reversed  [7:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out          [7:0],
    output logic [1:0] channel_out,
    output logic valid_out
);

    logic signed [INPUT_WIDTH-1:0] x_in [7:0];

    // Undo bit-reverse order
    always_comb begin
        x_in[0] = x_in_reversed[0];
        x_in[1] = x_in_reversed[4];
        x_in[2] = x_in_reversed[2];
        x_in[3] = x_in_reversed[6];
        x_in[4] = x_in_reversed[7];
        x_in[5] = x_in_reversed[3];
        x_in[6] = x_in_reversed[5];
        x_in[7] = x_in_reversed[1];
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 8; i++) y_out[i] <= '0;
            valid_out   <= '0;
            channel_out <= '0;
        end
        else begin
            valid_out   <= valid_in;
            channel_out <= channel_in;
            if(valid_in) begin

                y_out[0] <= x_in[0];
                y_out[1] <= x_in[1];
                y_out[2] <= x_in[2];
                y_out[3] <= x_in[3];
                y_out[4] <= x_in[4];
                y_out[7] <= x_in[7];

                // CSD Multiplication
                // H = 001_0110_1010
                y_out[5] <= ((x_in[5] << 8) + (x_in[5] << 6) + (x_in[5] << 5) + (x_in[5] << 3) + (x_in[5] << 1));
                y_out[6] <= ((x_in[6] << 8) + (x_in[6] << 6) + (x_in[6] << 5) + (x_in[6] << 3) + (x_in[6] << 1));

            end
            else begin
                for(int i = 0; i < 8; i++) y_out[i] <= '0;
            end
        end
    end

endmodule: loeffler_idct_stage_1

// Checked
module loeffler_idct_stage_2 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [1:0] channel_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [7:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [8:0],
    output  logic [1:0] channel_out,
    output logic valid_out
);

    logic signed [OUTPUT_WIDTH-1:0] y_out_result [8:0];

    always_comb begin
                
        // Passthrough signals
        y_out_result[0] = x_in[0];
        y_out_result[1] = x_in[1];
        y_out_result[5] = x_in[5];
        y_out_result[6] = x_in[6];

        // Additions/Substractions
        y_out_result[8] = (x_in[2] + x_in[3]);
        y_out_result[4] = (x_in[7] - x_in[4]) << 8;
        y_out_result[7] = (x_in[7] + x_in[4]) << 8;

        // CSD Multiplication
        // (C-F) = 000_1100_0100
        // (C+F) = 010_0-101_1001
        y_out_result[2] =  ((x_in[3] << 9) - (x_in[3] << 6) + (x_in[3] << 4) + (x_in[3] << 3) + x_in[3]);
        y_out_result[3] =  ((x_in[2] << 7) + (x_in[2] << 6) + (x_in[2] << 2));
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 9; i++) y_out[i] <= '0;
            valid_out   <= '0;
            channel_out <= '0;
        end
        else begin
            valid_out   <= valid_in;
            channel_out <= channel_in;
            if(valid_in) begin
                for(int i = 0; i < 9; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_idct_stage_2

// Checked
module loeffler_idct_stage_3 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [1:0] channel_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [8:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [8:0],
    output  logic [1:0] channel_out,
    output logic valid_out
);

    logic signed [OUTPUT_WIDTH-1:0] y_out_result [8:0];
    
    always_comb begin

        // Passthrough signals
        y_out_result[0] = x_in[0];
        y_out_result[1] = x_in[1];
        y_out_result[2] = x_in[2];
        y_out_result[3] = x_in[3];

        // Additions/Substractions
        y_out_result[4] = x_in[4] + x_in[6];
        y_out_result[5] = x_in[7] - x_in[5];
        y_out_result[6] = x_in[4] - x_in[6];
        y_out_result[7] = x_in[7] + x_in[5];

        // CSD Multiplication
        // F = 000_1000_1011
        y_out_result[8] = ((x_in[8] << 7) + (x_in[8] << 3) + (x_in[8] << 1) + x_in[8]);

    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 9; i++) y_out[i] <= '0;
            valid_out   <= '0;
            channel_out <= '0;
        end
        else begin
            valid_out   <= valid_in;
            channel_out <= channel_in;
            if(valid_in) begin
                for(int i = 0; i < 9; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_idct_stage_3

// Checked
module loeffler_idct_stage_4 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [1:0] channel_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [8:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [8:0],
    output  logic [1:0] channel_out,
    output logic valid_out
);

    logic signed [OUTPUT_WIDTH-1:0] y_out_result [8:0];

    always_comb begin

        // Passthrough signals
        y_out_result[0] = x_in[0];
        y_out_result[1] = x_in[1];
        y_out_result[5] = x_in[5];
        y_out_result[6] = x_in[6];

        // Additions/Substractions
        y_out_result[2] = x_in[8] - x_in[2];
        y_out_result[3] = x_in[8] + x_in[3];
        y_out_result[8] = x_in[4] + x_in[7];

        // CSD Multiplications
        // (E-D) = 111_1100_-1001
        // (E+D) = 001_0110_0011
        y_out_result[7] = (-(x_in[4] << 6) - (x_in[4] << 3) + x_in[4]);
        y_out_result[4] = ((x_in[7] << 8) + (x_in[7] << 6) + (x_in[7] << 5) + (x_in[7] << 1) + x_in[7]);

    end
    
   always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 9; i++) y_out[i] <= '0;
            valid_out   <= '0;
            channel_out <= '0;
        end
        else begin
            valid_out   <= valid_in;
            channel_out <= channel_in;
            if(valid_in) begin
                for(int i = 0; i < 9; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_idct_stage_4


// Checked
module loeffler_idct_stage_5 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [1:0] channel_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [8:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [9:0],
    output  logic [1:0] channel_out,
    output logic valid_out
);

    logic signed [OUTPUT_WIDTH-1:0] y_out_result [9:0];

    always_comb begin

        // Passthrough signals
        y_out_result[0] = x_in[0];
        y_out_result[1] = x_in[1];
        y_out_result[2] = x_in[2];
        y_out_result[3] = x_in[3];
        y_out_result[4] = x_in[4];
        y_out_result[7] = x_in[7];
        y_out_result[8] = x_in[8];

        // Additions/Subtractions
        y_out_result[9] = x_in[5] + x_in[6];

        // CSD Multiplication
        // (G+B) = 001_0010_1101
        // (G-B) = 111_0011_100-1
        y_out_result[5] = ((x_in[6] <<  8) + (x_in[6] << 5) + (x_in[6] << 3) + (x_in[6] << 2) + x_in[6]);
        y_out_result[6] = (-(x_in[5] << 8) + (x_in[5] << 5) + (x_in[5] << 4) + (x_in[5] << 3) - x_in[5]);

    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 10; i++) y_out[i] <= '0;
            valid_out   <= '0;
            channel_out <= '0;
        end
        else begin
            valid_out   <= valid_in;
            channel_out <= channel_in;
            if(valid_in) begin
                for(int i = 0; i < 10; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_idct_stage_5


// Checked
module loeffler_idct_stage_6 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [1:0] channel_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [9:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [9:0],
    output  logic [1:0] channel_out,
    output logic valid_out
);

    logic signed [OUTPUT_WIDTH-1:0] y_out_result [9:0];

    always_comb begin

        // Additions/Substractions
        y_out_result[0] = x_in[0] + x_in[1];
        y_out_result[1] = x_in[0] - x_in[1];

        // Shifting
        y_out_result[2] = x_in[2] >>> 8;
        y_out_result[3] = x_in[3] >>> 8;

        // Passthrough signals
        y_out_result[4] = x_in[4];
        y_out_result[5] = x_in[5];
        y_out_result[6] = x_in[6];
        y_out_result[7] = x_in[7];

        // CSD Multiplications
        // D = 000_1101_0101
        // B = 001_0000_-1011
        y_out_result[8] = ((x_in[8] << 7) + (x_in[8] << 6) + (x_in[8] << 4) + (x_in[8] << 2) + x_in[8]);
        y_out_result[9] = ((x_in[9] << 8) - (x_in[9] << 3) + (x_in[9] << 1) + x_in[9]);

    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 10; i++) y_out[i] <= '0;
            valid_out   <= '0;
            channel_out <= '0;
        end
        else begin
            valid_out   <= valid_in;
            channel_out <= channel_in;
            if(valid_in) begin
                for(int i = 0; i < 10; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_idct_stage_6

// Checked
module loeffler_idct_stage_7 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [1:0] channel_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [9:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [7:0],
    output  logic [1:0] channel_out,
    output logic valid_out
);

    logic signed [OUTPUT_WIDTH-1:0] y_out_result [7:0];

    always_comb begin

        // Additions/Substractions
        y_out_result[0] = (x_in[0] + x_in[3]);
        y_out_result[1] = (x_in[1] + x_in[2]);
        y_out_result[2] = (x_in[1] - x_in[2]);
        y_out_result[3] = (x_in[0] - x_in[3]);
        y_out_result[4] = (x_in[8] - x_in[4]) >>> 16;
        y_out_result[5] = (x_in[9] - x_in[5]) >>> 16;
        y_out_result[6] = (x_in[9] + x_in[6]) >>> 16;
        y_out_result[7] = (x_in[8] + x_in[7]) >>> 16;
        
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 8; i++) y_out[i] <= '0;
            valid_out   <= '0;
            channel_out <= '0;
        end
        else begin
            valid_out   <= valid_in;
            channel_out <= channel_in;
            if(valid_in) begin
                for(int i = 0; i < 8; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_idct_stage_7

// Checked
module loeffler_idct_stage_8 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [1:0] channel_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [7:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [7:0],
    output  logic [1:0] channel_out,
    output logic valid_out
);

    logic signed [OUTPUT_WIDTH-1:0] y_out_result [7:0];

    always_comb begin

        // Additions/Substractions
        y_out_result[0] = x_in[0] + x_in[7];
        y_out_result[1] = x_in[1] + x_in[6];
        y_out_result[2] = x_in[2] + x_in[5];
        y_out_result[3] = x_in[3] + x_in[4];
        y_out_result[4] = x_in[3] - x_in[4];
        y_out_result[5] = x_in[2] - x_in[5];
        y_out_result[6] = x_in[1] - x_in[6];
        y_out_result[7] = x_in[0] - x_in[7];

    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 8; i++) y_out[i] <= '0;
            valid_out   <= '0;
            channel_out <= '0;
        end
        else begin
            valid_out   <= valid_in;
            channel_out <= channel_in;
            if(valid_in) begin
                for(int i = 0; i < 8; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_idct_stage_8
