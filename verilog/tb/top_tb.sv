module top_tb;
    //Inputs
    logic clk, rst;
    logic [`IN_BUS_WIDTH-1:0] data_in;
    logic valid_in;
    HUFF_PACKET hp;
    QUANT_PACKET qp;
    //Outputs
    logic request;
    logic unsigned [7:0] r [7:0][7:0];
    logic unsigned [7:0] g [7:0][7:0];
    logic unsigned [7:0] b [7:0][7:0];
    logic valid_out_Color;

    /* Automatically load image name */
    string img_filename;
    integer img_file_handle, scan_result;
    initial begin
        img_file_handle = $fopen("../python/imageName.txt", "r");
        scan_result = $fscanf(img_file_handle, "%s\n", img_filename);
        $display({"Running top_tb on: ", img_filename});
    end
     /* Or set image name manually */
    //string img_filename = "smallCat";

    ////////////////////////////////////////////////////////////////////////////

    //Instantiate Top module
    jpeg_decoder_top dut (
        .clk, 
        .rst,
        .data_in,
        .valid_in,
        .hp,
        .qp,
        .request,
        .r,
        .g,
        .b,
        .valid_out_Color
    );

    integer file_ptr, scan_len;
    integer curr_row, tab_idx;
    integer processed_cnt = 0;
    integer r_file, g_file, b_file;
    real img_height, img_width; 
    integer vertical_blocks, horizontal_blocks;

    always #(`PERIOD/2) clk = ~clk;

    initial begin
        //Load Header info
        file_ptr = $fopen({"../python/out/", img_filename, "/HeaderInfo.txt"}, "r");
        scan_len = $fscanf(file_ptr, "%d,%d\n", img_height, img_width);
        horizontal_blocks = $ceil(img_width/16.0)*2;
        vertical_blocks = $ceil(img_height/16.0)*2;
        // $display(horizontal_blocks);
        // $display(vertical_blocks);

        //Load quantization tables into quant packet
        qp.map[0] = 0;
        qp.map[1] = 1;
        qp.map[2] = 1;

        file_ptr = $fopen({"../python/out/", img_filename, "/QuantTable0.txt"}, "r");
        curr_row = 0;
        while(!$feof(file_ptr)) begin
            scan_len = $fscanf(file_ptr, "%d, %d, %d, %d, %d, %d, %d, %d\n",
            qp.tabs[0].tab[curr_row][0], qp.tabs[0].tab[curr_row][1],
            qp.tabs[0].tab[curr_row][2], qp.tabs[0].tab[curr_row][3],
            qp.tabs[0].tab[curr_row][4], qp.tabs[0].tab[curr_row][5],
            qp.tabs[0].tab[curr_row][6], qp.tabs[0].tab[curr_row][7]);
            curr_row = curr_row + 1;
        end

        file_ptr = $fopen({"../python/out/", img_filename, "/QuantTable1.txt"}, "r");
        curr_row = 0;
        while(!$feof(file_ptr)) begin
            scan_len = $fscanf(file_ptr, "%d, %d, %d, %d, %d, %d, %d, %d\n",
            qp.tabs[1].tab[curr_row][0], qp.tabs[1].tab[curr_row][1],
            qp.tabs[1].tab[curr_row][2], qp.tabs[1].tab[curr_row][3],
            qp.tabs[1].tab[curr_row][4], qp.tabs[1].tab[curr_row][5],
            qp.tabs[1].tab[curr_row][6], qp.tabs[1].tab[curr_row][7]);
            curr_row = curr_row + 1;
        end

        //Load huffman tables into huff packet
        hp.map[0] = 0;
        hp.map[1] = 1;
        hp.map[2] = 1;

        load_dc_table(0, {"../python/out/", img_filename, "/DC_HuffTable_Index0Flipped.txt"});
        load_dc_table(1, {"../python/out/", img_filename, "/DC_HuffTable_Index1Flipped.txt"});
        load_ac_table(0, {"../python/out/", img_filename, "/AC_HuffTable_Index0Flipped.txt"});
        load_ac_table(1, {"../python/out/", img_filename, "/AC_HuffTable_Index1Flipped.txt"});

        // initial values
        clk = 0;
        rst = 1;
        valid_in = 0;
        data_in = 0;
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        r_file = $fopen({"out/", img_filename, "_R.txt"}, "w");
        g_file = $fopen({"out/", img_filename, "_G.txt"}, "w");
        b_file = $fopen({"out/", img_filename, "_B.txt"}, "w");

        file_ptr = $fopen({"../python/out/", img_filename, "/bitStreamFlipped.txt"}, "r");
        scan_len = -1;
        while(!$feof(file_ptr)) begin
            @(negedge clk);
            if (request) begin
                scan_len = $fscanf(file_ptr, "%b\n", data_in);
                valid_in = 1;
            end else begin
                valid_in = 0;
            end
            if (valid_out_Color) begin
                output_block_data;
                processed_cnt += 1;
            end
        end

        while (processed_cnt < vertical_blocks*horizontal_blocks) begin
            @(negedge clk);
            if (request) begin
                valid_in = 1;
            end else begin
                valid_in = 0;
            end
            if (valid_out_Color) begin
                output_block_data;
                processed_cnt += 1;
            end
        end

        $fclose(r_file);
        $fclose(g_file);
        $fclose(b_file);

        $finish; 
    end

    // Combined function to load DC huffman tables
    task load_dc_table(input integer table_num, input string filepath);
        file_ptr = $fopen(filepath, "r");
        scan_len = -1;
        hp.tabs[table_num].dc_tab = 0;
        tab_idx = 0;
        scan_len = $fscanf(file_ptr, "%d\n", hp.tabs[table_num].dc_size);
        while(!$feof(file_ptr)) begin
           scan_len = $fscanf(file_ptr, "%b %d %d\n", hp.tabs[table_num].dc_tab[tab_idx].code,
                    hp.tabs[table_num].dc_tab[tab_idx].symbol, hp.tabs[table_num].dc_tab[tab_idx].size);
            tab_idx = tab_idx + 1;
        end
    endtask

    // Combined function to load AC huffman tables
    task load_ac_table(input integer table_num, input string filepath);
        file_ptr = $fopen(filepath, "r");
        scan_len = -1;
        hp.tabs[table_num].ac_tab = 0;
        tab_idx = 0;
        scan_len = $fscanf(file_ptr, "%d\n", hp.tabs[table_num].ac_size);
        while(!$feof(file_ptr)) begin
           scan_len = $fscanf(file_ptr, "%b %d %d\n", hp.tabs[table_num].ac_tab[tab_idx].code,
                    hp.tabs[table_num].ac_tab[tab_idx].symbol, hp.tabs[table_num].ac_tab[tab_idx].size);
            tab_idx = tab_idx + 1;
        end
    endtask

    task output_block_data;
        for (int row = 0; row < 8; row++) begin
            for (int col = 0; col < 8; col++) begin
                $fwrite(r_file, "%d ", r[row][col]);
            end
            $fwrite(r_file, "\n");
        end

        for (int row = 0; row < 8; row++) begin
            for (int col = 0; col < 8; col++) begin
                $fwrite(g_file, "%d ", g[row][col]);
            end
            $fwrite(g_file, "\n");
        end

        for (int row = 0; row < 8; row++) begin
            for (int col = 0; col < 8; col++) begin
                $fwrite(b_file, "%d ", b[row][col]);
            end
            $fwrite(b_file, "\n");
        end
    endtask

endmodule