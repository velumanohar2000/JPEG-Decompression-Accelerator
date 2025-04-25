`include "segmented_raw.svh"
`include "sys_defs.svh"

`define DEBUG

`define AXI_BYTES 4
// JPEG DQT segment thresholds for 8-bit precision tables (Pq = 0)
`define DQT_LEN_1_TABLE 16'h0043  // 2 + 1×65 = 67 bytes total
`define DQT_LEN_2_TABLES 16'h0084 // 2 + 2×65 = 132 bytes total
`define DQT_LEN_3_TABLES 16'h00C5 // 2 + 3×65 = 197 bytes total
`define DQT_LEN_4_TABLES 16'h0106 // 2 + 4×65 = 262 bytes total (max allowed by JPEG standard)

typedef struct packed {
    logic [15:0] len;
    logic [7:0]  precision;
    logic [15:0] image_height;
    logic [15:0] image_width;
    logic [7:0]  num_components;
    struct packed {
        logic [7:0] id;
        logic [7:0] sampling_factors;
        logic [7:0] quant_tbl_idx;
    } [2:0] components; // ✅ Packed array, fixed definition
} SOF0_PACKET;

typedef enum logic [3:0] {
    BLANK  = 4'd0,
    SOI    = 4'd1,
    CUTOFF = 4'd2,
    APP0   = 4'd3,
    DQT    = 4'd4,
    SOF0   = 4'd5,
    DHT    = 4'd6,
    SOS    = 4'd7,
    EOI    = 4'd8
} state_t;

`ifdef DEBUG
task display_gened_huff(input HUFF_TABLE gened_huff, input logic [7:0] DHT_info);
    $display("\n==== Generated Huffman Table (Class: %s, ID: %0d) ====", 
             DHT_info[4] ? "AC" : "DC", DHT_info[1:0]);

    // Display DC Huffman Table
    $display("\nDC Huffman Table (Size: %0d):", gened_huff.dc_size);
    $display("Length Options: %b", gened_huff.dc_length_opts);
    for (int i = 0; i < gened_huff.dc_size; i++) begin
        $display("[DC] Symbol: %3d | Size: %2d | Code: %016b", 
                 gened_huff.dc_tab[i].symbol, 
                 gened_huff.dc_tab[i].size,
                 gened_huff.dc_tab[i].code);
    end

    // Display AC Huffman Table
    $display("\nAC Huffman Table (Size: %0d):", gened_huff.ac_size);
    $display("Length Options: %b", gened_huff.ac_length_opts);
    for (int i = 0; i < gened_huff.ac_size; i++) begin
        $display("[AC] Symbol: %3d | Size: %2d | Code: %016b", 
                 gened_huff.ac_tab[i].symbol, 
                 gened_huff.ac_tab[i].size,
                 gened_huff.ac_tab[i].code);
    end
endtask

task print_quant_packet(input QUANT_PACKET qp);
    $display("📋 Quantization Table 0 (8x8):");
    for (int row = 0; row < 8; row++) begin
        for (int col = 0; col < 8; col++)
            $write("%3d ", qp.tabs[0].tab[row][col]);
        $write("\n");
    end
    $display("📋 Quantization Table 1 (8x8):");
    for (int row = 0; row < 8; row++) begin
        for (int col = 0; col < 8; col++)
            $write("%3d ", qp.tabs[1].tab[row][col]);
        $write("\n");
    end
endtask

task print_SOF0_out(input SOF0_PACKET fp);
    $display("📐 SOF0 Frame Packet Info:");
    $display(" - Length          : %0d bytes", fp.len);
    $display(" - Precision       : %0d bits", fp.precision);
    $display(" - Image Height    : %0d pixels", fp.image_height);
    $display(" - Image Width     : %0d pixels", fp.image_width);
    $display(" - Num Components  : %0d", fp.num_components);

    for (int i = 0; i < fp.num_components; i++) begin
        $display("  🔹 Component [%0d]:", i);
        $display("     - ID               : %0d", fp.components[i].id);
        $display("     - Sampling Factors : H: %0d, V: %0d", 
                fp.components[i].sampling_factors[7:4], 
                fp.components[i].sampling_factors[3:0]);
        $display("     - Quant Table ID   : %0d", fp.components[i].quant_tbl_idx);
    end
endtask

task print_transition(input state_t current_state, input state_t next_state);
    if (current_state != next_state) begin
        case (next_state)
            BLANK:  $display("🌑 Entered BLANK state at time %0t", $time);
            SOI:    $display("✅ Entered SOI state at time %0t", $time);
            CUTOFF: $display("⚠️ Entered CUTOFF state at time %0t", $time);
            APP0:   $display("📌 Entered APP0 state at time %0t", $time);
            DQT:    $display("📗 Entered DQT state at time %0t", $time);
            SOF0:   $display("📙 Entered SOF0 state at time %0t", $time);
            DHT:    $display("📘 Entered DHT state at time %0t", $time);
            SOS:    $display("📕 Entered SOS state at time %0t", $time);
            EOI:    $display("🏁 Entered EOI state at time %0t", $time);
            default:$display("🔴 Entered UNKNOWN state at time %0t", $time);
        endcase
    end
endtask


task display_huff_table(input HUFF_TABLE tb);
    $display("\n==== AC Huffman Table ====");
    $display("AC Size: %0d", tb.ac_size);
    $display("AC Length Opts (bit lengths used): %b", tb.ac_length_opts);

    for (int i = 0; i < tb.ac_size; i++) begin
        $display("AC Symbol: %3d | Size: %2d bits | Code: %016b", 
                 tb.ac_tab[i].symbol, 
                 tb.ac_tab[i].size, 
                 tb.ac_tab[i].code);
    end

    $display("\n==== DC Huffman Table ====");
    $display("DC Size: %0d", tb.dc_size);
    $display("DC Length Opts (bit lengths used): %b", tb.dc_length_opts);

    for (int i = 0; i < tb.dc_size; i++) begin
        $display("DC Symbol: %3d | Size: %2d bits | Code: %016b", 
                 tb.dc_tab[i].symbol, 
                 tb.dc_tab[i].size, 
                 tb.dc_tab[i].code);
    end
endtask
`endif

module header_reader (
    input  logic         clk,
    input  logic         rst,
    input  logic [31:0]  data_in,
    output logic         jpeg_valid,
    output logic         found_cutoff,
    output logic         found_app0,
    output QUANT_PACKET  DQT_out,           // ✅ New output in zigzag order
    output SOF0_PACKET   SOF0_out,
    output HUFF_PACKET   HUFF_out
);
    //We read into the table of DQT row order, then the zig zag is jut created with wiring and a generate loop
    localparam logic [5:0] zigzag_map [0:63] = '{
        0,  1,  5,  6, 14, 15, 27, 28,
        2,  4,  7, 13, 16, 26, 29, 42,
        3,  8, 12, 17, 25, 30, 41, 43,
        9, 11, 18, 24, 31, 40, 44, 53,
        10, 19, 23, 32, 39, 45, 52, 54,
        20, 22, 33, 38, 46, 51, 55, 60,
        21, 34, 37, 47, 50, 56, 59, 61,
        35, 36, 48, 49, 57, 58, 62, 63
    };

    //Generate loop for zig zaging the DQT packet
    genvar t, i;
    generate
        for (t = 0; t < `QN; t++) begin : TABLE_LOOP
            for (i = 0; i < 64; i++) begin : ZIGZAG_LOOP
                localparam [2:0] row_in = zigzag_map[i] >> 3;
                localparam [2:0] col_in = zigzag_map[i] & 3'b111;
                assign DQT_out.tabs[t].tab[i >> 3][i & 3'b111] =
                    quant_packet.tabs[t].tab[row_in][col_in];
           
            end
        end
    endgenerate



    state_t state, next_state;

    logic [`AXI_BYTES-1:0] soi_marker_status, app0_marker_status, dqt_marker_status, dht_marker_status, sof0_marker_status,sos_marker_status, eoi_marker_status, stuffing_marker_status;
    logic [15:0] DQT_len;
    logic [2:0] DQT_seg_tbl_num;

    logic [7:0]  DQT_info;
    logic [3:0]  saved_marker_status;
    logic [6:0]  DQT_fill_idx;
    logic [2:0]  DQT_fill_offset;
    logic [31:0] last_data_in;
    logic [7:0] SOF0_buffer [0:31]; // 32-byte buffer
    logic [6:0] SOF0_byte_cnt;

  

    logic [15:0] DHT_len;                          // Segment length (JPEG header info)
    logic [7:0]  DHT_info;                         // Huffman Table Class and ID byte
    logic [8:0]  DHT_sym_ttl;                        // Total number of symbols
    logic [7:0]  DHT_code_counts [1:16];           // Number of codes for each bit-length (1-16)
    logic [7:0]  DHT_len_offsets [1:16];           // This is a set of offsets that will mark in a large buffer where symbols of a certain length 1:16 start
    logic [7:0]  DHT_sym_buffer [0:255];           // Symbol buffer built up and then converted into the huff table format.
    logic [5:0]  DHT_len_byte_cnt;                     // Position in reading code counts (0-15)
    logic [8:0]  DHT_sym_byte_cnt;                 //Where we are in the large symbol buffer
    logic [8:0]  DHT_inc_sum;                      // To build up the offset locatiosn for each code elngth I require this 
    logic [7:0]  prior_byte;


    // Parsed Table Class/ID (for clarity)
    logic        DHT_class;                        // 0 = DC, 1 = AC
    logic [1:0]  DHT_id;                           // Huffman table ID (0-3)
    logic [15:0] code;
    int sym_idx;
    logic [7:0]  SOS_stuffer[3:0];
    logic [7:0]  SOS_buffer [15:0];
    logic [3:0]  SOS_head;
    logic [3:0]  SOS_tail;
    logic [3:0]  SOS_diff;
    logic [31:0] SOS_to_fifo;

    HUFF_TABLE gened_huff;
    QUANT_PACKET quant_packet;
    HUFF_PACKET  huff_packet;

    assign SOF0_out.len             = {SOF0_buffer[0], SOF0_buffer[1]};
    assign SOF0_out.precision       = SOF0_buffer[2];
    assign SOF0_out.image_height    = {SOF0_buffer[3], SOF0_buffer[4]};
    assign SOF0_out.image_width     = {SOF0_buffer[5], SOF0_buffer[6]};
    assign SOF0_out.num_components  = SOF0_buffer[7];

    assign SOF0_out.components[0].id                = SOF0_buffer[8];
    assign SOF0_out.components[0].sampling_factors  = SOF0_buffer[9];
    assign SOF0_out.components[0].quant_tbl_idx     = SOF0_buffer[10];

    assign SOF0_out.components[1].id                = SOF0_buffer[11];
    assign SOF0_out.components[1].sampling_factors  = SOF0_buffer[12];
    assign SOF0_out.components[1].quant_tbl_idx     = SOF0_buffer[13];

    assign SOF0_out.components[2].id                = SOF0_buffer[14];
    assign SOF0_out.components[2].sampling_factors  = SOF0_buffer[15];
    assign SOF0_out.components[2].quant_tbl_idx     = SOF0_buffer[16];

    assign DHT_class = DHT_info[4];    // 0=DC, 1=AC
    assign DHT_id    = DHT_info[1:0];  // Table ID (0-3)
    assign HUFF_out = huff_packet;

    always_comb begin
                    // Assign Huffman codes implicitly without explicit offsets
        code = 16'd0;
        sym_idx = 0;


        if (DHT_class == 1'b1) begin  // AC Huffman table
            gened_huff.ac_size = DHT_code_counts[1] + DHT_code_counts[2] + DHT_code_counts[3] + DHT_code_counts[4] + 
                DHT_code_counts[5] + DHT_code_counts[6] + DHT_code_counts[7] + DHT_code_counts[8] + 
                DHT_code_counts[9] + DHT_code_counts[10] + DHT_code_counts[11] + DHT_code_counts[12] +
                DHT_code_counts[13] + DHT_code_counts[14] + DHT_code_counts[15] + DHT_code_counts[16];
            gened_huff.ac_length_opts <= {|DHT_code_counts[1],  |DHT_code_counts[2],  |DHT_code_counts[3],  |DHT_code_counts[4],
                |DHT_code_counts[5],  |DHT_code_counts[6],  |DHT_code_counts[7],  |DHT_code_counts[8],
                |DHT_code_counts[9],  |DHT_code_counts[10], |DHT_code_counts[11], |DHT_code_counts[12],
                |DHT_code_counts[13], |DHT_code_counts[14], |DHT_code_counts[15], |DHT_code_counts[16]};
            for (int bit_len = 1; bit_len <= 16; bit_len++) begin
                for (int count = 0; count < DHT_code_counts[bit_len]; count++) begin
                    gened_huff.ac_tab[sym_idx].code   = code;
                    gened_huff.ac_tab[sym_idx].size   = bit_len[4:0];
                    gened_huff.ac_tab[sym_idx].symbol = DHT_sym_buffer[sym_idx];
                    code = code + 1;
                    sym_idx = sym_idx + 1;
                end
                code = code << 1;
            end
        end else begin                // DC Huffman table
            gened_huff.dc_size = DHT_code_counts[1] + DHT_code_counts[2] + DHT_code_counts[3] + DHT_code_counts[4] + 
                DHT_code_counts[5] + DHT_code_counts[6] + DHT_code_counts[7] + DHT_code_counts[8] + 
                DHT_code_counts[9] + DHT_code_counts[10] + DHT_code_counts[11] + DHT_code_counts[12] +
                DHT_code_counts[13] + DHT_code_counts[14] + DHT_code_counts[15] + DHT_code_counts[16];
            gened_huff.dc_length_opts <= {|DHT_code_counts[1],  |DHT_code_counts[2],  |DHT_code_counts[3],  |DHT_code_counts[4],
                |DHT_code_counts[5],  |DHT_code_counts[6],  |DHT_code_counts[7],  |DHT_code_counts[8],
                |DHT_code_counts[9],  |DHT_code_counts[10], |DHT_code_counts[11], |DHT_code_counts[12],
                |DHT_code_counts[13], |DHT_code_counts[14], |DHT_code_counts[15], |DHT_code_counts[16]};
            for (int bit_len = 1; bit_len <= 16; bit_len++) begin
                for (int count = 0; count < DHT_code_counts[bit_len]; count++) begin
                    gened_huff.dc_tab[sym_idx].code   = code;
                    gened_huff.dc_tab[sym_idx].size   = bit_len[4:0];
                    gened_huff.dc_tab[sym_idx].symbol = DHT_sym_buffer[sym_idx];
                    code = code + 1;
                    sym_idx = sym_idx + 1;
                end
                code = code << 1;
            end
        end
        // This combinatorilly builds the starting indices for the different code lengths 
        DHT_inc_sum = 0;
        for (int len = 1; len <= 16; len++) begin
            DHT_len_offsets[len] = DHT_inc_sum;
            DHT_inc_sum = DHT_inc_sum + DHT_code_counts[len];
        end
        // DQT_len includes 2-byte length field; each 8-bit table takes 65 bytes
        if (DQT_len >= `DQT_LEN_4_TABLES)
            DQT_seg_tbl_num = 3'd4;
        else if (DQT_len >= `DQT_LEN_3_TABLES)
            DQT_seg_tbl_num = 3'd3;
        else if (DQT_len >= `DQT_LEN_2_TABLES)
            DQT_seg_tbl_num = 3'd2;
        else if (DQT_len >= `DQT_LEN_1_TABLE)
            DQT_seg_tbl_num = 3'd1;
        else
            DQT_seg_tbl_num = 3'd0; // Invalid / malformed segment
        
        //Every marker has a four bit status bitfield that basicslly will not only tell me if the marker is seen but which location in the 32 input it is seen
        for (int i = 0; i < `AXI_BYTES; i++) begin
            case (i)
                0: begin
                    soi_marker_status[i]  = ({prior_byte, data_in[31:24]} == 16'hFFD8);
                    app0_marker_status[i] = ({prior_byte, data_in[31:24]} == 16'hFFE0);
                    dqt_marker_status[i]  = ({prior_byte, data_in[31:24]} == 16'hFFDB);
                    dht_marker_status[i]  = ({prior_byte, data_in[31:24]} == 16'hFFC4);
                    sof0_marker_status[i] = ({prior_byte, data_in[31:24]} == 16'hFFC0);
                    sos_marker_status[i]  = ({prior_byte, data_in[31:24]} == 16'hFFDA);
                    eoi_marker_status[i]  = ({prior_byte, data_in[31:24]} == 16'hFFD9);
                    stuffing_marker_status[i] = ({prior_byte, data_in[31:24]} == 16'hFF00);
                end
                1: begin
                    soi_marker_status[i]  = (data_in[15:0] == 16'hFFD8);
                    app0_marker_status[i] = (data_in[15:0] == 16'hFFE0);
                    dqt_marker_status[i]  = (data_in[15:0] == 16'hFFDB);
                    dht_marker_status[i]  = (data_in[15:0] == 16'hFFC4);
                    sof0_marker_status[i] = (data_in[15:0] == 16'hFFC0);
                    sos_marker_status[i]  = (data_in[15:0] == 16'hFFDA);
                    eoi_marker_status[i]  = (data_in[15:0] == 16'hFFD9);
                    stuffing_marker_status[i] = (data_in[15:0] == 16'hFF00);

                end
                2: begin
                    soi_marker_status[i]  = (data_in[23:8] == 16'hFFD8);
                    app0_marker_status[i] = (data_in[23:8] == 16'hFFE0);
                    dqt_marker_status[i]  = (data_in[23:8] == 16'hFFDB);
                    dht_marker_status[i]  = (data_in[23:8] == 16'hFFC4);
                    sof0_marker_status[i] = (data_in[23:8] == 16'hFFC0);
                    sos_marker_status[i]  = (data_in[23:8] == 16'hFFDA);
                    eoi_marker_status[i]  = (data_in[23:8] == 16'hFFD9);
                    stuffing_marker_status[i] = (data_in[23:8] == 16'hFF00);
                end
                3: begin
                    soi_marker_status[i]  = (data_in[31:16] == 16'hFFD8);
                    app0_marker_status[i] = (data_in[31:16] == 16'hFFE0);
                    dqt_marker_status[i]  = (data_in[31:16] == 16'hFFDB);
                    dht_marker_status[i]  = (data_in[31:16] == 16'hFFC4);
                    sof0_marker_status[i] = (data_in[31:16] == 16'hFFC0);
                    sos_marker_status[i]  = (data_in[31:16] == 16'hFFDA);
                    eoi_marker_status[i]  = (data_in[31:16] == 16'hFFD9);
                    stuffing_marker_status[i] = (data_in[31:16] == 16'hFF00);
                end
            endcase
        end
    end

    always_comb begin 
        next_state = state;
        case (state)
            BLANK: begin
                if ((|soi_marker_status) && (|app0_marker_status)) next_state = APP0;
                else if (|soi_marker_status) next_state = SOI;
                else if (data_in[7:0] == 8'hFF) next_state = CUTOFF;
            end
            SOI: begin
                if (|app0_marker_status) next_state = APP0;
                else if (data_in[7:0] == 8'hFF) next_state = CUTOFF;
            end
            CUTOFF: begin
                if (|app0_marker_status) next_state = APP0;
            end
            APP0: begin
                if (|dqt_marker_status) next_state = DQT;
                else if (|dht_marker_status) next_state = DHT;
                else if (|sof0_marker_status) next_state = SOF0;
            end
            DQT: begin
                if (|dqt_marker_status) next_state = DQT;
                else if (|dht_marker_status) next_state = DHT;
                else if (|sof0_marker_status) next_state = SOF0;
                else if (|sos_marker_status) next_state = SOS;
                else if (|eoi_marker_status) next_state = EOI;

            end
            DHT: begin
                if (|dqt_marker_status) next_state = DQT;
                else if (|dht_marker_status) next_state = DHT;
                else if (|sof0_marker_status) next_state = SOF0;
                else if (|sos_marker_status) next_state = SOS;
                else if (|eoi_marker_status) next_state = EOI;
                
            end
            SOF0: begin
                if (|dht_marker_status) next_state = DHT;
                else if (|dqt_marker_status) next_state = DQT;
                else if (|sos_marker_status) next_state = SOS;
            end
            default: next_state = state;
            
        endcase
    end

    always_ff @(posedge clk) begin

        if (rst) begin
            state <= BLANK;
            jpeg_valid <= 0;
            found_cutoff <= 0;
            found_app0 <= 0;
            DQT_len <= 0;
            DQT_info <= 0;
            DQT_fill_idx <= 0;
            DQT_fill_offset <= 0;
            quant_packet <= '{default:0};
            last_data_in <= 0;
            SOF0_buffer <= '{default:0};
            SOF0_byte_cnt <= '0;
            huff_packet <= '{default:0};
            DHT_len_byte_cnt <= '0;
            DHT_sym_byte_cnt <= '0;
            DHT_len <= '0;
            DHT_info <= '0;
            DHT_code_counts <= '{default:0};
            SOS_buffer <= '{default:0};
            SOS_head <= '0;
            SOS_tail <= '0;
            SOS_to_fifo <= '0;
            prior_byte <= '0;
        end else begin
            state <= next_state;
            last_data_in <= data_in;
            prior_byte <= last_data_in[7:0];

`ifdef DEBUG
            print_transition(state, next_state);
`endif
            if (!jpeg_valid && (next_state == SOI || next_state == APP0)) begin
                jpeg_valid <= 1'b1;
                $display("✅ SOI Marker found at time %0t", $time);
            end

            if (!found_app0 && next_state == APP0) begin
                found_app0 <= 1'b1;
                $display("📌 APP0 Marker (JFIF) found at time %0t", $time);
            end

            /* DQT HANDLING ---------------------------------------------------*/
            if (next_state == DQT && |dqt_marker_status) begin //First case are we entering DQT state fresh off a marker?
                saved_marker_status <= dqt_marker_status;
                case (dqt_marker_status)
                    4'b1000: begin // Marker at byte 3 (2 hangover bytes: length bytes)
                        DQT_len <= last_data_in[15:0];
                        DQT_info <= data_in[31:24];
                        quant_packet.tabs[data_in[27:24]].tab[0][0] <= data_in[23:16];
                        quant_packet.tabs[data_in[27:24]].tab[0][1] <= data_in[15:8];
                        quant_packet.tabs[data_in[27:24]].tab[0][2] <= data_in[7:0];
                        DQT_fill_idx <= 3;
                    end
                    4'b0100: begin // Marker at byte 2 (1 hangover byte: upper length byte)
                        DQT_len[15:8] <= last_data_in[7:0];
                        DQT_len[7:0]  <= data_in[31:24];
                        DQT_info      <= data_in[23:16];
                        quant_packet.tabs[data_in[19:16]].tab[0][0] <= data_in[15:8];
                        quant_packet.tabs[data_in[19:16]].tab[0][1] <= data_in[7:0];
                        DQT_fill_idx <= 2;
                    end
                    4'b0010: begin // Marker at byte 1 (no hangover, len/info in data_in)
                        DQT_len  <= data_in[31:16];
                        DQT_info <= data_in[15:8];
                        quant_packet.tabs[data_in[11:8]].tab[0][0] <= data_in[7:0];
                        DQT_fill_idx <= 1;
                    end
                    4'b0001: begin // Marker at byte 0 (3 hangover bytes: length & info)
                        DQT_len  <= last_data_in[23:8];
                        DQT_info <= last_data_in[7:0];
                        quant_packet.tabs[last_data_in[3:0]].tab[0][0] <= data_in[31:24];
                        quant_packet.tabs[last_data_in[3:0]].tab[0][1] <= data_in[23:16];
                        quant_packet.tabs[last_data_in[3:0]].tab[0][2] <= data_in[15:8];
                        quant_packet.tabs[last_data_in[3:0]].tab[0][3] <= data_in[7:0];
                        DQT_fill_idx <= 4;
                    end
                endcase
            end else if (state == DQT) begin 
`ifdef DEBUG
                print_quant_packet(DQT_out);
`endif
                // Continue filling the quant table 4 bytes per cycle
                quant_packet.tabs[DQT_info[3:0]].tab[DQT_fill_idx      >> 3][DQT_fill_idx      & 3'b111] <= data_in[31:24];
                quant_packet.tabs[DQT_info[3:0]].tab[(DQT_fill_idx+1) >> 3][(DQT_fill_idx+1) & 3'b111] <= data_in[23:16];
                quant_packet.tabs[DQT_info[3:0]].tab[(DQT_fill_idx+2) >> 3][(DQT_fill_idx+2) & 3'b111] <= data_in[15:8];
                quant_packet.tabs[DQT_info[3:0]].tab[(DQT_fill_idx+3) >> 3][(DQT_fill_idx+3) & 3'b111] <= data_in[7:0];

                //After filling four move the index up
                DQT_fill_idx <= DQT_fill_idx + 4;
                //If we get obove 60 we are nearly done with the table and we have to make sure we are handlign the break either between tables or between marker segments
                if (DQT_fill_idx >= 60) begin
                    //Some nuance here after a table is read in there could be upt to 3 more, and the shift based on the marker position changes because one byte is swallowed
                    //up by the DQT_info byte so I cheat by changing the marker offset (encoded by the saved marker) to get the right stuff
                    case (saved_marker_status) 
                        4'b1000: if (DQT_fill_idx == 63) begin
                            quant_packet.tabs[DQT_info[3:0]].tab[63 >> 3][63 & 3'b111] <= data_in[31:24];
                            if (DQT_fill_offset < DQT_seg_tbl_num) begin
                                DQT_fill_offset <= DQT_fill_offset + 1;
                                DQT_info <= data_in[23:16];

                                quant_packet.tabs[data_in[19:16]].tab[0][0] <= data_in[15:8];
                                quant_packet.tabs[data_in[19:16]].tab[0][1] <= data_in[7:0];
                                DQT_fill_idx <= 2;
                                saved_marker_status <= 4'b0100;
                            end
                        end

                        4'b0100: if (DQT_fill_idx == 62) begin
                            quant_packet.tabs[DQT_info[3:0]].tab[62 >> 3][62 & 3'b111] <= data_in[31:24];
                            quant_packet.tabs[DQT_info[3:0]].tab[63 >> 3][63 & 3'b111] <= data_in[23:16];

                            if (DQT_fill_offset < DQT_seg_tbl_num) begin
                                DQT_fill_offset <= DQT_fill_offset + 1;
                                DQT_info <= data_in[15:8];

                                quant_packet.tabs[data_in[11:8]].tab[0][0] <= data_in[7:0];

                                DQT_fill_idx <= 1;
                                saved_marker_status <= 4'b0010;
                            end
                        end

                        4'b0100: if (DQT_fill_idx == 62) begin
                            quant_packet.tabs[DQT_info[3:0]].tab[62 >> 3][62 & 3'b111] <= data_in[31:24];
                            quant_packet.tabs[DQT_info[3:0]].tab[63 >> 3][63 & 3'b111] <= data_in[23:16];

                            if (DQT_fill_offset < DQT_seg_tbl_num) begin
                                DQT_fill_offset <= DQT_fill_offset + 1;
                                DQT_info <= data_in[15:8];

                                quant_packet.tabs[data_in[11:8]].tab[0][0] <= data_in[7:0];
                                DQT_fill_idx <= 1;
                                saved_marker_status <= 4'b0010;
                            end
                        end

                        4'b0010: if (DQT_fill_idx == 61) begin
                            quant_packet.tabs[DQT_info[3:0]].tab[61 >> 3][61 & 3'b111] <= data_in[31:24];
                            quant_packet.tabs[DQT_info[3:0]].tab[62 >> 3][62 & 3'b111] <= data_in[23:16];
                            quant_packet.tabs[DQT_info[3:0]].tab[63 >> 3][63 & 3'b111] <= data_in[15:8];

                            if (DQT_fill_offset < DQT_seg_tbl_num) begin
                                DQT_fill_offset <= DQT_fill_offset + 1;
                                DQT_info <= data_in[7:0];

                                DQT_fill_idx <= 0;
                                saved_marker_status <= 4'b0001;
                            end
                        end
                    endcase

                    $display("✅ Quantization Table %0d fully filled at time %0t", DQT_fill_offset, $time);
                    if (DQT_fill_offset + 1 >= DQT_seg_tbl_num) begin
                        $display("🎯 All Quant Tables Filled, returning to marker scanning.");
                    end
                end
            end
            /* END of DQT handling ----------------------------*/
            /* START of SOF0 handling -------------------------*/

            if (next_state == SOF0 && |sof0_marker_status) begin
                saved_marker_status <= sof0_marker_status;
                
                case (sof0_marker_status)
                    // ffc0XXXX there are two hangover bytes 
                    4'b1000: begin
                        SOF0_buffer[0] <= last_data_in[15:8];  // Length high byte
                        SOF0_buffer[1] <= last_data_in[7:0];  // Length high byte
                        SOF0_buffer[2] <= data_in[31:24]; 
                        SOF0_buffer[3] <= data_in[23:16]; 
                        SOF0_buffer[4] <= data_in[15:8];
                        SOF0_buffer[5] <= data_in[7:0];   
                        SOF0_byte_cnt  <= 6;               
                    end

                    // 2dffc0XX there is a spare data byte from last cycle thsat needs to be read 
                    4'b0100: begin
                        SOF0_buffer[0] <= last_data_in[7:0];  // Length high byte
                        SOF0_buffer[1] <= data_in[31:24];  // Length high byte
                        SOF0_buffer[2] <= data_in[23:16];
                        SOF0_buffer[3] <= data_in[15:8];
                        SOF0_buffer[4] <= data_in[7:0];  
                        SOF0_byte_cnt  <= 5; 
                    end

                    // example 0b0010 for 2d2dffc0 then the next data in is read
                    4'b0010: begin
                        SOF0_buffer[0] <= data_in[31:24]; 
                        SOF0_buffer[1] <= data_in[23:16]; 
                        SOF0_buffer[2] <= data_in[15:8];     // Image height high byte
                        SOF0_buffer[3] <= data_in[7:0];      // Image height low byte
                        SOF0_byte_cnt  <= 4;                 // 5 bytes loaded total (1 last cycle, 4 current cycle)
                    end

                    // example 0b0010 for 2d200dff then the next data has one spare marker byte then I use tAbouthreee data
                    4'b0001: begin
                        SOF0_buffer[0] <= data_in[23:16];      // Image height high byte
                        SOF0_buffer[1] <= data_in[15:8];       // Image height low byte
                        SOF0_buffer[2] <= data_in[7:0];        // Image width high byte
                        SOF0_byte_cnt  <= 3;                   // 6 bytes loaded total (2 last cycle, 4 current cycle)
                    end
                endcase
            end else if(state == SOF0) begin
                SOF0_buffer[SOF0_byte_cnt]     <= data_in[31:24];
                SOF0_buffer[SOF0_byte_cnt + 1] <= data_in[23:16];
                SOF0_buffer[SOF0_byte_cnt + 2] <= data_in[15:8];
                SOF0_buffer[SOF0_byte_cnt + 3] <= data_in[7:0];

                // Increment byte counter by 4 bytes
                SOF0_byte_cnt <= SOF0_byte_cnt + 4;
`ifdef DEBUG
                print_SOF0_out(SOF0_out);
`endif
                //Buffer is big enough I can just copy spare bits in an break out into the next state without error. 
                if (SOF0_byte_cnt >= SOF0_out.len) begin
                    $display("✅ SOF0 buffer filled completely at time %0t", $time);
                end
            end

            /* END of SOF0 handling -------------------------*/
            /* START of DHT handling ------------------------*/

            if (next_state == DHT && |dht_marker_status) begin
                $display("!!!@!@ HERE WE ARE");
                DHT_sym_byte_cnt <= '0;

                saved_marker_status <= dht_marker_status;
                case (dht_marker_status)
                    4'b1000: begin
                        DHT_len  <= last_data_in[15:0];
                        DHT_info <= data_in[31:24];
                        DHT_len_byte_cnt <= 3;

                        DHT_code_counts[1] <= data_in[23:16];
                        DHT_code_counts[2] <= data_in[15:8];
                        DHT_code_counts[3] <= data_in[7:0];
                    end
                    4'b0100: begin
                        DHT_len  <= {last_data_in[7:0], data_in[31:24]};
                        DHT_info <= data_in[23:16];
                        DHT_len_byte_cnt <= 2;

                        DHT_code_counts[1] <= data_in[15:8];
                        DHT_code_counts[2] <= data_in[7:0];
                    end
                    4'b0010: begin
                        DHT_len  <= data_in[31:16];
                        DHT_info <= data_in[15:8];
                        DHT_len_byte_cnt <= 1;

                        DHT_code_counts[1] <= data_in[7:0];
                    end
                    4'b0001: begin
                        $display("Got length: %d ", last_data_in[23:8]);
                        DHT_len  <= last_data_in[23:8];
                        DHT_info <= last_data_in[7:0];
                        DHT_len_byte_cnt <= 4;

                        DHT_code_counts[1] <= data_in[31:24];
                        DHT_code_counts[2] <= data_in[23:16];
                        DHT_code_counts[3] <= data_in[15:8];
                        DHT_code_counts[4] <= data_in[7:0];
                    end
                endcase

            end else if (state == DHT) begin
                if (DHT_len_byte_cnt < 16) begin //fortunately the byte count is never zero at the start
                    //Final butlength cycyle now
                    if (DHT_len_byte_cnt >= 12) begin
                        case (saved_marker_status)
                            4'b1000: begin  // exactly 1 remaining byte [16]
                                DHT_code_counts[16] <= data_in[31:24];
                                DHT_len_byte_cnt <= DHT_len_byte_cnt + 1;
                                // explicitly 3 bytes remain for symbols
                                DHT_sym_buffer[DHT_sym_byte_cnt] <= data_in[23:16];
                                DHT_sym_buffer[DHT_sym_byte_cnt + 1] <= data_in[15:8];
                                DHT_sym_buffer[DHT_sym_byte_cnt + 2] <= data_in[7:0];
                                DHT_sym_byte_cnt <= DHT_sym_byte_cnt + 3;
                            end
                            4'b0100: begin  // exactly 2 remaining bytes [15-16]
                                DHT_code_counts[15] <= data_in[31:24];
                                DHT_code_counts[16] <= data_in[23:16];
                                DHT_len_byte_cnt <= DHT_len_byte_cnt + 2;

                                // explicitly 2 bytes remain for symbols
                                DHT_sym_buffer[DHT_sym_byte_cnt] <= data_in[15:8];
                                DHT_sym_buffer[DHT_sym_byte_cnt + 1] <= data_in[7:0];
                                DHT_sym_byte_cnt <= DHT_sym_byte_cnt + 2;
                            end
                            4'b0010: begin  // exactly 3 remaining bytes [14-16]
                                DHT_code_counts[14] <= data_in[31:24];
                                DHT_code_counts[15] <= data_in[23:16];
                                DHT_code_counts[16] <= data_in[15:8];
                                DHT_len_byte_cnt <= DHT_len_byte_cnt + 3;

                                // explicitly 1 byte remains for symbols
                                DHT_sym_buffer[DHT_sym_byte_cnt] <= data_in[7:0];
                                DHT_sym_byte_cnt <= DHT_sym_byte_cnt + 1;
                            end
                            4'b0001: begin  // exactly 4 remaining bytes [13-16]
                                DHT_code_counts[13] <= data_in[31:24];
                                DHT_code_counts[14] <= data_in[23:16];
                                DHT_code_counts[15] <= data_in[15:8];
                                DHT_code_counts[16] <= data_in[7:0];
                                DHT_len_byte_cnt <= DHT_len_byte_cnt + 4;
                            end
                        endcase
                    end else begin

                        // We are loading the 16 length bytes (L1 - L16)
                        DHT_code_counts[DHT_len_byte_cnt + 1]   <= data_in[31:24];
                        DHT_code_counts[DHT_len_byte_cnt + 2]   <= data_in[23:16];
                        DHT_code_counts[DHT_len_byte_cnt + 3]   <= data_in[15:8];
                        DHT_code_counts[DHT_len_byte_cnt + 4]   <= data_in[7:0];
                        DHT_len_byte_cnt <= DHT_len_byte_cnt + 4;
                    end
                end else begin
                    if(DHT_len_byte_cnt == 16) begin
                        $display("Total size is: %d, vector is: %b", DHT_code_counts[1] + DHT_code_counts[2] + DHT_code_counts[3] + DHT_code_counts[4] + 
                                DHT_code_counts[5] + DHT_code_counts[6] + DHT_code_counts[7] + DHT_code_counts[8] + 
                                DHT_code_counts[9] + DHT_code_counts[10] + DHT_code_counts[11] + DHT_code_counts[12] +
                                DHT_code_counts[13] + DHT_code_counts[14] + DHT_code_counts[15] + DHT_code_counts[16], {|DHT_code_counts[1],  |DHT_code_counts[2],  |DHT_code_counts[3],  |DHT_code_counts[4],
                                |DHT_code_counts[5],  |DHT_code_counts[6],  |DHT_code_counts[7],  |DHT_code_counts[8],
                                |DHT_code_counts[9],  |DHT_code_counts[10], |DHT_code_counts[11], |DHT_code_counts[12],
                                |DHT_code_counts[13], |DHT_code_counts[14], |DHT_code_counts[15], |DHT_code_counts[16]} );

                        if (DHT_class == 1'b1) begin  // AC Huffman table
                            huff_packet.tabs[DHT_id].ac_size <= (DHT_code_counts[1] + DHT_code_counts[2] + DHT_code_counts[3] + DHT_code_counts[4] + 
                                DHT_code_counts[5] + DHT_code_counts[6] + DHT_code_counts[7] + DHT_code_counts[8] + 
                                DHT_code_counts[9] + DHT_code_counts[10] + DHT_code_counts[11] + DHT_code_counts[12] +
                                DHT_code_counts[13] + DHT_code_counts[14] + DHT_code_counts[15] + DHT_code_counts[16]);
                            huff_packet.tabs[DHT_id].ac_length_opts <= {|DHT_code_counts[1],  |DHT_code_counts[2],  |DHT_code_counts[3],  |DHT_code_counts[4],
                                |DHT_code_counts[5],  |DHT_code_counts[6],  |DHT_code_counts[7],  |DHT_code_counts[8],
                                |DHT_code_counts[9],  |DHT_code_counts[10], |DHT_code_counts[11], |DHT_code_counts[12],
                                |DHT_code_counts[13], |DHT_code_counts[14], |DHT_code_counts[15], |DHT_code_counts[16]};
                        end else begin                // DC Huffman table
                            huff_packet.tabs[DHT_id].dc_size <= DHT_code_counts[1] + DHT_code_counts[2] + DHT_code_counts[3] + DHT_code_counts[4] + 
                                DHT_code_counts[5] + DHT_code_counts[6] + DHT_code_counts[7] + DHT_code_counts[8] + 
                                DHT_code_counts[9] + DHT_code_counts[10] + DHT_code_counts[11] + DHT_code_counts[12] +
                                DHT_code_counts[13] + DHT_code_counts[14] + DHT_code_counts[15] + DHT_code_counts[16];
                            huff_packet.tabs[DHT_id].dc_length_opts <= {|DHT_code_counts[1],  |DHT_code_counts[2],  |DHT_code_counts[3],  |DHT_code_counts[4],
                                |DHT_code_counts[5],  |DHT_code_counts[6],  |DHT_code_counts[7],  |DHT_code_counts[8],
                                |DHT_code_counts[9],  |DHT_code_counts[10], |DHT_code_counts[11], |DHT_code_counts[12],
                                |DHT_code_counts[13], |DHT_code_counts[14], |DHT_code_counts[15], |DHT_code_counts[16]};
                        end
                        DHT_len_byte_cnt <= 17;
                    end 
                    $display("\nID changing?: %d", DHT_id);
                    DHT_sym_buffer[DHT_sym_byte_cnt ]       <= data_in[31:24];
                    DHT_sym_buffer[DHT_sym_byte_cnt +1]     <= data_in[23:16];
                    DHT_sym_buffer[DHT_sym_byte_cnt +2]     <= data_in[15:8];
                    DHT_sym_buffer[DHT_sym_byte_cnt +3]     <= data_in[7:0];
                    DHT_sym_byte_cnt <= DHT_sym_byte_cnt + 4;
                    $display("\Current %d",DHT_sym_byte_cnt);
                    $display("\nNumber %d",DHT_len_byte_cnt);
                    if(DHT_class == 1'b1) begin //This is AC
                        if(DHT_sym_byte_cnt + 4 > huff_packet.tabs[DHT_id].ac_size) begin
                            huff_packet.tabs[DHT_id].ac_tab <= gened_huff.ac_tab;
                            $display("About to finish table ");
                            display_gened_huff(gened_huff, DHT_info);
                        end
                    end else begin
                        if(DHT_sym_byte_cnt + 4 > huff_packet.tabs[DHT_id].dc_size) begin
                            huff_packet.tabs[DHT_id].dc_tab <= gened_huff.dc_tab;
                            $display("About to finish table ");
                            display_gened_huff(gened_huff, DHT_info);
                        end
                    end
                end
            end
                    
                    // After 16 length bytes are loaded, now loading symbols
                    // (Handled in a subsequent logic block clearly)     
        end

            /* END of DHT handling --------------------------*/
            /* START of SOS handling --------------------------*/


        if (next_state == SOS && |sos_marker_status) begin //First case are we entering SOS state fresh off a marker?
            $display("\nWitnesses SOS, seeing last:%h and current: %h", last_data_in, data_in);
            saved_marker_status <= sos_marker_status;
            case (sos_marker_status)
                4'b1000: begin // Mark ends then 2 remaining 
                    SOS_buffer[SOS_tail] <= last_data_in[15:8];
                    SOS_buffer[SOS_tail + 1] <= last_data_in[7:0]; 
                    SOS_buffer[SOS_tail + 2] <= data_in[31:24]; 
                    SOS_buffer[SOS_tail + 3] <= data_in[23:16]; 
                    SOS_buffer[SOS_tail + 4] <= data_in[15:8];
                    SOS_buffer[SOS_tail + 5] <= data_in[7:0];   
                    SOS_tail <= SOS_tail + 6;

                end
                4'b0100: begin 
                    SOS_buffer[SOS_tail] <= last_data_in[7:0]; 
                    SOS_buffer[SOS_tail + 1] <= data_in[31:24]; 
                    SOS_buffer[SOS_tail + 2] <= data_in[23:16]; 
                    SOS_buffer[SOS_tail + 3] <= data_in[15:8];
                    SOS_buffer[SOS_tail + 4] <= data_in[7:0];   
                    SOS_tail <= SOS_tail + 5;

                end
                4'b0010: begin 
                    SOS_buffer[SOS_tail] <= data_in[31:24]; 
                    SOS_buffer[SOS_tail + 1] <= data_in[23:16]; 
                    SOS_buffer[SOS_tail + 2] <= data_in[15:8];
                    SOS_buffer[SOS_tail + 3] <= data_in[7:0];   
                    SOS_tail <= SOS_tail + 4;

                end
                4'b0001: begin
                    SOS_buffer[SOS_tail] <= data_in[23:16]; 
                    SOS_buffer[SOS_tail + 1] <= data_in[15:8];
                    SOS_buffer[SOS_tail + 2] <= data_in[7:0];   
                    SOS_tail <= SOS_tail + 3;

                end
            endcase
            
        end else if(state == SOS) begin
            $display("Suffing Marker: %b, tesing indexing: %b" ,stuffing_marker_status, stuffing_marker_status[3]);
            $display("SOS Diff: %d", ({SOS_tail - SOS_head}[3:0]));
            $display("SOS_buffer Buffer: [%02h %02h %02h %02h %02h %02h %02h %02h %02h %02h %02h %02h %02h %02h %02h %02h] | head: %d | tail: %d",
         SOS_buffer[0], SOS_buffer[1], SOS_buffer[2], SOS_buffer[3],
         SOS_buffer[4], SOS_buffer[5], SOS_buffer[6], SOS_buffer[7],
         SOS_buffer[8], SOS_buffer[9], SOS_buffer[10], SOS_buffer[11],
         SOS_buffer[12], SOS_buffer[13], SOS_buffer[14], SOS_buffer[15],
         SOS_head, SOS_tail);

            case (stuffing_marker_status)
                4'b0000: begin
                    SOS_buffer[SOS_tail]     <= last_data_in[31:24];
                    SOS_buffer[SOS_tail + 1] <= last_data_in[23:16];
                    SOS_buffer[SOS_tail + 2] <= last_data_in[15:8];
                    SOS_buffer[SOS_tail + 3] <= last_data_in[7:0];
                    SOS_tail <= SOS_tail + 4;
                end
  
                4'b0010: begin
                    $display("Stuffing witnessed!");
                    SOS_buffer[SOS_tail]     <= last_data_in[31:24];
                    SOS_buffer[SOS_tail + 1] <= last_data_in[23:16];
                    SOS_buffer[SOS_tail + 2] <= last_data_in[15:8];
                    SOS_buffer[SOS_tail + 3] <= last_data_in[7:0];
                    SOS_tail <= SOS_tail + 4;
                end
                4'b0100: begin
                    $display("Stuffing witnessed!");
                    SOS_buffer[SOS_tail]     <= last_data_in[31:24];
                    SOS_buffer[SOS_tail + 1] <= last_data_in[23:16];
                    SOS_buffer[SOS_tail + 2] <= last_data_in[7:0];
                    SOS_tail <= SOS_tail + 3;
                end
                4'b1000: begin
                    $display("Stuffing witnessed!");
                    SOS_buffer[SOS_tail]     <= last_data_in[31:24];
                    SOS_buffer[SOS_tail + 1] <= last_data_in[15:8];
                    SOS_buffer[SOS_tail + 2] <= last_data_in[7:0];
                    SOS_tail <= SOS_tail + 3;
                end
                default: begin
                    $display("Multiple stuffing markers detected!");
                    // Optionally handle error or multiple markers
                end
            endcase

            if(SOS_tail - SOS_head > 3) begin
                $display("Export 8 and display");
                SOS_to_fifo[31:24] <= SOS_buffer[SOS_head];
                SOS_to_fifo[23:16] <= SOS_buffer[SOS_head + 1];
                SOS_to_fifo[15:8] <= SOS_buffer[SOS_head + 2];
                SOS_to_fifo[7:0] <= SOS_buffer[SOS_head + 3];
                SOS_head <= SOS_head + 4;
                $display("Will output: %h",{SOS_buffer[SOS_head], SOS_buffer[SOS_head+1],SOS_buffer[SOS_head+2],SOS_buffer[SOS_head+3]} );
            end
        end
                        /* START of SOS handling --------------------------*/
    end
endmodule
