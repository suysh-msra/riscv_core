///top level datapayh for a singlecycleMIPS style CPU.
//all stages in one clk cycle
//supported Instructions : R type add,sub,and,or,slt; addi; lw,sw; beq;j

module single_cycle_cpu (
  input clk,
  input rst_n
);
  logic [31:0] pc, pc_plus4, pc_next, brat, jumt;
  logic [31:0] inst;
  logic [31:0] rd_dat1, rd_dat2, wr_dat;
  logic [31:0] sign_xt_imm, alu_b, alu_res;//what's alu_b??
  logic [31:0] memrd_dat;
  logic [4:0]  wr_reg;
  logic        alu_zero;

  //inst fields
  wire [5:0] op     = inst[31: 26];
  wire [4:0] rs     = inst[25: 21];
  wire [4:0] rt     = inst[20: 16];
  wire [4:0] rd     = inst[15: 11];
  wire [5:0] funct  = inst[5 : 0];
  wire [15:0] imm16 = inst[15 : 0];//shaamat??
  wire [25:0] addr26 = inst[25: 0];

  //ctrl sigs
  logic reg_dst, alu_src, mem_to_reg, reg_wr, mem_rd, mem_wr, bra, jum;
  logic [2:0] alu_ctrl;

  ctrl_unit u_ctrl (
    .op(op),
    .funct(funct),
    .reg_dst(reg_dst),
    .alu_src(alu_src),
    .mem_to_reg(mem_to_reg),
    .reg_wr(reg_wr),
    .mem_rd(mem_rd),
    .mem_wr(mem_wr),
    .bra(bra),
    .jum(jum),
    .alu_ctrl(alu_ctrl)
  );
//TODO: rest  of the code
  
endmodule
