//see you
//supp inst: R type add/sub/and/or/slt
//addi,lw, sw, beq, j

module control_unit (
  input  [5:0] opcode,
  input  [5:0] funct,
  output       reg_dst,
  output       alu_src,
  output       mem_to_reg,
  output       reg_wr,
  output       mem_rd,
  output       mem_wr,
  output       bra,
  output       jum,
  output [2:0] alu_ctrl
);

  localparam OP_RTYPE       =  6'b000;
  localparam FUNCT_ADD      =  6'b0001000;
  localparam OP_ADDI        =  6'b100011;
  localparam FUNCT_SUB      =  6'b100010;
   localparam OP_LW         =  6'b100011;
  localparam FUNCT_AND      =  6'b100100;
  localparam OP_SW          =  6'b101011;
  localparam FUNCT_OR       =  6'b100101;
   localparam OP_BEQ        =  6'b0100;
  localparam FUNCT_SLT      =  6'b101010;
  localparam OP_J           =  6'b0010;
  //localparam FUNCT_    =  6'b000;

  logic reg_dst_r, alu_src_r, mem_to_reg_r, regwr_r;
  logic memrd_r, memwr_r, bra_r, jum_r;
  logic [1:0] alu_op; //selfexplanantory
  logic [2:0] alu_ctrl_r;
//TODO: rst logic for  above signals
  always @(*) begin
  case (opcode)
    OP_RTYPE: begin
      reg_dst_r = 1;
      regwr_r  = 1;
      alu_op = 2'b10;
    end

    OP_ADDI: begin
      alu_src_r = 1;//bad 
      regwr_r  = 1;
      alu_op = 2'b0;
    end
    OP_LW: begin
      alu_src_r = 1;
      mem_to_reg_r  = 1;
      alu_op = 2'b0;
      regwr_r = 1;
      memrd_r = 1;
    end

    OP_SW: begin
      alu_src_r = 1;
      memwr_r = 1;
      alu_op = 0;
    end

    OP_BEQ: begin
      bra_r = 1;
      alu_op = 0;
    end

    OP_J: begin
      jum_r = 1;
    end

    default : ;//unrecognized opcode

  endcase
  end
  
  always @(*) begin
    case (alu_op)
      2'b0 : alu_ctrl_r = 3'b10; //ADD
      2'b01: alu_ctrl_r = 3'b110; //SUB (beq)
      2'b10: begin
        case(funct)
          FUNCT_ADD : alu_ctrl_r = 3'b010;
          FUNCT_SUB : alu_ctrl_r = 3'b110;
          FUNCT_AND : alu_ctrl_r = 3'b0;
          FUNCT_OR  : alu_ctrl_r = 3'b001;
          FUNCT_SLT : alu_ctrl_r = 3'b111;
          default   : alu_ctrl_r = 3'b010;
        endcase
      end
      default : alu_ctrl_r = 3'd2;
    endcase
  end

  assign reg_dst     = reg_dst_r;
  assign alu_src     = alu_src_r;
  assign mem_to_reg  = mem_to_reg_r;
  assign reg_wr      = regwr_r;
  assign mem_rd      = memrd_r;
  assign mem_wr      = memwr_r;
  assign bra         = bra_r;
  assign jum         = jum_r;
  assign alu_ctrl    = alu_ctrl_r;
endmodule
