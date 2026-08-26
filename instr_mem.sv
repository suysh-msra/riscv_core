//TODO:
//write a program in binary to this memory
//that exercises every supported instruction

module instr_mem (
  input [31:0] addr,
  output [31:0] instr
);
  logic [31:0] mem [0:63];

  initial begin
    int i;
    for (i = 0; i < 64; i++)
      mem[i] = 32'h0;
  end

  assign instr = mem[addr[31:2]];
endmodule
