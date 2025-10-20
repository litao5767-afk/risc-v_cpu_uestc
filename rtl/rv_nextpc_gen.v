// ============================================================================
// Module: rv_nextpc_gen
// Author: QiShui47
// Created: 2025-10-09
// Description: 
// - NextPC Generator(Dedicated Adder)
// ============================================================================
import my_pkg::*;
module rv_nextpc_gen(
    input  wire                      zero       ,
    input  wire                      less       ,
    input  wire [2 : 0]              branch     ,
    input  wire [ADDR_WIDTH - 1 : 0] pc         ,
    input  wire [DATA_WIDTH - 1 : 0] rs         ,
    input  wire [DATA_WIDTH - 1 : 0] imm        ,
    output reg  [ADDR_WIDTH - 1 : 0] nextpc
    );

    always @(*) begin
        case(branch)
            BR_NONE: // 不跳转
                nextpc = pc + 4;
            BR_BEQ: // beq 相等时跳转
                nextpc = (zero) ? (pc + imm) : (pc + 4);
            BR_BNE: // bne 不等时跳转
                nextpc = (zero) ? (pc + 4) : (pc + imm);
            BR_BLT: // blt/bltu 小于时跳转
                nextpc = (less) ? (pc + imm) : (pc + 4);
            BR_BGE: // bge/bgeu 大于或等于时跳转
                nextpc = (!less) ? (pc + imm) : (pc + 4);
            BR_JAL: // jal  强制跳转至 PC+IMM
                nextpc = pc + imm;
            BR_JALR: // jalr 强制跳转至 RS+IMM，且最低位强制为0
                nextpc = (rs + imm) & {{(ADDR_WIDTH-1){1'b1}}, 1'b0};
            default:
                nextpc = pc + 4;
        endcase
    end
endmodule