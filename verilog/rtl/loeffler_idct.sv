module loeffler_idct
#(parameter DATA_WIDTH = 64)
(
    input  logic clk,
    input  logic rst,
    input  logic valid_in,
    input  logic [1:0] channel_in,
    input  logic signed [DATA_WIDTH-1:0] idct_in [7:0],
    output logic signed [DATA_WIDTH-1:0] idct_out [7:0],
    output logic [1:0] channel_out,
    output logic valid_out
);

    logic signed [DATA_WIDTH-1:0] x [0:9];
    logic signed [DATA_WIDTH-1:0] y [0:9];
    logic signed [DATA_WIDTH-1:0] z [0:9];
    logic signed [DATA_WIDTH-1:0] w [0:9];
    logic signed [DATA_WIDTH-1:0] a [0:9];
    logic signed [DATA_WIDTH-1:0] b [0:9];
    logic signed [DATA_WIDTH-1:0] c [0:9];
    logic signed [DATA_WIDTH-1:0] d [7:0];
    logic signed [DATA_WIDTH-1:0] e [7:0];

    logic [1:0] ch_1, ch_2, ch_3, ch_4, ch_5, ch_6, ch_7, ch_8;
    logic v_1, v_2, v_3, v_4, v_5, v_6, v_7, v_8;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 8; i++) x[i] <= '0;
            ch_1 <= 0;
            v_1 <= 0;
        end else begin
            x[0] <= idct_in[0];
            x[1] <= idct_in[4];
            x[2] <= idct_in[2];
            x[3] <= idct_in[6];
            x[4] <= idct_in[7];
            x[5] <= ((idct_in[3] << 8) + (idct_in[3] << 6) + (idct_in[3] << 5) + (idct_in[3] << 3) + (idct_in[3] << 1));
            x[6] <= ((idct_in[5] << 8) + (idct_in[5] << 6) + (idct_in[5] << 5) + (idct_in[5] << 3) + (idct_in[5] << 1));
            x[7] <= idct_in[1];
            ch_1 <= channel_in;
            v_1 <= valid_in;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            y <= '{default: '0};
            ch_2 <= 0;
            v_2 <= 0;
        end else begin
            y[0] <= x[0];
            y[1] <= x[1];
            y[5] <= x[5];
            y[6] <= x[6];
            y[8] <= x[2] + x[3];
            y[4] <= (x[7] - x[4]) << 8;
            y[7] <= (x[7] + x[4]) << 8;
            y[2] <= ((x[3] << 9) - (x[3] << 6) + (x[3] << 4) + (x[3] << 3) + x[3]);
            y[3] <= ((x[2] << 7) + (x[2] << 6) + (x[2] << 2));
            ch_2 <= ch_1;
            v_2 <= v_1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            z <= '{default: '0};
            ch_3 <= 0;
            v_3 <= 0;
        end else begin
            z[0] <= y[0];
            z[1] <= y[1];
            z[2] <= y[2];
            z[3] <= y[3];
            z[4] <= y[4] + y[6];
            z[5] <= y[7] - y[5];
            z[6] <= y[4] - y[6];
            z[7] <= y[7] + y[5];
            z[8] <= ((y[8] << 7) + (y[8] << 3) + (y[8] << 1) + y[8]);
            ch_3 <= ch_2;
            v_3 <= v_2;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            w <= '{default: '0};
            ch_4 <= 0;
            v_4 <= 0;
        end else begin
            w[0] <= z[0];
            w[1] <= z[1];
            w[5] <= z[5];
            w[6] <= z[6];
            w[2] <= z[8] - z[2];
            w[3] <= z[8] + z[3];
            w[8] <= z[4] + z[7];
            w[7] <= (-(z[4] << 6) - (z[4] << 3) + z[4]);
            w[4] <= ((z[7] << 8) + (z[7] << 6) + (z[7] << 5) + (z[7] << 1) + z[7]);
            ch_4 <= ch_3;
            v_4 <= v_3;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            a <= '{default: '0};
            ch_5 <= 0;
            v_5 <= 0;
        end else begin
            a[0] <= w[0];
            a[1] <= w[1];
            a[2] <= w[2];
            a[3] <= w[3];
            a[4] <= w[4];
            a[7] <= w[7];
            a[8] <= w[8];
            a[9] <= w[5] + w[6];
            a[5] <= ((w[6] << 8) + (w[6] << 5) + (w[6] << 3) + (w[6] << 2) + w[6]);
            a[6] <= (-(w[5] << 8) + (w[5] << 5) + (w[5] << 4) + (w[5] << 3) - w[5]);
            ch_5 <= ch_4;
            v_5 <= v_4;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            b <= '{default: '0};
            ch_6 <= 0;
            v_6 <= 0;
        end else begin
            b[0] <= a[0] + a[1];
            b[1] <= a[0] - a[1];
            b[2] <= a[2] >>> 8;
            b[3] <= a[3] >>> 8;
            b[4] <= a[4];
            b[5] <= a[5];
            b[6] <= a[6];
            b[7] <= a[7];
            b[8] <= ((a[8] << 7) + (a[8] << 6) + (a[8] << 4) + (a[8] << 2) + a[8]);
            b[9] <= ((a[9] << 8) - (a[9] << 3) + (a[9] << 1) + a[9]);
            ch_6 <= ch_5;
            v_6 <= v_5;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            c <= '{default: '0};
            ch_7 <= 0;
            v_7 <= 0;
        end else begin
            c[0] <= b[0] + b[3];
            c[1] <= b[1] + b[2];
            c[2] <= b[1] - b[2];
            c[3] <= b[0] - b[3];
            c[4] <= (b[8] - b[4]) >>> 16;
            c[5] <= (b[9] - b[5]) >>> 16;
            c[6] <= (b[9] + b[6]) >>> 16;
            c[7] <= (b[8] + b[7]) >>> 16;
            ch_7 <= ch_6;
            v_7 <= v_6;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            d <= '{default: '0};
            ch_8 <= 0;
            v_8 <= 0;
        end else begin
            d[0] <= c[0] + c[7];
            d[1] <= c[1] + c[6];
            d[2] <= c[2] + c[5];
            d[3] <= c[3] + c[4];
            d[4] <= c[3] - c[4];
            d[5] <= c[2] - c[5];
            d[6] <= c[1] - c[6];
            d[7] <= c[0] - c[7];
            ch_8 <= ch_7;
            v_8 <= v_7;
        end
    end

    assign idct_out = d;
    assign channel_out = ch_8;
    assign valid_out = v_8;

endmodule
