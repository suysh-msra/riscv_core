//regfilef
//two comb rd ports (ID stage), onesync wr port (WB stage).
//reg 0 hardwired to zero

//same cycle wr-to-rd bypass. in a 5 stage pipeline, an instr 3 slots behind its producerhas its ID stage read  land on the exact cycle 
// the producer's WB-stage write commits . eg addi $1(i0) then two unrelated instr then an instr reading $1 (I3), both touch regfule in the same cycle.

module regfile (
  output [31:0] rd_data1,
  output [31:0] rd_data2,
  input         clk,
  input         rst_n,
  input         wr_en,
  input  [4:0]  rd_reg1,
  input  [4:0]  rd_reg2,
  input  [4:0]  wr_reg,
  input  [31:0] wr_data
);

  logic [31:0] regs [0:31];

  always @ (posedge clk) begin
    if (!rst_n) begin
      int i;
      for (i = 0; i < 32; i++) regs[i] <= 32'd0;
    end else if (wr_en && wr_reg != 5'd0) begin
      regs[wr_reg] <= wr_data;
    end
  end

  wire bypass1 = wr_en && (wr_reg) && (wr_reg == rd_reg1);
  wire bypass2 = wr_en && (wr_reg) && (wr_reg == rd_reg2);

  assign rd_data1 = (!rd_reg1) ? 32'd0 : (bypass1 ? wr_data : regs[rd_reg1]);
  assign rd_data2 = (!rd_reg2) ? 32'd0 : (bypass2 ? wr_data : regs[rd_reg2]);
endmodule
      
