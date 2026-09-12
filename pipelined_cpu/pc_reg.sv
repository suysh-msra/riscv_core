/*
pc register. a plain "load pc_next"latch.
*/

module pc_reg(
  output [31:0] pc,
  input  [31:0] pc_next,
  input         clk,
  input         rst_n
);
  logic [31:0] pc_r;

  always @(posedge clk) begin
    if (!rst_n) pc_r <= 32'd0;
    else        pc_r <= pc_next;
  end

  assign pc = pc_r;
endmodule
