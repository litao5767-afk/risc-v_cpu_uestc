// ============================================================================
// Module: rv_nextpc_gen
// Author: QiShui47
// Created: 2025-10-09
// Description: 
// - NextPC Generator(Dedicated Adder)
// ============================================================================
import my_pkg.sv::*;
module rv_nextpc_gen(
    input  wire                      zero       ,
    input  wire                      less       ,
    input  wire [2 : 0]              branch     ,
    input  wire [DATA_WIDTH - 1 : 0] pc         ,
    input  wire [DATA_WIDTH - 1 : 0] rs         ,
    input  wire [DATA_WIDTH - 1 : 0] imm        ,
    output reg  [DATA_WIDTH - 1 : 0] nextpc
    );
wire const;
assign const = 32'h00000004;
always@(*)
begin
    case(branch)
        3'b000://不跳转
        begin
            nextpc = pc + const;
        end
        3'b100://beq 相等时跳转
        begin
            if(!zero)
                nextpc = pc + const;
            else
                nextpc = pc + imm;
        end
        3'b101://bne 不等时跳转
        begin
            if(zero)
                nextpc = pc + const;
            else
                nextpc = pc + imm;
        end
        3'b110://blt bltu 小于时跳转
        begin
            if(!less)
                nextpc = pc + const;
            else
                nextpc = pc + imm;
        end
        3'b111://bge bgeu 大于时跳转
        begin
            if(zero||less)
                nextpc = pc + const;
            else
                nextpc = pc + imm;
        end
        3'b001://jal  强制跳转至PC+IMM
        begin
            nextpc = pc + imm;
        end
        3'b010://jalr 强制跳转至RS+IMM
        begin
            nextpc = rs + imm;
        end
        default:
        begin
            nextpc = pc + const;
        end
    endcase
end
endmodule