//data_mem.sv
//data RAM
//word addressed
//synch wr, comb rd.mem_rd not needed to gate rd.
//array rd always valid.
//

module data_mem(
  input clk,
  input [31:0] addr,
  input [31:0] wr_dat,
  input        mem_wr,
  input        mem_rd,
  //input 
  output [31:0] rd_dat);

  logic [31:0] mem [0:63]; //who knew it was this easy to create RAM

  initial begin
    int i;
    for (i = 0; i < 64; i++)
      mem[i] = 32'b0;
  end
  
  always @ (posedge clk) begin
    if (mem_wr)
      mem[addr[31:2]] <= wr_dat;
  end

  assign rd_dat = mem[addr[31:2]];
endmodule
