//5 stage pipelined RV32I CPU (R-type add/sub/and/or/slt, addi, lw, sw, beq, and jal used as an uncoditional jump
//stages:
/* IF -> ID (decode, reg rd, bra/jum prd + redirect) -> EX (ALU ,operand fwding, branch res+ mispred correction)
-> MEM (data mem) -> WB (reg wb)

RISC-V's rd field sits at instr[11:7] for every fmt that writes a reg, so unlike a MIPS design there's no reg_dst mux anywhere.
branch/jump argets are PC relative to the instr's own address; not to pc+4. RV32I's B-type/J-type immediates are already byte-granular
(no left-shift needed, unl;ike a word-offset ISA).

Branching: prediced using a 2 bit saturating counter. if pred takn, the already flushed next inst is flushed aznd fetch redirects to the branch target
immediately. that's a onc cyc penalty even when the pred si correct, since target address isnt known untildecode.  
the branch is authoritatively resolved in EX (via the ALU zero flag), if EX finds the actual outcome didnt match what ID predicted, 
it flushes both IF and ID instructuions and redirects fetch to the correct tgt -- a further 2-cycle penalty stacked on topof whatever
the initial prediction already cost. every resolved branch, whether mispredicted or not, trains the predictor.

jumps are unconditiona; and resolved in ID directly: a 1 cycle penalty to flush the already feched next seqential instruction and 
redirect to the jump tgt.

HAZARDS: EX/MEM- and MEM/WV- stage fwding resolve ordinary RAW@ hazards without stalling. a load whose result is needed by the very next ins
(the classic load-use hazard) cant be fwded -- hazard_detect stalls the pipelinefor ecaxtly one cycle (freezing PC and IF/ID, bubbling ID/EX)
so MEM/WB fwding can supply it the cycle after instead. a same cyc wr/rd race 3 instr apart is coevered by regfile's own bypass
rather than fwding, since fwding only feeds into EX.

*/

module pipelined_cpu(
  input clk,
  input rst_n);

  //CROSS STAGE CTRL WIRES (decl here, driven later)
  wire [31:0] id_redirect_pc;
  wire [31:0] ex_correct_pc;
  wire        hazard_stall;    //load use stall, from hazard_detect
  wire        id_redirect;     //branch prediction/jmp , decided in ID
  wire        ex_flush;       //Ex stage misprediction correction

  //IF STAGE
  logic [31:0] pc, pc_plus4;
  logic [31:0] if_instr;

  wire [31:0] pc_next = ex_flush      ? ex_correct_pc    :
                        id_redirect   ? id_indirect_pc   :
                        hazard_stall  ? pc               :
                                        pc_plus4;

  pc_reg u_pc (.*); // is this the correct syntax? i forger

  assign pc_plus4 = pc + 32'd4;

  instr_mem u_instr_mem (.addr(pc), .instr(if_instr)); //

  /*
  //flush on either redirect source; hazard stall can never be true in the same cycle as ex_flush (they key off ID/EX's single current 
  //instruction , which can't simiultaneously be a ld and a branch). but flush is checked first in if_id_reg regardless, so the priority 
  is unambiguous even if that ever changed.
  */

  wire if_id_flush = ex_flush || id_redirect;

  logic [31:0] id_pc, id_pc_plus4, id_instr;

  if_id_reg u_if_id (
    .clk           (clk),
    .rst_n         (rst_n),
    .stall         (hazard_stall),
    .flush         (if_id_flush),
    .pc_in         (pc),
    .pc_plus4_in   (pc_plus4),
    .instr_in      (if_instr),
    .pc_out        (id_pc),
    .pc_plus4_out  (id_pc_plus4),
    .instr_out     (id_instr)
  );
  /*?* fi;;;ll the rest later*/


  //ID Stage

  wire [6:0] id_opcode = id_instr[6:0];
  wire [4:0] id_rd     = id_instr[11:7];
  wire [2:0] id_funct3 = id_instr[14:12];
  wire [4:0] id_rs1    = id_instr[19:15];
  wire [4:0] id_rs2    = id_instr[24:20];
  wire [6:0] id_funct7 = id_instr[31:25];

  wire id_alu_src, id_mem2reg, id_reg_wr;
  wire id_mem_rd, id_mem_wr, id_bra, id_jump;
  wire id_alu_ctrl;

  control_unit u_control (
    .opcode      (id_opcode),
    .funct3      (id_funct3),
    .funct7      (id_funct7),
    .alu_src     (id_alu_src),
    .mem2reg     (id_mem2reg),
    .reg_wr      (id_reg_wr),
    .mem_rd      (id_mem_rd),
    .mem_wr      (id_mem_wr),
    .bra         (id_bra),
    .jump        (id_jump),
    .alu_ctrl    (id_alu_ctrl)
  );

  //rd sits at the same bit position in RV32I

  wire [4:0] id_wr_reg = id_rd;

  //WB stage signals
  wire [31:0] wb_write_back_data;
  wire [4:0]  wb_wr_reg;
  wire        wb_reg_wr;

  wire [31:0] id_rd_data1, id_rd_data2;

  regfile u_regfile (
    .clk         (clk),
    .rst_n       (rst_n),
    .rd_reg1     (id_rs1),
    .rd_reg2     (id_rs2),
    .wr_reg      (wb_wr_reg),
    .wr_data     (wb_write_back_data),
    .wr_en       (wb_reg_wr),
    .rd_data1    (id_rd_data1),
    .rd_data2    (id_rd_data2)
  );

  //the four RV32I fmts this ISA subset  needs.
  //byte granular: bit 0 forced 0, doesnt need a lftshft. b and j type instrs
  wire [31:0] id_imm_i = {{20{id_instr[31]}}, id_instr[31:20]};
  wire [31:0] id_imm_s = {{20{id_instr[31]}}, id_instr[31:25], id_instr[11:7]};
  wire [31:0] id_imm_b = {{19{id_instr[31]}}, id_instr[31], id_intr[7], 
                          id_instr[30:25], id_instr[11:8], 1'b0}; //i dont get this
  wire [31:0] id_imm_j = {{11{id_instr[31]}}, id_instr[31], id_instr[19:12],
                          id_instr[20], id_instr[30:21], 1'b0};

  //alu operand immediate: addi/lw use the I fmt, sw uses the S fmt (the field layout differs).
  // id_mem_wr uniquely selects sw among everything that sets alu_src, so no separate selctor sig is needed

  
  wire [31:0] id_sext_imm = id_mem_wr ? id_imm_s : id_imm_i;
  wire [31:0] id_brat     = id_pc + id_imm_b;
  wire [31:0] id_jump_tgt = id_pc + id_imm_j;

  //branch prediction: read this cycle's global couner state for whichever instruction is in ID; EX trains it
  wire pred_takn;
  wire bp_update, bp_actual_takn;

  branch_predictor_2bit u_bra_pred (
    .clk           (clk),
    .rst_n         (rst_n),
    .update        (bp_update),
    .branch_taken  (bp_actual_takn),
    .predict_taken (pred_takn)
  ); 

  wire id_branch_redirect = id_bra && pred_takn;
  wire id_jump_redirect   = id_jump;
  assign id_redirect      = id_branch_redirect || id_jump_indirect;
  assign id_redirect_pc   = id_jump_redirect ? id_jump_tgt : id_brat;

  //hazard detection against the instruction currently in EX (ID/X reg outputs, )

  wire ex_mem_rd;
  wire [4:0] ex_wr_reg;

  hazard_detect u_hazard (
    .id_opcode    (id_opcode),
    .id_rs1       (id_rs1),
    .id_rs2       (id_rs2),
    .ex_mem_rd    (ex_mem_rd),
    .ex_wr_reg    (ex_wr_reg),
    .stall        (hazard_stall)
  );

  //bubbled by either a load-use stall (delays this ID-stqage ionstr by once cycle) or an ESX stage mispred flush (discards
  //this ID stage instr outright)
  wire id_ex_bubble = hazard_stall || ex_flush;

  wire [31:0] ex_rd_data1, ex_rd_data2, ex_sext_imm;
  wire [31:0] ex_pc_plus4, ex_bra_tgt;
  wire [4:0]  ex_rs1, ex_rs2;
  wire        ex_reg_wr, ex_mem_wr, ex_mem2reg;
  wire        ex_alu_src, ex_branch, ex_pred_takn;
  wire [2:0]  ex_alu_ctrl;

  id_ex_reg u_id_ex (
    .clk                (clk),
    .rst_n              (rst_n),
    .bubble             (id_ex_bubble),
    .rd_data1_in        (id_rd_data1),
    .rd_data2_in        (id_rd_data2),
    //continue
  
  //continue 
  
