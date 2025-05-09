// A simple tb to test the functionality of the design
// Code your testbench here
// or browse Examples
module link_fifo_tb;

  parameter DATAWIDTH = 128;
  parameter DEPTH = 32;

  // Inputs
  logic clk;
  logic resetn;
  logic [DATAWIDTH:0] wdata;  // [128]=list selector, [127:0]=payload
  logic wr_vld;
  logic [$clog2(DEPTH)-1:0] wr_idx;
  logic rd_rdy;
  logic rd_list;  // 1 = List A, 0 = List B

  // Outputs
  logic wr_rdy;
  logic [DATAWIDTH-1:0] rdata;
  logic rd_vld;

  // Instantiate DUT
  link_fifo #(DATAWIDTH, DEPTH) dut (
    .clk(clk),
    .resetn(resetn),
    .wdata(wdata),
    .wr_vld(wr_vld),
    .wr_rdy(wr_rdy),
    .wr_idx(wr_idx),
    .rdata(rdata),
    .rd_vld(rd_vld),
    .rd_rdy(rd_rdy),
    .rd_list(rd_list)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Task to push a random transaction to a list
  task automatic push_random();
    logic list_sel = $urandom_range(0, 1);
    logic [127:0] payload = $urandom();
    logic [$clog2(DEPTH)-1:0] idx = $urandom_range(0, DEPTH-1);

    wdata = {list_sel, payload};
    wr_idx = idx;
    wr_vld = 1;

    wait (wr_rdy);
    @(posedge clk);
    wr_vld = 0;

    $display("Time %0t: PUSH  List=%s  Payload=0x%032x  wr_idx=%0d",
              $time, (list_sel ? "A" : "B"), payload, idx);
  endtask

  // Task to try reading from either List A or B
  task automatic try_read(input logic list_sel);
    rd_list = list_sel;
    if (rd_vld) begin
      rd_rdy = 1;
      @(posedge clk);
      rd_rdy = 0;
      $display("Time %0t: READ  List=%s  Data=0x%032x",
               $time, (list_sel ? "A" : "B"), rdata);
    end
  endtask

  // Random test scenario
  task automatic run_random_ops(int cycles);
    for (int i = 0; i < cycles; i++) begin
      if ($urandom_range(0, 1) && wr_rdy) begin
        push_random();
      end

      if ($urandom_range(0, 1)) begin
        try_read($urandom_range(0, 1));  // Randomly try read from A or B
      end

      @(posedge clk);
    end
  endtask

  // Main stimulus
  initial begin
    clk = 0;
    resetn = 0;
    wr_vld = 0;
    rd_rdy = 0;
    rd_list = 0;

    repeat (2) @(posedge clk);
    resetn = 1;

    $display("==== Randomized Test ====");
    run_random_ops(50);

    #50;
    $finish;
  end

initial
   begin
      $dumpfile("link_fifo_tb.vcd");
      $dumpvars(0,link_fifo_tb);
   end
endmodule
