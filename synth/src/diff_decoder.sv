`include "sys_defs.svh"

module diff_decoder (
    input logic clk, rst,
    input logic signed [11:0] value_in,
    input logic freq,
    input logic [$clog2(`CH+1)-1:0] ch,
    output logic signed [11:0] value_out
);

logic signed [`CH-1:0][11:0] prev_value_n, prev_value;

always_comb begin
    prev_value_n = prev_value;
    value_out = value_in;
    if (!freq) begin // DC
        value_out = value_in + prev_value[ch];
        prev_value_n[ch] = value_out;
    end 
end

always_ff @(posedge clk) begin
    if (rst) prev_value <= 0;
    else prev_value <= prev_value_n;
end

endmodule
