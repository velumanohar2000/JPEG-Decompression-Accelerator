`include "sys_defs.svh"

module top_tb;

    // Inputs
    logic clk, rst;
    logic [`IN_BUS_WIDTH-1:0] data_in;
    logic valid_in;
    HUFF_PACKET hp;
    QUANT_PACKET qp;

    // Outputs
    logic request;
    logic [7:0] r [7:0][7:0];
    logic [7:0] g [7:0][7:0];
    logic [7:0] b [7:0][7:0];
    logic valid_out_Color;

    // Image info
    string img_filename;
    integer img_file_handle, scan_result;
    real img_height, img_width;
    integer horizontal_blocks, vertical_blocks;

    // File handles
    integer file_ptr, r_file, g_file, b_file;
    integer scan_len, curr_row, tab_idx;
    integer processed_cnt = 0;

    // Clock generation
    always #(`PERIOD/2) clk = ~clk;

    // Instantiate DUT
    jpeg_decoder_top dut (
        .clk, .rst,
        .data_in, .valid_in,
        .hp, .qp,
        .request,
        .r, .g, .b,
        .valid_out_Color
    );

    //------------------------------//
    // INITIALIZATION AND LOADING
    //------------------------------//
    initial begin
        // Get image name from file
        img_file_handle = $fopen("../python/imageName.txt", "r");
        scan_result = $fscanf(img_file_handle, "%s\n", img_filename);
        $display("Running top_tb on: %s", img_filename);

        // Load header info
        file_ptr = $fopen({"../python/out/", img_filename, "/HeaderInfo.txt"}, "r");
        $fscanf(file_ptr, "%f,%f\n", img_height, img_width);
        horizontal_blocks = $ceil(img_width / 16.0) * 2;
        vertical_blocks   = $ceil(img_height / 16.0) * 2;

        // Initialize clocked inputs
        clk = 0;
        rst = 1;
        valid_in = 0;
        data_in = 0;

        repeat (2) @(posedge clk);
        rst = 0;

        // Load quantization tables
        load_quant_table(0, {"../python/out/", img_filename, "/QuantTable0.txt"});
        load_quant_table(1, {"../python/out/", img_filename, "/QuantTable1.txt"});

        // Set quant table map
        qp.map[0] = 0;
        qp.map[1] = 1;
        qp.map[2] = 1;

        // Load huffman tables
        hp.map[0] = 0;
        hp.map[1] = 1;
        hp.map[2] = 1;

        load_dc_table(0, {"../python/out/", img_filename, "/DC_HuffTable_Index0Flipped.txt"});
        load_dc_table(1, {"../python/out/", img_filename, "/DC_HuffTable_Index1Flipped.txt"});
        load_ac_table(0, {"../python/out/", img_filename, "/AC_HuffTable_Index0Flipped.txt"});
        load_ac_table(1, {"../python/out/", img_filename, "/AC_HuffTable_Index1Flipped.txt"});

        // Open output image RGB files
        r_file = $fopen({"out/", img_filename, "_R.txt"}, "w");
        g_file = $fopen({"out/", img_filename, "_G.txt"}, "w");
        b_file = $fopen({"out/", img_filename, "_B.txt"}, "w");

        //------------------------------//
        // PROCESS BITSTREAM
        //------------------------------//
        file_ptr = $fopen({"../python/out/", img_filename, "/bitStreamFlipped.txt"}, "r");
        scan_len = -1;

        while (!$feof(file_ptr)) begin
            @(negedge clk);
            valid_in = request ? $fscanf(file_ptr, "%b\n", data_in) == 1 : 0;

            if (valid_out_Color) begin
                output_block_data;
                processed_cnt++;
            end
        end

        // Finish pending color blocks
        while (processed_cnt < vertical_blocks * horizontal_blocks) begin
            @(negedge clk);
            valid_in = request;
            if (valid_out_Color) begin
                output_block_data;
                processed_cnt++;
            end
        end

        // Cleanup
        $fclose(r_file);
        $fclose(g_file);
        $fclose(b_file);
        $finish;
    end

    //------------------------------//
    // TASKS
    //------------------------------//

    task load_quant_table(input int idx, input string path);
        file_ptr = $fopen(path, "r");
        curr_row = 0;
        while (!$feof(file_ptr)) begin
            $fscanf(file_ptr, "%d, %d, %d, %d, %d, %d, %d, %d\n",
                qp.tabs[idx].tab[curr_row][0], qp.tabs[idx].tab[curr_row][1],
                qp.tabs[idx].tab[curr_row][2], qp.tabs[idx].tab[curr_row][3],
                qp.tabs[idx].tab[curr_row][4], qp.tabs[idx].tab[curr_row][5],
                qp.tabs[idx].tab[curr_row][6], qp.tabs[idx].tab[curr_row][7]);
            curr_row++;
        end
        $fclose(file_ptr);
    endtask

    task load_dc_table(input int table_num, input string path);
        file_ptr = $fopen(path, "r");
        hp.tabs[table_num].dc_tab = 0;
        tab_idx = 0;
        $fscanf(file_ptr, "%d\n", hp.tabs[table_num].dc_size);
        while (!$feof(file_ptr)) begin
            $fscanf(file_ptr, "%b %d %d\n",
                hp.tabs[table_num].dc_tab[tab_idx].code,
                hp.tabs[table_num].dc_tab[tab_idx].symbol,
                hp.tabs[table_num].dc_tab[tab_idx].size);
            tab_idx++;
        end
        $fclose(file_ptr);
    endtask

    task load_ac_table(input int table_num, input string path);
        file_ptr = $fopen(path, "r");
        hp.tabs[table_num].ac_tab = 0;
        tab_idx = 0;
        $fscanf(file_ptr, "%d\n", hp.tabs[table_num].ac_size);
        while (!$feof(file_ptr)) begin
            $fscanf(file_ptr, "%b %d %d\n",
                hp.tabs[table_num].ac_tab[tab_idx].code,
                hp.tabs[table_num].ac_tab[tab_idx].symbol,
                hp.tabs[table_num].ac_tab[tab_idx].size);
            tab_idx++;
        end
        $fclose(file_ptr);
    endtask

    task output_block_data;
        for (int row = 0; row < 8; row++) begin
            for (int col = 0; col < 8; col++) $fwrite(r_file, "%d ", r[row][col]);
            $fwrite(r_file, "\n");
        end
        for (int row = 0; row < 8; row++) begin
            for (int col = 0; col < 8; col++) $fwrite(g_file, "%d ", g[row][col]);
            $fwrite(g_file, "\n");
        end
        for (int row = 0; row < 8; row++) begin
            for (int col = 0; col < 8; col++) $fwrite(b_file, "%d ", b[row][col]);
            $fwrite(b_file, "\n");
        end
    endtask

endmodule
