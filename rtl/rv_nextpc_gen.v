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
        3'b000://����ת
        begin
            nextpc = pc + const;
        end
        3'b100://beq ���ʱ��ת
        begin
            if(!zero)
                nextpc = pc + const;
            else
                nextpc = pc + imm;
        end
        3'b101://bne ����ʱ��ת
        begin
            if(zero)
                nextpc = pc + const;
            else
                nextpc = pc + imm;
        end
        3'b110://blt bltu С��ʱ��ת
        begin
            if(!less)
                nextpc = pc + const;
            else
                nextpc = pc + imm;
        end
        3'b111://bge bgeu ����ʱ��ת
        begin
            if(zero||less)
                nextpc = pc + const;
            else
                nextpc = pc + imm;
        end
        3'b001://jal  ��������ת��pcĿ��
        begin
            nextpc = pc + imm;
        end
        3'b010://jalr ��������ת���Ĵ���Ŀ��
        begin
            nextpc = rs + imm;
        end
    endcase
end
endmodule