`include "segmented_raw.svh"
`include "sys_defs.svh"

module header_reader_tb;

    logic clk;
    logic rst;
    logic [31:0] data_in;
    logic jpeg_valid;
    logic found_cutoff;
    logic found_app0;

    // Instantiate header_reader explicitly
    header_reader uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .jpeg_valid(jpeg_valid),
        .found_cutoff(found_cutoff),
        .found_app0(found_app0)
    );

    // Variables explicitly defined
    int word_idx;

    // Clock generation explicitly (100 MHz)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        word_idx = 0;

        #20; 
        rst = 0;

        // Scan explicitly for SOI marker detection
        for (word_idx = 0; word_idx < `DATA_SEGMENTS; word_idx++) begin

            data_in = jpeg_raw[word_idx];
            @(posedge clk);
            if (jpeg_valid) begin
                $display("✅ SOI Marker detected at word_idx = %0d, time = %0t ns", word_idx, $time);
                break;
            end
        end

        if (!jpeg_valid) begin
            $display("❌ ERROR: SOI Marker not found.");
            $finish;
        end

        // Scan explicitly for APP0 marker detection
        for (; word_idx < `DATA_SEGMENTS; word_idx++) begin
            data_in = jpeg_raw[word_idx];
            @(posedge clk);
            if (found_app0) begin
                $display("📌 APP0 Marker detected at word_idx = %0d, time = %0t ns", word_idx, $time);
                break;
            end
        end

        if (!found_app0) begin
            $display("❌ ERROR: APP0 Marker not found.");
            $finish;
        end

        // Now explicitly continue scanning for next markers (DQT, DHT, SOF0)
        for (; word_idx < `DATA_SEGMENTS; word_idx++) begin
            @(posedge clk);

            data_in = jpeg_raw[word_idx];
            $display("!!!Data_in for this cycle is %h @ time: %0t", data_in, $time);

            // FSM state transitions are explicitly printed internally; detect using simulation outputs
        end

        // If we reach this point explicitly, no further markers were detected.
        $display("⚠️ Reached end of data without detecting DQT, DHT, or SOF0 markers.");

        #20;
        $finish;
    end

endmodule
