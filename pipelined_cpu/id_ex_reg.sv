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
  input         reg_wr_in, mem_rd_in, mem_wr_in, mem2reg_in,
  input         alu_src_in, bra_in, pred_takn_in, //predicted_taken_in
  input  [2:0]  alu_ctrl_in,
  
  output [31:0] rd_data1_out, rd_data2_out,
  output [31:0] sext_imm_out,
  output [31:0] pc_plus4_out, brat_out,
  output [4:0]  rs1_out, rs2_out, wr_reg_out,
  output        reg_wr_out, mem_rd_out, mem_wr_out, mem2reg_out,
  output        alu_src_out, bra_out, pred_takn_out,
  output [2:0]  alu_ctrl_out
);
  logic  [31:0] rd_data1_r, rd_data2_r, sext_imm_r, pc_plus4_r, brat_r;
  //need to add logic and logic for register nehavior
  logic  [4:0]  rs1_r, rs2_r, wr_reg_r;
  logic         reg_wr_r, mem_rd_r, mem_wr_r, mem2reg_r;
  logic         alu_src_r, bra_r, pred_takn_r;
  logic  [2:0]  alu_ctrl_r;

  always @(posedge clk) begin
    if(!rst_n || bubble) begin
      rd_data1_r     <= 32'd0;
      rd_data2_r     <= 32'd0;
      sext_imm_r     <= 32'd0;
      pc_plus4_r     <= 32'd0;
      brat_r         <= 32'd0;
      rs1_r          <= 5'd0;
      rs2_r          <= 5'd0;
      wr_reg_r       <= 5'd0;
      reg_wr_r       <= 1'b0;
      mem_rd_r       <= 1'b0;
      mem_wr_r       <= 1'b0;
      mem2reg_r      <= 1'b0;
      alu_src_r      <= 1'b0;
      bra_r          <= 1'b0;
      pred_takn_r    <= 1'b0;
      alu_ctrl_r     <= 3'b010; //whyyyy
    end else begin
      rd_data1_r     <= rd_data1_in;
      rd_data2_r     <= rd_data2_in;
      sext_imm_r     <= sext_imm_in;
      pc_plus4_r     <= pc_plus4_in;
      brat_r         <= brat_in;
      rs1_r          <= rs1_in;
      rs2_r          <= rs2_in;
      wr_reg_r       <= wr_reg_in;
      reg_wr_r       <= reg_wr_in;
      mem_rd_r       <= mem_rd_in;
      mem_wr_r       <= mem_wr_in;
      mem2reg_r      <= mem2reg_in;
      alu_src_r      <= alu_src_in;
      bra_r          <= bra_in;
      pred_takn_r    <= pred_takn_in;
      alu_ctrl_r     <= alu_ctrl_in;
    end
  end

  assign rd_data1_out = rd_data1_r;
  assign rd_data2_out = rd_data2_r;
  assign sext_imm_out = sext_imm_r;
  assign pc_plus4_out = pc_plus4_r;
  assign brat_out     = brat_r;
  assign rs1_out      = rs1_r;
  assign rs2_out      = rs2_r;
  assign wr_reg_out   = wr_reg_r;
  assign reg_wr_out   = reg_wr_r;
  assign mem_rd_out   = mem_rd_r;
  assign mem_wr_out   = mem_wr_r;
  assign mem2reg_out  = mem2reg_r;
  assign alu_src_out  = alu_src_r;
  assign bra_out      = bra_r;
  assign pred_takn_out = pred_takn_r;
  assign alu_ctrl_out = alu_ctrl_r;
endmodule
  
