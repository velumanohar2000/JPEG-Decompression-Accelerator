`include "sys_defs.svh"

module unzigzag(
    input logic [`BLOCK_BUFF_SIZE-1:0][11:0] line,
    output logic signed [11:0] block [7:0][7:0]
);

logic [3:0] r_lut [0:63] = {
    4'd0, 4'd0, 4'd1, 4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd3, 
    4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd5, 4'd4, 
    4'd3, 4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 
    4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 
    4'd7, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd7, 4'd6, 
    4'd5, 4'd6, 4'd7, 4'd7
};

logic [3:0] c_lut [0:63] = {
    4'd0, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 4'd3, 4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 
    4'd2, 4'd3, 4'd4, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd0, 4'd0, 4'd1, 4'd2, 
    4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1, 4'd0, 
    4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 
    4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd7, 4'd6, 4'd5, 4'd4, 4'd5, 4'd6, 
    4'd7, 4'd7, 4'd6, 4'd7
};

always_comb begin
    for (int i = 0; i < 64; ++i) begin
        block[r_lut[i]][c_lut[i]] = line[i];
    end
end

endmodule

