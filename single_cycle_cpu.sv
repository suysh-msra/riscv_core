///top level datapayh for a singlecycleMIPS style CPU.
//all stages in one clk cycle
//supported Instructions : R type add,sub,and,or,slt; addi; lw,sw; beq;j
//dict:
//branch_target : brat
//jump_target : jumt
//sign_ext_imm : sign_xt_imm
//instr : inst
//read_dataX : rd_datX, write_data : wr_dat, alu_result : alu_res,
//mem_read_data : memrd_dat
//write_reg : wr_reg
//mem_rd_data : memrd_dat
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
  //dict
  //reg(mem)_write(read) : reg(mem)_wr(rd)
  //branch : bra, jump, jum
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
  pc_reg u_pc (
    .clk      (clk),
    .rst_n    (rst_n),
    .pc_next  (pc_next),
    .pc       (pc)
  );

  instr_mem u_instr_mem (
    .addr(pc),
    .instr(instr)
  );

  assign write_reg = reg_dst ? rd : rt;

  regfile u_regfile (
    .clk        (clk),
    .rst_n      (rst_n),
    .rd_reg1    (rs),
    .rd_reg2    (rt),
    .wr_reg     (wr_reg),
    .wr_dat     (wr_dat),
    .wr_en      (reg_write),
    .rd_dat1    (rd_dat1),
    .rd_dat2    (rd_dat2)
  );

  assign sign_xt_imm = {{16{imm16[15]}}, imm16};
  //i still don't understand why sign extension works, and i'm too lazy to do a numerical example by hand to convince myself

  assign alu_b = alu_src ? sign_xt_imm : rd_dat2; //oh okay, so alu_b is the second operand, and it's either an immediate value specified in the instruction itself, or a reg

  alu u_alu (
    .a        (rd_dat1),
    .b        (alu_b),
    .alu_ctrl (alu_ctrl),
    .alu_zero (alu_zero)
  );

  data_mem u_data_mem (
    .clk        (clk),
    .addr       (alu_res),
    .wr_dat     (rd_dat2),
    .mem_wr     (mem_wr),
    .mem_rd     (mem_rd),
    .rd_dat     (memrd_dat)
  );

  assign wr_dat = mem_to_reg ? memrd_dat : alu_res;//mem2reg was right there
  //Next-PC logic: sequential
  assign pc_plus4 = pc + 32'd4;
  //taken branch
  assign brat     = pc_plus4 + (sign_ext_imm  << 2);
  //jump
  assign jumt     = {pc_plus4[31:28], addr26, 2'b0};

  wire [31:0] pc_after_branch = (branch && alu_zero) ? brat : pc_plus4;
  assign pc_next = jump ? jumt : pc_after_branch;
endmodule
