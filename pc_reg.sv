//the program counter register

module pc_reg(
  input [31:0] pc_next,
  input        clk,
  input        rst_n,
  output       pc
);
  logic [31:0] pc_r;

  always @(posedge clk) begin
    if (!rst_n) pc_r <= 32'b0;
    else        pc_r <= pc_next;
  end

  assign pc = pc_r;
endmodule
