module instr_mem(
  input  [31:0] addr,
  output [31:0] instr
);
  logic [31:0] mem [0:63];

  initial begin
    int i;
    for (i = 0; i < 64; i++) mem[i] = 32'h0;

    mem[0] = 32'h500093; //addi x1,x0, 5
    mem[1] = 32'hA00113; //addi x2, x0, 10
    mem[2] = 32'h2081B3; //add x3, x1, x2
    mem[3] = 32'h40110233; //sub x4, x2, x1
    mem[4] = 32'h302023; //./sw x3, 0, (x0)
    mem[5] = 32'h2283; //lw x5, 0, (x0)
    mem[6] = 32'h518463; //beq x3, x5,+8 (skip word 7)
    mem[7] = 32'h6300313; //addi who cares skipped
    mem[8] = 32'h700313; //addi x6, x0, 7 (bran tgt)
    mem[9] = 32'hC0006F; //jal x0,+12
    mem[10] = 32'h6F00393; //addi x7, x0, 111 (skipped)
    mem[11] = 32'hC01DB0D5; //garbage, aslo skipped
    mem[12] = 32'h2100393; //addi x7, x0, 33 (jump target)
  end

  assign instr = mem[addr[7:2]];
endmodule
