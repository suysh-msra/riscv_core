//EX stage operand forwarding.
//selects, for rs1 and rs2,
//among:
// regfile value read back in ID
// mem/wb stage's Write-back value, and
//EX/MEM stage's ALU rsult (more recent, so takes priority over MEM/Wb stage)

//fwd_b feeds both, the alu's b input and the store-data value carried into EX/MEM for a later sw
// sw's value-to-store bypasses the ALU entirely in this datapath, so it needs the same fwded value 
module forward_unit (
  input  [4:0] ex_rs1, ex_rs2,   //ID/EX.rs1/2
  input        mem_reg_wr,
  input  [4:0] mem_wr_reg,       //EX/MEM.write_reg
  input  [4:0] wb_wr_reg,        //MEM/WB.write_reg
  input        wb_reg_wr,        //MEM/WB.reg_write
  output [1:0] fwd_a,           //00=regfile, 01=MEM/WB, 10=EX/MEM 
  output [1:0] fwd_b
);
  wire mem_hit_rs1 = mem_reg_wr && (mem_wr_reg != 'd0) && (mem_wr_reg == ex_rs1);
  
  wire mem_hit_rs2 = mem_reg_wr && (mem_wr_reg != 'd0) && (mem_wr_reg == ex_rs2);
  
  wire wb_hit_rs1 = wb_reg_wr && (wb_wr_reg != 'd0) && (wb_wr_reg == ex_rs1);
  wire wb_hit_rs2 = wb_reg_wr && (wb_wr_reg != 'd0) && (wb_wr_reg == ex_rs1);

  assign fwd_a = mem_hit_rs1 ? 2'b10 : (wb_hit_rs1 ? 2'b01 : 2'b00);
  assign fwd_b = mem_hit_rs2 ? 2'b10 : (wb_hit_rs2 ? 2'b01 : 2'b00); 
endmodule
