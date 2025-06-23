module afifo_tb;

  parameter DSIZE = 8;
  parameter ASIZE = 3; // FIFO depth = 2^3 = 8 entries (small for wraparound test)

  // DUT signals
  reg                  wclk, wrstn, wren;
  reg  [DSIZE-1:0]     wdata;
  wire                 wfull;

  reg                  rclk, rrstn, rden;
  wire [DSIZE-1:0]     rdata;
  wire                 rempty;

  // Instantiate the FIFO
  afifo #(
    .dsize(DSIZE),
    .asize(ASIZE)
  ) dut (
    .wclk(wclk), .wrstn(wrstn), .wren(wren), .wdata(wdata), .wfull(wfull),
    .rclk(rclk), .rrstn(rrstn), .rden(rden), .rdata(rdata), .rempty(rempty)
  );

  // Clock generation
  initial wclk = 0;
  always #5 wclk = ~wclk;   // 100 MHz

  initial rclk = 0;
  always #7 rclk = ~rclk;   // ~71 MHz

  // Reset both domains
  initial begin
    wrstn = 0; rrstn = 0;
    #20;
    wrstn = 1; rrstn = 1;
  end

  // Stimulus
  integer i;
  reg [DSIZE-1:0] expected_data = 0;

  initial begin
    wren = 0;
    wdata = 0;
    rden = 0;

    wait(wrstn && rrstn);  // Wait for reset deassertion

    // -------------------------------
    // WRITE 8 entries (to max depth)
    // -------------------------------
    for (i = 0; i < 8; i = i + 1) begin
      @(posedge wclk);
      if (!wfull) begin
        wdata <= i;
        wren <= 1;
        $display("WRITE: %0d at time %0t", i, $time);
      end else begin
        $display("WARNING: FIFO FULL at time %0t", $time);
      end
    end
    @(posedge wclk); wren <= 0;

    // -------------------------------
    // Attempt to overfill FIFO (edge case)
    // -------------------------------
    @(posedge wclk);
    if (wfull) begin
      $display("Correct: FIFO reported FULL when full (at time %0t)", $time);
    end else begin
      $display("Error: FIFO should be full (at time %0t)", $time);
    end

    // -------------------------------
    // READ 4 entries (partial drain)
    // -------------------------------
    for (i = 0; i < 4; i = i + 1) begin
      @(posedge rclk);
      if (!rempty) begin
        rden <= 1;
        @(posedge rclk);  // Wait for stable data
        rden <= 0;
        $display("READ : %0d at time %0t", rdata, $time);

        if (rdata !== expected_data)
          $display("Data Mismatch! Expected: %0d, Got: %0d", expected_data, rdata);
        expected_data = expected_data + 1;
      end else begin
        $display("Error: FIFO was empty unexpectedly!");
      end
    end

    // -------------------------------
    // WRITE 4 more (wraparound test)
    // -------------------------------
    for (i = 8; i < 12; i = i + 1) begin
      @(posedge wclk);
      if (!wfull) begin
        wdata <= i;
        wren <= 1;
        $display("WRITE (wrap): %0d at time %0t", i, $time);
      end else begin
        $display("Error: FIFO is full too early");
      end
    end
    @(posedge wclk); wren <= 0;

    // -------------------------------
    // READ remaining data
    // -------------------------------
    for (i = 4; i < 12; i = i + 1) begin
      @(posedge rclk);
      if (!rempty) begin
        rden <= 1;
        @(posedge rclk);
        rden <= 0;
        $display("READ : %0d at time %0t", rdata, $time);

        if (rdata !== expected_data)
          $display("Data Mismatch! Expected: %0d, Got: %0d", expected_data, rdata);
        expected_data = expected_data + 1;
      end else begin
        $display("Error: FIFO empty too soon");
      end
    end

    // -------------------------------
    // Attempt to read from empty FIFO (edge case)
    // -------------------------------
    @(posedge rclk);
    if (rempty) begin
      $display("Correct: FIFO reported EMPTY after all reads (at time %0t)", $time);
    end else begin
      $display("Error: FIFO should be empty (at time %0t)", $time);
    end
    rden <= 1;
    @(posedge rclk);
    rden <= 0;
    $display("Attempted read on empty FIFO");

    // End simulation
    #50;
    $display("TEST COMPLETE at time %0t", $time);
    $finish;
  end

endmodule
