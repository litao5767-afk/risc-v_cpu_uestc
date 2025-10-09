// ============================================================================
// Module: rv_nextpc_gen
// Author: QiShui47
// Created: 2025-10-09
// Description: 
// - NextPC Generator(Dedicated Adder)
// ============================================================================
module rv_nextpc_gen(
    input             zero,
    input             less,
    input      [2:0]  branch,
    input      [31:0] pc,
    input      [31:0] rs,
    input      [31:0] imm,
    output reg [31:0] nextpc
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
        3'b001://jal  无条件跳转至pc目标
        begin
            nextpc = pc + imm;
        end
        3'b010://jalr 无条件跳转至寄存器目标
        begin
            nextpc = rs + imm;
        end
    endcase
end
endmodule