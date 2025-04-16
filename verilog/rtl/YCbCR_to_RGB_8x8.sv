`include "sys_defs.svh"
module YCbCr_to_RGB_8x8 (
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [7:0] y  [7:0][7:0],
    input  logic [7:0] cb [7:0][7:0],
    input  logic [7:0] cr [7:0][7:0],
    output logic [7:0] r  [7:0][7:0],
    output logic [7:0] g  [7:0][7:0],
    output logic [7:0] b  [7:0][7:0],
    output logic valid_out
);

    logic [7:0] y_row   [7:0];
    logic [7:0] cb_row  [7:0];
    logic [7:0] cr_row  [7:0];
    logic [7:0] r_row   [7:0];
    logic [7:0] g_row   [7:0];
    logic [7:0] b_row   [7:0];
    logic       pixel_valid [7:0][7:0];

    // Output valid tracking
    logic valid_reduced;

    genvar i, j;
    generate
        for (i = 0; i < 8; i++) begin : row_gen
            for (j = 0; j < 8; j++) begin : col_gen
                YCbCr_to_RGB conv_inst (
                    .clk(clk),
                    .rst(rst),
                    .valid_in(valid_in),
                    .y(y[i][j]),
                    .cb(cb[i][j]),
                    .cr(cr[i][j]),
                    .r(r[i][j]),
                    .g(g[i][j]),
                    .b(b[i][j]),
                    .valid_out(pixel_valid[i][j])
                );
            end
        end
    endgenerate

    // Reduce pixel_valid matrix to one signal
    always_comb begin
        valid_reduced = 1'b1;
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                valid_reduced &= pixel_valid[i][j];
            end
        end
    end

    assign valid_out = valid_reduced;

endmodule

module YCbCr_to_RGB (
    input  logic clk,
    input  logic rst,
    input  logic [7:0] y, cb, cr,       // YCbCr input, unsigned 8-bit
    input  logic valid_in,
    output logic [7:0] r, g, b,         // RGB output, unsigned 8-bit
    output logic valid_out
);

    // Intermediate signed results
    logic signed [16:0] r_tmp, g_tmp, b_tmp;
    logic signed [16:0] r_y, r_cr;
    logic signed [16:0] g_y, g_cb, g_cr;
    logic signed [16:0] b_y, b_cb;

    // Clamped 8-bit outputs
    logic [7:0] r_clamped, g_clamped, b_clamped;

    // Common Y contribution (298 * y) >> 8
    assign r_y = ((y  << 8) + (y  << 5) + (y  << 3) + (y  << 1)) >> 8; // = 298*y >> 8
    assign g_y = r_y;
    assign b_y = r_y;

    // Cr for R: (408 * cr) >> 8
    assign r_cr = ((cr << 8) + (cr << 7) + (cr << 4) + (cr << 3)) >> 8;

    // Cb and Cr for G: (100 * cb) >> 8, (208 * cr) >> 8
    assign g_cb = ((cb << 6) + (cb << 5) + (cb << 2)) >> 8;
    assign g_cr = ((cr << 7) + (cr << 6) + (cr << 4)) >> 8;

    // Cb for B: (516 * cb) >> 8
    assign b_cb = ((cb << 9) + (cb << 2)) >> 8;

    // ----------- Final RGB Math with Bias Correction ----------- //
    assign r_tmp = r_y + r_cr - 223;
    assign g_tmp = g_y - g_cb - g_cr + 136;
    assign b_tmp = b_y + b_cb - 277;

    // ----------- Clamp RGB to [0, 255] ----------- //
    always_comb begin
        r_clamped = (r_tmp > 255) ? 8'd255 : (r_tmp < 0 ? 8'd0 : r_tmp[7:0]);
        g_clamped = (g_tmp > 255) ? 8'd255 : (g_tmp < 0 ? 8'd0 : g_tmp[7:0]);
        b_clamped = (b_tmp > 255) ? 8'd255 : (b_tmp < 0 ? 8'd0 : b_tmp[7:0]);
    end

    // ----------- Output Register Stage ----------- //
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            r <= 8'd0;
            g <= 8'd0;
            b <= 8'd0;
            valid_out <= 1'b0;
        end else begin
            if (valid_in) begin
                r <= r_clamped;
                g <= g_clamped;
                b <= b_clamped;
                valid_out <= 1'b1;
            end else begin
                r <= 8'd0;
                g <= 8'd0;
                b <= 8'd0;
                valid_out <= 1'b0;
            end
        end
    end

endmodule
