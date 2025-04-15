`include "sys_defs.svh"

module zigzag(
    input  logic                 clk,
    input  logic                 reset,
    input  logic signed [`Q-1:0] quantized    [7:0][7:0],
    output logic signed [`Q-1:0] quantized_zz [63:0]
);

logic signed [3:0] r_lut [0:63] = {
    4'd0, 4'd0, 4'd1, 4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd3, 
    4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd5, 4'd4, 
    4'd3, 4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 
    4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 
    4'd7, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd7, 4'd6, 
    4'd5, 4'd6, 4'd7, 4'd7
};

logic signed [3:0] c_lut [0:63] = {
    4'd0, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 4'd3, 4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 
    4'd2, 4'd3, 4'd4, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 
    4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd0, 
    4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 
    4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd7, 4'd6, 4'd5, 4'd4, 4'd5, 4'd6, 
    4'd7, 4'd7, 4'd6, 4'd7
};

always_comb begin
    for (int i = 0; i < 64; ++i) begin
        quantized_zz[i] = quantized[r_lut[i]][c_lut[i]];
    end
end

endmodule

