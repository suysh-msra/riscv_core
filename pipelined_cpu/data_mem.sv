//data RAM

module data_mem (
  input clk,
  //input rst_n,
  input [31:0] addr,
  input [31:0] wr_dat,
  input        mem_wr,
  input        mem_rd,
  output [31:0] rd_dat
);
  logic [31:0] mem [0:63];

  initial begin
    int i;
    for (i = 0; i < 64; i++) mem[i] = 32'h0;
  end

  always @(posedge clk) begin
    if (mem_wr) mem[addr[7:2]] <= wr_dat;
  end

  assign rd_dat = mem[addr[7:2]];
endmodule
  
