//load-use hazard detection. If the instruction currently in EX is a load whose destination mathces a src reg actually read by 
//instr currently in ID, a sin cyc stll is reqd, the ld data doesnt exist yet. after the stall cycle, MEM/WB fwding covers it.

//uses_rs2 diffs between instr fmts where rs2 (inst[24:20]) is a real src reg (R-type, sw, beq) from others.

module hazard_detect(
  input [6:0] id_op,
  input [4:0] id_rs1, id_rs2,
  input       ex_mem_rd,
  input [4:0] ex_wr_reg,
  output      stall);

  localparam [6:0] OP_RTYPE = 7'b0110011;
  localparam [6:0] OP_STORE = 7'b0100011;
  localparam [6:0] OP_BRA   = 7'b1100011;

  wire uses_rs2 = (ip_op == OP_RTYPE) || (id_op == OP_STORE) || (id_op ==OP_BRA);//i wish there was a slicker way

  assign stall = ex_mem_rd && (ex_wr_reg != 5'd0) &&
                  ((ex_wr_reg == id_rs1) || (uses_rs2 && (ex_wr_reg == id_rs2)));

endmodule
  
