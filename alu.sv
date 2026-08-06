//alu.sv 

//single cycle CPU ALU
//add,sub,and, or, set less than

module alu(
  input [31:0] a,
  input [31:0] b,
  input  [2:0] alu_ctrl, //010 ADD,110 SUB, 000 AND, 001 OR, 111 SLT
  output [31:0] result,
  output zero
);
  logic [31:0] result_r;
  always @(*) begin
    case (alu_ctrl)
      3'b000: result_r = a & b;
      3'b001: result_r = a | b;
      3'b010: result_r = a + b;
      3'b110: result_r = a - b;
      3'b111: result_r = ($signed(a) < $signed(b));
      default: result_r = 32'd0;
    endcase
  end

  assign result = result_r;
  assign zero   = (result_r == 32'b0);
  
endmodule
