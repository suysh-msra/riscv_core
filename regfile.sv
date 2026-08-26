module regfile (
  input clk,
  input rst_n,
  input [4:0] rd_reg1,
  input [4:0] rd_reg2,
  input [4:0] wr_reg,
  input [31:0] wr_dat,
  input        wr_en,
  output [31:0] rd_dat1,
  output [31:0] rd_dat2
);
  logic [31:0] regs [0:31];

  always @(posedge clk) begin
    if (!rst_n) begin
      int i;
      for (i = 0; i < 32; i++) regs[i] <= 32'd0;
    end else if (wr_en && wr_reg != 0) regs[wr_reg] <= wr_dat;
    //ik reg0 is hardcoded tozero but i still don't understand this style of writing verilog
    //i guess it simplifies the logic because we're not separately checking every time we write to a reg, that it's not reg0
  end
  //end

  assign rd_dat1 = (rd_reg1 == 0) ? 32'd0 : regs[rd_reg1];
  assign rd_dat2 = (rd_reg2 == 0) ? 32'd0 : regs[rd_reg2];
endmodule
