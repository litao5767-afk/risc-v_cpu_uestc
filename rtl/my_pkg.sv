package my_pkg;
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter MEM_DATA_DEPTH  = 4096;
    parameter MEM_INST_DEPTH  = 4096;

    // Memory operation encoding
    parameter MEM_LB  = 3'b000;
    parameter MEM_LH  = 3'b001;
    parameter MEM_LW  = 3'b010;
    parameter MEM_LBU = 3'b011;
    parameter MEM_LHU = 3'b100;
    parameter MEM_SB  = 3'b101;
    parameter MEM_SH  = 3'b110;
    parameter MEM_SW  = 3'b111;

    //ALU operation encoding
    parameter ALU_ADD  = 4'b0000;
    parameter ALU_SUB  = 4'b1000;
    parameter ALU_SLL  = 4'b0001;
    parameter ALU_SLT  = 4'b0010;
    parameter ALU_SLTU = 4'b1010;
    parameter ALU_XOR  = 4'b0100;
    parameter ALU_SRL  = 4'b0101;
    parameter ALU_SRA  = 4'b1101;
    parameter ALU_OR   = 4'b0110;
    parameter ALU_AND  = 4'b0111;
    parameter ALU_LUI  = 4'b0011;

    // ALU source encoding: [2:1] = operand2 select (00=rs2,01=imm,10=const4), [0]=operand1 select (0=rs1,1=pc)
    parameter ALU_SRC_RS1_RS2 = 3'b000; // rs1, rs2
    parameter ALU_SRC_RS1_IMM  = 3'b010; // rs1, imm
    parameter ALU_SRC_PC_IMM   = 3'b011; // pc, imm (used by AUIPC)
    parameter ALU_SRC_PC_4     = 3'b101; // pc, constant 4 (used by JAL/JALR)

    // branch encodings used by controller / nextpc_gen
    parameter BR_NONE  = 3'b000; // no branch
    parameter BR_JAL   = 3'b001; // jal
    parameter BR_JALR  = 3'b010; // jalr
    parameter BR_BEQ   = 3'b100; // beq
    parameter BR_BNE   = 3'b101; // bne
    parameter BR_BLT   = 3'b110; // blt / bltu
    parameter BR_BGE   = 3'b111; // bge / bgeu
endpackage