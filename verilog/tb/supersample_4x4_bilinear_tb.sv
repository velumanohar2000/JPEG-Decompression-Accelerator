module supersample_4x4_bilinear_tb ();

    // DUT interface signals
    logic        valid_in;
    logic [7:0]  block_in [3:0][3:0];
    logic [7:0]  block_out [7:0][7:0];
    logic        valid_out;

    // Instantiate DUT
    supersample_4x4_bilinear dut (
        .valid_in(valid_in),
        .block_in(block_in),
        .block_out(block_out),
        .valid_out(valid_out)
    );

    // Test input
    initial begin
        // Initialize inputs
        valid_in = 0;
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                block_in[i][j] = i * 4 + j; // simple ascending pattern: 0, 1, 2, ..., 15
            end
        end

        // Wait some time then assert valid
        #10;
        valid_in = 1;

        // Wait for output to stabilize
        #10;

        $display("==== Input 8x8 block ====");
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                $write("%3d ", block_in[i][j]);
            end
            $write("\n");
        end

        // Print result
        $display("==== Output 8x8 block ====");
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                $write("%3d ", block_out[i][j]);
            end
            $write("\n");
        end

        $display("Valid out: %b", valid_out);
        $finish;
    end

endmodule
