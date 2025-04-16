module 4ptFFT(
    input logic signed [7:0] x_r [3:0],
    input logic signed [7:0] x_i [3:0],
    output logic signed [7:0] Xout_r [3:0],
    output logic signed [7:0] Xout_i [3:0]);

    logic signed [7:0] twiddles_r [3:0] = {8'sd1,8'sd1,8'sd1,8'sd1};
    logic signed [7:0] twiddles_i [3:0] = {8'sd1,8'sd1,8'sd1,8'sd1};

    //Instances
    butterfly s1r1(.xe_r(),.xe_i(),.xo_r(),.xo_i(),.twiddle_r(),.twiddle_i(),.Xlower_r(),.Xlower_i(),.Xupper_r(),.Xupper_i());
    butterfly s1r2(.xe_r(),.xe_i(),.xo_r(),.xo_i(),.twiddle_r(),.twiddle_i(),.Xlower_r(),.Xlower_i(),.Xupper_r(),.Xupper_i());
    butterfly s2r1(.xe_r(),.xe_i(),.xo_r(),.xo_i(),.twiddle_r(),.twiddle_i(),.Xlower_r(),.Xlower_i(),.Xupper_r(),.Xupper_i());
    butterfly s2r2(.xe_r(),.xe_i(),.xo_r(),.xo_i(),.twiddle_r(),.twiddle_i(),.Xlower_r(),.Xlower_i(),.Xupper_r(),.Xupper_i());

endmodule
