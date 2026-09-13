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

  /*?* fi;;;ll the rest later*/
  
