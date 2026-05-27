# riscv_core
a repo for a Riscv compatible CPU. 

Pico RISC-V Processor Learning Repo
Phase 1 is a deliberately simple RV32I interpreter written in plain Python that should also run on MicroPython.

Phase 1: RV32I ISA Interpreter
Implemented in rv32i_phase1.py:

32 integer registers, with x0 hardwired to zero
Program counter (pc)
Unified byte-addressed memory array
Fetch/decode/execute loop
Verbose cycle-by-cycle tracing
Instructions:
ADD, SUB, AND, OR, XOR
ADDI
LW, SW
BEQ, BNE
JAL, JALR
The simulator treats instruction word 0x00000000 as a halt sentinel so demo programs have a simple way to stop.

the core loop:
instr = self.load_u32(self.pc)
decoded = self.decode(instr)
next_pc = self.execute(decoded)
self.pc = next_pc


