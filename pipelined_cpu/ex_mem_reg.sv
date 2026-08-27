//EX/MEM piepline register.
//always advabnces, no stall/ flush needed here, as 
//any bubble already present at its input is just all inactive control inst

module ex_mem_reg (
  input         clk,
  input         rst_n,
  input  [31:0] alu_res_in, st_dat_in,
  input  [4:0]  wr_reg_in,
  input         reg_wr_in, mem_rd_in, mem_wr_in, mem_to_reg_in,

  output [31:0] alu_res_out, st_dat_out,
  output [4:0]  wr_reg_out,
  output        reg_wr_out, mem_rd_out, mem_wr_out, mem_to_reg_out
);
  logic [31:0] alu_res_r, st_dat_r;
  logic [4:0]  wr_reg_r;
  logic        reg_wr_r, mem_rd_r,mem_wr_r, mem_to_reg_r;

  always @(posedge clk) begin
    if (!rst_n) begin
      alu_res_r    <=  0 ;
      st_dat_r     <=   0;
      wr_reg_r     <=   0;
      reg_wr_r     <=   0;
      mem_rd_r     <=   0;
      mem_wr_r     <=   0;
      mem_to_reg_r <=  0;
    end else  begin
      alu_res_r    <=   alu_res_in;
      st_dat_r     <=   st_dat_in;
      wr_reg_r     <=   wr_reg_in;
      reg_wr_r     <=   reg_wr_in;
      mem_rd_r     <=   mem_rd_in;
      mem_wr_r     <=   mem_wr_in;
      mem_to_reg_r <=  mem_to_reg_in;
    end
  end
  assign alu_res_out = alu_res_r;
  assign st_dat_out  = st_dat_r;
  assign wr_reg_out  = wr_reg_r;
  assign reg_wr_out  = reg_wr_r;
  assign mem_rd_out  = mem_rd_r;
  assign mem_wr_out  = mem_wr_r;
  assign mem_to_reg_out = mem_to_reg_r;
endmodule
  
