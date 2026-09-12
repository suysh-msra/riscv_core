// ID/EX pipeline register. 'bubble' (driven by a load/use stall or an EX-stage misprediction flush) forces every ctrl sig to its inactive value
//on the next edge , turning this slotinto a no-op. Data fields are zeroed alongside the ctrls purely for simulation determinism
//nothing dowstream ever reads them once ctrl sigs are inactive//

module id_ex_reg(
  input         clk,
  input         rst_n,
  input         bubble,
  //data
  input  [31:0] rd_data1_in, rd_data2_in,
  input  [31:0] sext_imm_in,
  input  [31:0] pc_plus4_in, brat_in, //branch_target_in
  input  [4:0]  rs1_in, rs2_in, wr_reg_in,
  //ctrl
  input         reg_wr_in, mem_rd_in, mem_wr_in, mem_to_reg_in,
  input         alu_src_in, bra_in, pred_taken_in, //predicted_taken_in
  input  [2:0]  alu_ctrl_in,
  
  output [31:0] rd_data1_out, rd_data2_out,
  output [31:0] sext_imm_out,
  output [31:0] pc_plus4_out, brat_out,
  output [4:0]  rs1_out, rs2_out, wr_reg_out,
  output        reg_wr_out, mem_rd_out, mem_wr_out, mem_to_reg_out,
  output        alu_src_out, bra_out, predicted_taken_out,
  output [2:0]  alu_ctrl_out
);
  logic  [31:0] rd_data1_r, rd_data2_r, sext_imm_r, pc_plus4_r, brat_r;
  //need to add logic and logic for register nehavior
endmodule
  
  
  
  t_out,
