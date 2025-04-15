module loeffler_dct
(
    input  logic signed clk,
    input  logic signed rst,
    input  logic valid_in,
    input  logic signed [7:0] dct_in  [7:0],
    output logic signed [31:0] dct_out [7:0],
    output logic valid_out
);

    //logic signed [7:0] [7:0] stage1_in;

    //assign stage1_in[0] = {24'd0, dct_in[0]};

    logic stage1_valid_out;
    logic stage2_valid_out;
    logic stage3_valid_out;
    logic stage4_valid_out;
    logic stage5_valid_out;
    logic stage6_valid_out;
    logic stage7_valid_out;

    logic stage1_valid_in;

    logic signed [31:0] stage1_in  [7:0];
    logic signed [31:0] stage1_out [7:0];
    logic signed [31:0] stage2_out [9:0];
    logic signed [31:0] stage3_out [9:0];
    logic signed [31:0] stage4_out [9:0];
    logic signed [31:0] stage5_out [8:0];
    logic signed [31:0] stage6_out [8:0];
    logic signed [31:0] stage7_out [8:0];

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 8; i++) stage1_in[i] <= '0;
            stage1_valid_in <= '0;
        end
        else begin
            stage1_valid_in <= valid_in;
            for(int i = 0; i < 8; i++) begin
                stage1_in[i] <= dct_in[i];
            end
        end
    end

    /****************** STAGE 1 *******************/

    loeffler_stage_1 #(.INPUT_WIDTH(32), .OUTPUT_WIDTH(32)) stage1 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage1_valid_in),
        .x_in(stage1_in),
        .y_out(stage1_out),
        .valid_out(stage1_valid_out)
    );


    /****************** STAGE 2 *******************/

    loeffler_stage_2 #(.INPUT_WIDTH(32), .OUTPUT_WIDTH(32)) stage2 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage1_valid_out),
        .x_in(stage1_out),
        .y_out(stage2_out),
        .valid_out(stage2_valid_out)
    );

    /****************** STAGE 3 *******************/

    loeffler_stage_3 #(.INPUT_WIDTH(32), .OUTPUT_WIDTH(32)) stage3 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage2_valid_out),
        .x_in(stage2_out),
        .y_out(stage3_out),
        .valid_out(stage3_valid_out)
    );

    /****************** STAGE 4 *******************/

    loeffler_stage_4 #(.INPUT_WIDTH(32), .OUTPUT_WIDTH(32)) stage4 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage3_valid_out),
        .x_in(stage3_out),
        .y_out(stage4_out),
        .valid_out(stage4_valid_out)
    );

    /****************** STAGE 5 *******************/

    loeffler_stage_5 #(.INPUT_WIDTH(32), .OUTPUT_WIDTH(32)) stage5 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage4_valid_out),
        .x_in(stage4_out),
        .y_out(stage5_out),
        .valid_out(stage5_valid_out)
    );

    /****************** STAGE 6 *******************/

    loeffler_stage_6 #(.INPUT_WIDTH(32), .OUTPUT_WIDTH(32)) stage6 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage5_valid_out),
        .x_in(stage5_out),
        .y_out(stage6_out),
        .valid_out(stage6_valid_out)
    );

    /****************** STAGE 7 *******************/

    loeffler_stage_7 #(.INPUT_WIDTH(32), .OUTPUT_WIDTH(32)) stage7 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage6_valid_out),
        .x_in(stage6_out),
        .y_out(stage7_out),
        .valid_out(stage7_valid_out)
    );

    /****************** STAGE 8 *******************/

    loeffler_stage_8 #(.INPUT_WIDTH(32), .OUTPUT_WIDTH(32)) stage8 (
        .clk(clk),
        .rst(rst),
        .valid_in(stage7_valid_out),
        .x_in(stage7_out),
        .y_out(dct_out),
        .valid_out(valid_out)
    );

endmodule: loeffler_dct

// Checked
module loeffler_stage_1 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic signed clk,
    input  logic signed rst,
    input  logic valid_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [7:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [7:0] ,
    output logic valid_out
);

    //logic signed [OUTPUT_WIDTH-1:0] [7:0] y_out_result;

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 8; i++) y_out[i] <= '0;
            valid_out <= '0;
        end
        else begin
            valid_out <= valid_in;
            if(valid_in) begin

                y_out[0] = x_in[0] + x_in[7];
                y_out[1] = x_in[1] + x_in[6];
                y_out[2] = x_in[2] + x_in[5];
                y_out[3] = x_in[3] + x_in[4];
                
                y_out[4] = x_in[3] - x_in[4];
                y_out[5] = x_in[2] - x_in[5];
                y_out[6] = x_in[1] - x_in[6];
                y_out[7] = x_in[0] - x_in[7];

            end
            else begin
                for(int i = 0; i < 8; i++) y_out[i] <= '0;
            end
        end
    end

endmodule: loeffler_stage_1

// Checked
module loeffler_stage_2 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic signed clk,
    input  logic signed rst,
    input  logic valid_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [7:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [9:0],
    output logic valid_out
);

    logic signed [OUTPUT_WIDTH-1:0] y_out_result [9:0];

    always_comb begin
                
        y_out_result[0] = x_in[0] + x_in[3];
        y_out_result[1] = x_in[1] + x_in[2];
        y_out_result[2] = x_in[1] - x_in[2];
        y_out_result[3] = x_in[0] - x_in[3];
        
        // Substractions
        // (E-D) = 111_1100_-1001
        // (E+D) = 001_0110_0011
        y_out_result[4] = (-(x_in[7] << 6) - (x_in[7] << 3) + x_in[7]);
        y_out_result[7] = ((x_in[4] << 8) + (x_in[4] << 6) + (x_in[4] << 5) + (x_in[4] << 1) + x_in[4]);

        // Inputs 5 and 6 pass through stage 2 without modification except for the fact that
        // these are switched. Input 6 goes to output 5 and input 5 goes to output 6
        y_out_result[5] = x_in[6];
        y_out_result[6] = x_in[5];

        // Compute value of the extra register
        y_out_result[8] = x_in[4] + x_in[7];
        y_out_result[9] = x_in[5] + x_in[6];
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 10; i++) y_out[i] <= '0;
            valid_out <= '0;
        end
        else begin
            valid_out <= valid_in;
            if(valid_in) begin
                for(int i = 0; i < 10; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_stage_2

// Checked
module loeffler_stage_3 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic signed clk,
    input  logic signed rst,
    input  logic valid_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [9:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [9:0],
    output logic valid_out
);

    logic signed [OUTPUT_WIDTH-1:0] y_out_result [9:0];
    
    always_comb begin

        // Additions/Substractions
        y_out_result[0] = x_in[0] + x_in[1];
        y_out_result[1] = x_in[0] - x_in[1];
        
        // Passthrough signals
        y_out_result[2] = x_in[2];
        y_out_result[3] = x_in[3];
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
            valid_out <= '0;
        end
        else begin
            valid_out <= valid_in;
            if(valid_in) begin
                for(int i = 0; i < 10; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_stage_3

// Checked
module loeffler_stage_4 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic signed clk,
    input  logic signed rst,
    input  logic valid_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [9:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [9:0],
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
        y_out_result[9] = x_in[9];

        // CSD Multiplication
        // (G-B) = 111_0011_100-1
        // (G+B) = 001_0010_1101
        y_out_result[5] = (-(x_in[5] << 8) + (x_in[5] << 5) + (x_in[5] << 4) + (x_in[5] << 3) - x_in[5]);
        y_out_result[6] = ((x_in[6] <<  8) + (x_in[6] << 5) + (x_in[6] << 3) + (x_in[6] << 2) + x_in[6]);          
    end
    
   always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 10; i++) y_out[i] <= '0;
            valid_out <= '0;
        end
        else begin
            valid_out <= valid_in;
            if(valid_in) begin
                for(int i = 0; i < 10; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_stage_4


// Checked
module loeffler_stage_5 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic signed clk,
    input  logic signed rst,
    input  logic valid_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [9:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [8:0],
    output logic valid_out
);

    logic signed [OUTPUT_WIDTH-1:0] y_out_result [8:0];

    always_comb begin

        // Passthrough signals
        y_out_result[0] = x_in[0];
        y_out_result[1] = x_in[1];

        // Passthrough signals re-routed
        y_out_result[2] = x_in[3];
        y_out_result[3] = x_in[2];

        y_out_result[4] = x_in[8] + x_in[4];
        y_out_result[5] = x_in[9] + x_in[5];
        y_out_result[6] = x_in[9] - x_in[6];
        y_out_result[7] = x_in[8] - x_in[7];
        y_out_result[8] = x_in[2] + x_in[3];
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 9; i++) y_out[i] <= '0;
            valid_out <= '0;
        end
        else begin
            valid_out <= valid_in;
            if(valid_in) begin
                for(int i = 0; i < 9; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_stage_5


// Checked
module loeffler_stage_6 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic signed clk,
    input  logic signed rst,
    input  logic valid_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [8:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [8:0],
    output logic valid_out
);

    logic signed [OUTPUT_WIDTH-1:0] y_out_result [8:0];

    always_comb begin

        // Passthrough signals
        y_out_result[0] = x_in[0];
        y_out_result[1] = x_in[1];
        y_out_result[2] = x_in[2];
        y_out_result[3] = x_in[3];

        // Add/Sub
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
            valid_out <= '0;
        end
        else begin
            valid_out <= valid_in;
            if(valid_in) begin
                for(int i = 0; i < 9; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_stage_6

// Checked
module loeffler_stage_7 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic signed clk,
    input  logic signed rst,
    input  logic valid_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [8:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [8:0],
    output logic valid_out
);

    logic signed [OUTPUT_WIDTH-1:0] y_out_result [8:0];

    always_comb begin
        
        // Passthrough signal
        y_out_result[0] = x_in[0];
        y_out_result[1] = x_in[1];
        y_out_result[5] = x_in[5];
        y_out_result[6] = x_in[6];
        y_out_result[8] = x_in[8];
        
        // CSD Multiplication
        // (C-F) = 000_1100_0100
        // (C+F) = 010_0-101_1001
        y_out_result[2] =  ((x_in[2] << 7) + (x_in[2] << 6) + (x_in[2] << 2));
        y_out_result[3] =  ((x_in[3] << 9) - (x_in[3] << 6) + (x_in[3] << 4) + (x_in[3] << 3) + x_in[3]);

        // Add/Sub
        y_out_result[4] = x_in[7] - x_in[4];
        y_out_result[7] = x_in[7] + x_in[4];
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 9; i++) y_out[i] <= '0;
            valid_out <= '0;
        end
        else begin
            valid_out <= valid_in;
            if(valid_in) begin
                for(int i = 0; i < 9; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_stage_7

// Checked
module loeffler_stage_8 #(parameter INPUT_WIDTH, parameter OUTPUT_WIDTH)
(
    input  logic signed clk,
    input  logic signed rst,
    input  logic valid_in,
    input  logic signed [INPUT_WIDTH-1:0]  x_in  [8:0],
    output logic signed [OUTPUT_WIDTH-1:0] y_out [7:0],
    output logic valid_out
);

    logic signed [OUTPUT_WIDTH-1:0] y_out_result [7:0];

    always_comb begin

        // Passthrough signal
        y_out_result[0] = x_in[0];
        y_out_result[4] = x_in[1];

        // Shift Only
        y_out_result[1] = x_in[7] >> 8;
        y_out_result[7] = x_in[4] >> 8;

        // Add/Sub and Shift
        y_out_result[2] = (x_in[8] + x_in[2]) >> 8;
        y_out_result[6] = (x_in[8] - x_in[3]) >> 8;

        // CSD Multiplication
        // H = 001_0110_1010
        y_out_result[3] = ((x_in[5] << 8) + (x_in[5] << 6) + (x_in[5] << 5) + (x_in[5] << 3) + (x_in[5] << 1)) >> 16;
        y_out_result[5] = ((x_in[6] << 8) + (x_in[6] << 6) + (x_in[6] << 5) + (x_in[6] << 3) + (x_in[6] << 1)) >> 16;
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i = 0; i < 8; i++) y_out[i] <= '0;
            valid_out <= '0;
        end
        else begin
            valid_out <= valid_in;
            if(valid_in) begin
                for(int i = 0; i < 8; i++) y_out[i] <= y_out_result[i];
            end
        end
    end

endmodule: loeffler_stage_8
