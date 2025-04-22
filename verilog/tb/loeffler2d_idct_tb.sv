module loeffler2d_idct_tb;

  logic         clk;
  logic         rst;
  logic         valid_in;
  logic  [1:0]  channel_in;

  logic         valid_out;
  logic  [1:0]  channel_out;

  // two input blocks
  logic signed [11:0] idct_in_mem  [7:0][7:0];
  logic signed [11:0] idct_in_mem2 [7:0][7:0];
  logic signed [11:0] idct_in_mem3 [7:0][7:0];
  // muxed into this
  logic signed [11:0] idct_in      [7:0][7:0];
  logic unsigned [7:0] idct_out    [7:0][7:0];

  int finput;
  integer valid_count;

  // load both blocks
  initial begin
    finput = $fopen("../verilog/tb/idct_input_block2.txt", "r");
    for (int r = 0; r < 8; r++)
      for (int c = 0; c < 8; c++)
        $fscanf(finput, "%d\n", idct_in_mem[r][c]);
  end

    // block3 = all 2’s
    initial begin
        for (int r = 0; r < 8; r++) begin
            for (int c = 0; c < 8; c++) begin
                idct_in_mem2[r][c] = r;
                idct_in_mem3[r][c] = r + 8;
            end
        end
    end


  // instantiate DUT
  loeffler2d_idct_new idct2d_module (
    .clk        (clk),
    .rst        (rst),
    .valid_in   (valid_in),
    .channel_in (channel_in),
    .idct_in    (idct_in),
    .idct_out   (idct_out),
    .valid_out  (valid_out),
    .channel_out(channel_out)
  );

  // simple clock generator
  always #5 clk = ~clk;

  // count how many times we've pulsed valid_in
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      valid_count <= 0;
    else if (valid_in)
      valid_count <= valid_count + 1;
  end

  // multiplex the two memories based on valid_count
  always_comb begin
    for (int row = 0; row < 8; row++) begin
      for (int col = 0; col < 8; col++) begin
        if (valid_count == 2)
          idct_in[row][col] = idct_in_mem2[row][col];
        else if (valid_count == 3)
          idct_in[row][col] = idct_in_mem3[row][col];
        else
          idct_in[row][col] = idct_in_mem[row][col];
      end
    end
    channel_in = 2'd1;
  end

  // helper to wait N clocks
  task wait_cycles(int n);
    repeat(n) @(posedge clk);
  endtask

  // drive reset, valid_in, and then display outputs
  initial begin
    clk         = 0;
    rst         = 0;
    valid_in    = 0;

    // reset pulse
    wait_cycles(5);
    rst = 1;
    wait_cycles(5);
    rst = 0;

    // now pulse valid_in a bunch of times...
    repeat (2) begin
      valid_in = 1;
      @(posedge clk);
      valid_in = 0;
      @(posedge clk);
    end
    wait_cycles(10);
    @(posedge clk);
    valid_in = 1;
    @(posedge clk);
    valid_in = 0;

    // wait for each output block and display it
    repeat (2) begin
      wait (valid_out == 1);
      disp_block();
      // @(posedge clk);
    end

    wait_cycles(100);
    $finish;
  end

  task disp_block;
    $display("Output Block (pulse %0d):", valid_count);
    for (int r = 0; r < 8; r++) begin
      for (int c = 0; c < 8; c++)
        $write("%4d ", idct_out[r][c]);
      $write("\n");
    end
    $write("\n");
  endtask

endmodule
