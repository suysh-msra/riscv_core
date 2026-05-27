# Phase 1 RV32I interpreter for MicroPython / CPython.
#
# This is intentionally verbose: every cycle prints fetch, decode,
# execute, PC movement, and register/memory changes.


OP_RTYPE = 0x33
OP_ITYPE = 0x13
OP_LOAD = 0x03
OP_STORE = 0x23
OP_BRANCH = 0x63
OP_JAL = 0x6F
OP_JALR = 0x67


REG_NAMES = (
    "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
    "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
    "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
    "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6",
)


def u32(value):
    return value & 0xFFFFFFFF


def s32(value):
    value &= 0xFFFFFFFF
    if value & 0x80000000:
        return value - 0x100000000
    return value


def sign_extend(value, bits):
    sign = 1 << (bits - 1)
    value &= (1 << bits) - 1
    return (value ^ sign) - sign


def reg_name(index):
    return "x%d/%s" % (index, REG_NAMES[index])


class RV32I:
    def __init__(self, mem_size=4096, trace=True):
        self.regs = [0] * 32
        self.pc = 0
        self.mem = bytearray(mem_size)
        self.running = False
        self.trace = trace
        self.cycle = 0

    def reset(self, pc=0):
        self.regs = [0] * 32
        self.pc = pc
        self.running = False
        self.cycle = 0
        for i in range(len(self.mem)):
            self.mem[i] = 0

    def check_addr(self, addr, size):
        if addr < 0 or addr + size > len(self.mem):
            raise Exception("memory access out of range: addr=%d size=%d" % (addr, size))

    def load_u32(self, addr):
        self.check_addr(addr, 4)
        return (
            self.mem[addr]
            | (self.mem[addr + 1] << 8)
            | (self.mem[addr + 2] << 16)
            | (self.mem[addr + 3] << 24)
        )

    def store_u32(self, addr, value):
        self.check_addr(addr, 4)
        value &= 0xFFFFFFFF
        self.mem[addr] = value & 0xFF
        self.mem[addr + 1] = (value >> 8) & 0xFF
        self.mem[addr + 2] = (value >> 16) & 0xFF
        self.mem[addr + 3] = (value >> 24) & 0xFF

    def load_program(self, words, base_addr=0):
        addr = base_addr
        for word in words:
            self.store_u32(addr, word)
            addr += 4
        self.pc = base_addr

    def read_reg(self, index):
        if index == 0:
            return 0
        return self.regs[index] & 0xFFFFFFFF

    def write_reg(self, index, value):
        if index == 0:
            if self.trace:
                print("    write x0 ignored (x0 is hardwired to zero)")
            return
        old = self.regs[index]
        self.regs[index] = value & 0xFFFFFFFF
        if self.trace:
            print(
                "    %s: 0x%08x (%d) -> 0x%08x (%d)"
                % (reg_name(index), old & 0xFFFFFFFF, s32(old), self.regs[index], s32(self.regs[index]))
            )

    def decode(self, instr):
        opcode = instr & 0x7F
        rd = (instr >> 7) & 0x1F
        funct3 = (instr >> 12) & 0x07
        rs1 = (instr >> 15) & 0x1F
        rs2 = (instr >> 20) & 0x1F
        funct7 = (instr >> 25) & 0x7F

        info = {
            "instr": instr,
            "opcode": opcode,
            "rd": rd,
            "funct3": funct3,
            "rs1": rs1,
            "rs2": rs2,
            "funct7": funct7,
            "name": "UNKNOWN",
            "imm": 0,
        }

        if opcode == OP_RTYPE:
            if funct3 == 0x0 and funct7 == 0x00:
                info["name"] = "ADD"
            elif funct3 == 0x0 and funct7 == 0x20:
                info["name"] = "SUB"
            elif funct3 == 0x7 and funct7 == 0x00:
                info["name"] = "AND"
            elif funct3 == 0x6 and funct7 == 0x00:
                info["name"] = "OR"
            elif funct3 == 0x4 and funct7 == 0x00:
                info["name"] = "XOR"

        elif opcode == OP_ITYPE:
            info["imm"] = sign_extend(instr >> 20, 12)
            if funct3 == 0x0:
                info["name"] = "ADDI"

        elif opcode == OP_LOAD:
            info["imm"] = sign_extend(instr >> 20, 12)
            if funct3 == 0x2:
                info["name"] = "LW"

        elif opcode == OP_STORE:
            imm = ((instr >> 7) & 0x1F) | (((instr >> 25) & 0x7F) << 5)
            info["imm"] = sign_extend(imm, 12)
            if funct3 == 0x2:
                info["name"] = "SW"

        elif opcode == OP_BRANCH:
            imm = (
                (((instr >> 31) & 0x1) << 12)
                | (((instr >> 7) & 0x1) << 11)
                | (((instr >> 25) & 0x3F) << 5)
                | (((instr >> 8) & 0xF) << 1)
            )
            info["imm"] = sign_extend(imm, 13)
            if funct3 == 0x0:
                info["name"] = "BEQ"
            elif funct3 == 0x1:
                info["name"] = "BNE"

        elif opcode == OP_JAL:
            imm = (
                (((instr >> 31) & 0x1) << 20)
                | (((instr >> 12) & 0xFF) << 12)
                | (((instr >> 20) & 0x1) << 11)
                | (((instr >> 21) & 0x3FF) << 1)
            )
            info["imm"] = sign_extend(imm, 21)
            info["name"] = "JAL"

        elif opcode == OP_JALR:
            info["imm"] = sign_extend(instr >> 20, 12)
            if funct3 == 0x0:
                info["name"] = "JALR"

        return info

    def print_decode(self, d):
        name = d["name"]
        if name in ("ADD", "SUB", "AND", "OR", "XOR"):
            print(
                "DECODE: %-4s opcode=0x%02x rd=%s rs1=%s rs2=%s"
                % (name, d["opcode"], reg_name(d["rd"]), reg_name(d["rs1"]), reg_name(d["rs2"]))
            )
        elif name in ("ADDI", "LW", "JALR"):
            print(
                "DECODE: %-4s opcode=0x%02x rd=%s rs1=%s imm=%d"
                % (name, d["opcode"], reg_name(d["rd"]), reg_name(d["rs1"]), d["imm"])
            )
        elif name == "SW":
            print(
                "DECODE: %-4s opcode=0x%02x rs2=%s rs1=%s imm=%d"
                % (name, d["opcode"], reg_name(d["rs2"]), reg_name(d["rs1"]), d["imm"])
            )
        elif name in ("BEQ", "BNE"):
            print(
                "DECODE: %-4s opcode=0x%02x rs1=%s rs2=%s imm=%d"
                % (name, d["opcode"], reg_name(d["rs1"]), reg_name(d["rs2"]), d["imm"])
            )
        elif name == "JAL":
            print(
                "DECODE: %-4s opcode=0x%02x rd=%s imm=%d"
                % (name, d["opcode"], reg_name(d["rd"]), d["imm"])
            )
        else:
            print("DECODE: UNKNOWN opcode=0x%02x raw=0x%08x" % (d["opcode"], d["instr"]))

    def execute(self, d):
        instr = d["instr"]
        name = d["name"]
        rd = d["rd"]
        rs1 = d["rs1"]
        rs2 = d["rs2"]
        imm = d["imm"]
        next_pc = self.pc + 4

        if instr == 0:
            print("EXEC: 0x00000000 encountered; treating as HALT")
            self.running = False
            return self.pc

        if name == "UNKNOWN":
            raise Exception("unknown/unsupported instruction 0x%08x at pc=0x%08x" % (instr, self.pc))

        a = self.read_reg(rs1)
        b = self.read_reg(rs2)

        if name == "ADD":
            print("EXEC: ADD  %s = %s + %s" % (reg_name(rd), reg_name(rs1), reg_name(rs2)))
            self.write_reg(rd, a + b)

        elif name == "SUB":
            print("EXEC: SUB  %s = %s - %s" % (reg_name(rd), reg_name(rs1), reg_name(rs2)))
            self.write_reg(rd, a - b)

        elif name == "AND":
            print("EXEC: AND  %s = %s & %s" % (reg_name(rd), reg_name(rs1), reg_name(rs2)))
            self.write_reg(rd, a & b)

        elif name == "OR":
            print("EXEC: OR   %s = %s | %s" % (reg_name(rd), reg_name(rs1), reg_name(rs2)))
            self.write_reg(rd, a | b)

        elif name == "XOR":
            print("EXEC: XOR  %s = %s ^ %s" % (reg_name(rd), reg_name(rs1), reg_name(rs2)))
            self.write_reg(rd, a ^ b)

        elif name == "ADDI":
            print("EXEC: ADDI %s = %s + %d" % (reg_name(rd), reg_name(rs1), imm))
            self.write_reg(rd, a + imm)

        elif name == "LW":
            addr = s32(a) + imm
            value = self.load_u32(addr)
            print("EXEC: LW   %s = mem[0x%08x] -> 0x%08x (%d)" % (reg_name(rd), addr, value, s32(value)))
            self.write_reg(rd, value)

        elif name == "SW":
            addr = s32(a) + imm
            print("EXEC: SW   mem[0x%08x] = %s -> 0x%08x (%d)" % (addr, reg_name(rs2), b, s32(b)))
            self.store_u32(addr, b)

        elif name == "BEQ":
            taken = a == b
            print("EXEC: BEQ  %s == %s ? %s" % (reg_name(rs1), reg_name(rs2), taken))
            if taken:
                next_pc = self.pc + imm

        elif name == "BNE":
            taken = a != b
            print("EXEC: BNE  %s != %s ? %s" % (reg_name(rs1), reg_name(rs2), taken))
            if taken:
                next_pc = self.pc + imm

        elif name == "JAL":
            print("EXEC: JAL  %s = pc+4, jump pc %+d" % (reg_name(rd), imm))
            self.write_reg(rd, self.pc + 4)
            next_pc = self.pc + imm

        elif name == "JALR":
            target = (a + imm) & 0xFFFFFFFE
            print("EXEC: JALR %s = pc+4, jump (%s + %d) & ~1" % (reg_name(rd), reg_name(rs1), imm))
            self.write_reg(rd, self.pc + 4)
            next_pc = target

        print("PC: 0x%08x -> 0x%08x" % (self.pc, next_pc))
        return next_pc

    def dump_regs(self):
        print("REGISTERS:")
        for base in range(0, 32, 4):
            parts = []
            for i in range(base, base + 4):
                parts.append("x%-2d=0x%08x" % (i, self.read_reg(i)))
            print("  " + "  ".join(parts))

    def step(self):
        instr = self.load_u32(self.pc)
        print("")
        print("===== cycle %d =====" % self.cycle)
        print("FETCH: pc=0x%08x instr=0x%08x" % (self.pc, instr))

        decoded = self.decode(instr)
        self.print_decode(decoded)

        next_pc = self.execute(decoded)
        self.pc = next_pc
        self.regs[0] = 0
        self.cycle += 1

    def run(self, max_cycles=100):
        self.running = True
        while self.running:
            if self.cycle >= max_cycles:
                print("STOP: max_cycles=%d reached" % max_cycles)
                break
            self.step()
        print("")
        print("Final state after %d cycles:" % self.cycle)
        self.dump_regs()


# Tiny assembler helpers for the Phase 1 subset.


def r_type(funct7, rs2, rs1, funct3, rd, opcode=OP_RTYPE):
    return (
        ((funct7 & 0x7F) << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x07) << 12)
        | ((rd & 0x1F) << 7)
        | (opcode & 0x7F)
    )


def i_type(imm, rs1, funct3, rd, opcode):
    return (
        ((imm & 0xFFF) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x07) << 12)
        | ((rd & 0x1F) << 7)
        | (opcode & 0x7F)
    )


def s_type(imm, rs2, rs1, funct3, opcode=OP_STORE):
    imm &= 0xFFF
    return (
        (((imm >> 5) & 0x7F) << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x07) << 12)
        | ((imm & 0x1F) << 7)
        | (opcode & 0x7F)
    )


def b_type(imm, rs2, rs1, funct3, opcode=OP_BRANCH):
    imm &= 0x1FFF
    return (
        (((imm >> 12) & 0x1) << 31)
        | (((imm >> 5) & 0x3F) << 25)
        | ((rs2 & 0x1F) << 20)
        | ((rs1 & 0x1F) << 15)
        | ((funct3 & 0x07) << 12)
        | (((imm >> 1) & 0xF) << 8)
        | (((imm >> 11) & 0x1) << 7)
        | (opcode & 0x7F)
    )


def j_type(imm, rd, opcode=OP_JAL):
    imm &= 0x1FFFFF
    return (
        (((imm >> 20) & 0x1) << 31)
        | (((imm >> 1) & 0x3FF) << 21)
        | (((imm >> 11) & 0x1) << 20)
        | (((imm >> 12) & 0xFF) << 12)
        | ((rd & 0x1F) << 7)
        | (opcode & 0x7F)
    )


def ADD(rd, rs1, rs2):
    return r_type(0x00, rs2, rs1, 0x0, rd)


def SUB(rd, rs1, rs2):
    return r_type(0x20, rs2, rs1, 0x0, rd)


def AND(rd, rs1, rs2):
    return r_type(0x00, rs2, rs1, 0x7, rd)


def OR(rd, rs1, rs2):
    return r_type(0x00, rs2, rs1, 0x6, rd)


def XOR(rd, rs1, rs2):
    return r_type(0x00, rs2, rs1, 0x4, rd)


def ADDI(rd, rs1, imm):
    return i_type(imm, rs1, 0x0, rd, OP_ITYPE)


def LW(rd, rs1, imm):
    return i_type(imm, rs1, 0x2, rd, OP_LOAD)


def SW(rs2, rs1, imm):
    return s_type(imm, rs2, rs1, 0x2)


def BEQ(rs1, rs2, imm):
    return b_type(imm, rs2, rs1, 0x0)


def BNE(rs1, rs2, imm):
    return b_type(imm, rs2, rs1, 0x1)


def JAL(rd, imm):
    return j_type(imm, rd)


def JALR(rd, rs1, imm):
    return i_type(imm, rs1, 0x0, rd, OP_JALR)


def demo_program():
    # Uses data memory at address 128 so it does not overwrite instructions.
    # x1 = 10
    # x2 = 20
    # x3 = x1 + x2 = 30
    # mem[128] = x3
    # x4 = mem[128]
    # x5 = x4 - x1 = 20
    # branch tests and skips one ADDI
    return [
        ADDI(1, 0, 10),
        ADDI(2, 0, 20),
        ADD(3, 1, 2),
        SW(3, 0, 128),
        LW(4, 0, 128),
        SUB(5, 4, 1),
        XOR(6, 4, 5),
        OR(7, 6, 1),
        AND(8, 7, 4),
        BEQ(4, 3, 8),      # taken: skip next instruction
        ADDI(9, 0, 111),   # skipped
        BNE(5, 2, 8),      # not taken
        JAL(10, 8),        # x10 = return addr, skip next instruction
        ADDI(11, 0, 222),  # skipped
        ADDI(12, 0, 333),
        0,                 # HALT sentinel for this simulator
    ]


if __name__ == "__main__":
    cpu = RV32I(mem_size=512, trace=True)
    cpu.load_program(demo_program(), base_addr=0)
    cpu.run(max_cycles=50)
