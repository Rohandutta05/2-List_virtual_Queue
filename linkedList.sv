// LinkedList fifo / Vitual Fifo used for Multiple Host Queueing
// The index SRAM is defined here but the wdata SRAM is not coded.
// The controller part of the virtual fifo is as below
// Lets Begin

// Trying to create a SRAM based 2-list queue of depth N
module link_fifo#(parameter DATAWIDTH=128,
                  parameter DEPTH =32,
                  parameter LIST = 2)
  (
    input logic clk,
    input logic resetn,
  // Write interface  
    input logic [DATAWIDTH:0] wdata, // DATA_WIDTH MSB denotes A=1 , B=0
    input logic wr_vld,
  	output logic wr_rdy,
    input logic [$clog2(DEPTH)-1:0] wr_idx,
  // Read Interface
    output logic [DATAWIDTH-1:0] rdata,
    output logic rd_vld,
    input logic rd_rdy,
  	input logic rd_list);
  
  
  // 2 List queues
  // A LIST 
  logic [$clog2(DEPTH)-1:0] head_a;
  logic [$clog2(DEPTH)-1:0] tail_a;
  logic [$clog2(DEPTH)-1:0] count_a;
  
  logic [$clog2(DEPTH)-1:0] head;
  logic [$clog2(DEPTH)-1:0] tail;
  
  logic full;
  logic empty;
  logic push;
  logic pop;
  
  logic 				wren_list;
  logic [$clog2(DEPTH)-1:0] waddr_list;
  logic [$clog2(DEPTH)-1:0] waddr_lista;
  logic [$clog2(DEPTH)-1:0] waddr_listb;
  logic [$clog2(DEPTH)-1:0] wdata_list;
  logic [$clog2(DEPTH)-1:0] wdata_lista;
  logic [$clog2(DEPTH)-1:0] wdata_listb;
  logic [$clog2(DEPTH)-1:0] rdata_list;
  logic [$clog2(DEPTH)-1:0] raddr_list; 
  logic list_chk;
  
   // B LIST 
  logic [$clog2(DEPTH)-1:0] head_b;
  logic [$clog2(DEPTH)-1:0] tail_b;
  logic [$clog2(DEPTH)-1:0] count_b; // To count max 32 if all wdata is from List b
  
  // Write Control for List A
  always_ff @(posedge clk or negedge resetn) begin
    if(~resetn) begin
      	head_a <= '0;
    	tail_a <= '0; end
    else if (push & (wdata[DATAWIDTH] ==1) & count_a == 5'd0) begin
      	head_a <= wr_idx;
    	tail_a <= wr_idx; end
    else if (push & (wdata[DATAWIDTH] ==1) & count_a != 5'd0) begin
      	head_a <= head_a;
    	tail_a <= wr_idx; end     
    else if (pop & rd_list & count_a == 1) begin	// Dequeue when we have 1 value for the list A 
        head_a <= rdata_list;
    	tail_a <= rdata_list; end    
    else if (pop & rd_list & count_a !=0) begin	// Dequeue when we have more than 1 value for the list A
        head_a <= rdata_list;
    	tail_a <= tail_a; end    
  end
  
  // Write Control for List B
  always_ff @(posedge clk or negedge resetn) begin
    if(~resetn) begin
      	head_b <= '0;
    	tail_b <= '0; end
    else if (push & (wdata[DATAWIDTH] ==0) & count_b == 5'd0) begin
      	head_b <= wr_idx;
    	tail_b <= wr_idx; end
    else if (push & (wdata[DATAWIDTH] ==0) & count_b != 5'd0) begin
      	head_b <= head_b;
    	tail_b <= wr_idx; end 
    else if (pop & ~rd_list & count_b == 1) begin	// Dequeue when we have 1 value for the list B 
        head_b <= rdata_list;
    	tail_b <= rdata_list; end  
    else if (pop & ~rd_list & count_b !=0) begin	// Dequeue when we have more than 1 value for the list B 
        head_b <= rdata_list;
    	tail_b <= tail_b; end    
  end  
  
  // WR_RDY denotes if the fifo is Full 
  // Count_a and Count_b are the counts for A list and B list entries
  // Rd_vld is Read valid signal which denotes if fifo is empty
  assign wr_rdy = ((count_a + count_b ) != DEPTH) ; 	
  assign rd_vld = (count_a !=0 | count_b !=0) ? 1'b1:1'b0;
  assign push   = wr_rdy & wr_vld;
  assign pop = rd_vld & rd_rdy;

  
  // list A and List B index linking
  // Waddr_list is the address of the linked list fifo for List A and B
  assign waddr_lista = ((count_a == 0) & push) ? wr_idx: tail_a;
  assign waddr_listb = ((count_b == 0) & push) ? wr_idx: tail_b;
  assign waddr_list = (wdata[DATAWIDTH]) ? waddr_lista : waddr_listb;
  
  // Wdata_list shows the wdata value for that wr_idx
  // In this case, we take the waddr as wr_idx for the 1st entry followed by tailptr value as waddr and 
  // wr_idx as wdata. This keeps going on until the count value is full
  always_comb begin
    if ((count_a != 0) & push & wdata[DATAWIDTH])
      wdata_lista = wr_idx;
  end
  
  always_comb begin
    if ((count_b != 0) & push & ~wdata[DATAWIDTH])
      wdata_listb = wr_idx;
  end

  assign wdata_list = (wdata[DATAWIDTH]) ? wdata_lista : wdata_listb;  

  // Rd_list tells which List is selected. In this case rd_list =1, select List A or otherwise
  assign raddr_list = rd_list ? head_a : head_b;
  assign wren_list   = |push;
  assign ren_list = |pop;
  assign logic_chk = wdata[DATAWIDTH];
  
  // mem for the actual wdata value incoming in the SRAM 
  assign wren = |push;
  assign ren  = |pop;
  assign tail = wdata[DATAWIDTH]? tail_a : tail_b;
  assign head = pop & rd_list? head_a : head_b;
  
 // Instantitate the list mem and sram mem
  mem l1 (.clk(clk),
          .resetn(resetn),
          .wren(wren_list),
          .waddr(waddr_list),	// Can be tail_a or tail_b
          .wdata(wdata_list),
          .rdata(rdata_list),
          .raddr(head),
          .ren(ren_list));
/*  
  mem d1 (.clk(clk),
          .resetn(resetn),
          .wren(wren),
          .wdata(wdata[DATAWIDTH-1:0]),
          .waddr(tail),
          .rdata(rdata),
          .raddr(head),
          .ren(ren));  */
 // Counters for List A and B
  
  always @( posedge clk or negedge resetn) begin
    if(~resetn) begin
      count_a <= '0;end
    else if (push & wdata[DATAWIDTH] & count_a <= 5'd32)
      count_a <= count_a +1'b1; 
    else if (pop & rd_list & count_a !=0) 
      count_a <= count_a -1; end

  always @( posedge clk or negedge resetn) begin
    if(~resetn) begin
      count_b <= '0;end
    else if (push & ~wdata[DATAWIDTH] & count_b <= 5'd32)
      count_b <= count_b +1'b1; 
    else if (pop & ~rd_list & count_b !=0) 
      count_b <= count_b -1;   end   
endmodule

module mem #(parameter DEPTH =32)	// LinkedList Controller Memory
  (
    input logic clk,
    input logic [0:0] resetn,
	input logic [0:0] wren,
	input logic [$clog2(DEPTH)-1:0] waddr,
	input logic [$clog2(DEPTH)-1:0] wdata,
	output logic [$clog2(DEPTH)-1:0] rdata,
	input logic [$clog2(DEPTH)-1:0] raddr,
    input logic [0:0] ren);
  
  logic [$clog2(DEPTH)-1:0] mem_list [DEPTH-1:0];
  
  always@(posedge clk) begin
    if(wren)
      mem_list[waddr] <= wdata;
  end 
  
  always_comb begin
    if(ren)
      rdata = mem_list[raddr];
  end
endmodule
