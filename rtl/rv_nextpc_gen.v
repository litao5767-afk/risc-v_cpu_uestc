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
    output reg  [ADDR_WIDTH - 1 : 0] nextpc     ,
    output reg                       br_taken
    );

    always @(*) begin
        case(branch)
            BR_NONE: // 不跳转
            begin
                nextpc = pc + 4;
                br_taken = 1'b0;
            end
            BR_BEQ: // beq 相等时跳转
            begin
                nextpc = (zero) ? (pc + imm) : (pc + 4);
                br_taken = (zero) ? 1'b1 : 1'b0;
            end
            BR_BNE: // bne 不等时跳转
            begin
                nextpc = (zero) ? (pc + 4) : (pc + imm);
                br_taken = (zero) ? 1'b0 : 1'b1;
            end
            BR_BLT: // blt/bltu 小于时跳转
            begin
                nextpc = (less) ? (pc + imm) : (pc + 4);
                br_taken = (less) ? 1'b1 : 1'b0;
            end
            BR_BGE: // bge/bgeu 大于或等于时跳转
            begin
                nextpc = (!less) ? (pc + imm) : (pc + 4);
                br_taken = (!less) ? 1'b1 : 1'b0;
            end
            BR_JAL: // jal  强制跳转至 PC+IMM
            begin
                nextpc = pc + imm;
                br_taken = 1'b1;
            end
            BR_JALR: // jalr 强制跳转至 RS+IMM，且最低位强制为0
            begin
                nextpc = (rs + imm) & {{(ADDR_WIDTH-1){1'b1}}, 1'b0};
                br_taken = 1'b1;
            end
            default:
            begin
                nextpc = pc + 4;
                br_taken = 1'b0;
            end
        endcase
    end
endmodule