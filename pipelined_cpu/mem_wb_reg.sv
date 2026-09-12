//mem/wb piepline reg, always advances. wb data is already the fully mux'd value
//computed once in the MEM stage, so this reg and the regfile wr port downstream dont need t redo that mux.

module mem_wb_reg(
  input         clk,
  input         rst_n,
  input  [31:0] wb_data_in,
  input  [4:0]  wr_reg_in,
  input         reg_wr_in,
  
  output [31:0] wb_data_out,
  output [4:0]  wr_reg_out,
  output        reg_wr_out
);
  logic [31:0] wb_data_r;
  logic [4:0]  wr_reg_r;
  logic        reg_wr_r;

  always @(posedge clk) begin
    if (!rst_n) begin
      wb_data_r  <= 32'd0;
      wr_reg_r   <= 5'd0;
      reg_wr_r   <= 1'b0;
    end else begin
      wb_data_r  <= wb_data_in;
      wr_reg_r   <= wr_reg_in;
      reg_wr_r   <= reg_wr_in;
    end
  end

  assign wb_data_out  = wb_data_r;
  assign wr_reg_out   = wr_reg_r;
  assign reg_wr_out   = reg_wr_r;
endmodule
