//IF/ID pipeline reg. 
//two independent controls: 'stall' holds the current contxt (used for a ld-use hazz, so the stalled instr gets re-decoded next cyc)
//'flush' squashes to a nop (used for branch/jump redirect decided in ID, or an EX stage mispred correcting an older branch)

//bubble -> instr = 0 -> default case of ctrl_u , a noop
module if_id_reg(
  input         clk,
  input         rst_n,
  input         stall,
  input         flush,
  input  [31:0] pc_in,
  input  [31:0] pc_plus4_in,
  input  [31:0] instr_in,
  output [31:0] pc_out,
  output [31:0] pc_plus4_out,
  output [31:0] instr_out
);
  logic [31:0] pc_r, pc_plus4_r, instr_r;

  always @(posedge clk) begin
    if (!rst_n) begin
      pc_r       <= 32'd0;
      pc_plus4_r <= 32'd0;
      instr_r    <= 32'd0;
      
    end else if (flush) begin
      instr_r    <= 32'd0; //separate as we dont want to quash pc/pc+4 
    end else if (!stall) begin
      pc_r       <= pc_in;
      pc_plus4_r <= pc_plus4_in;
      instr_r    <= instr_in;
    end 
  //else: stall. hold everything as is
  end 

  assign pc_out       = pc_r;
  assign pc_plus4_out = pc_plus4_r;
  assign instr_out    = instr_r;
endmodule
