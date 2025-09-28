module rv_controller(
    input [31:0] inst,
    output reg [2:0] Branch, //跳转
    output reg Mem_Read,
    output reg Mem_Write,
    output reg Mem_to_Reg,
    output reg [3:0] ALU_OP, //ALU控制指令
    output reg [2:0] ALU_SRC,//低1位表示操作数1选择rs1(0)/PC(1)，高2位表示操作数2选择rs2(00)/imm(01)/常数4(10)
    output reg Reg_Write     //寄存器写入请求
    );
//Intruction Decode//
wire [6:0] funct7,opcode;
wire [4:0] rs1,rs2,rd;
wire [2:0] funct3;
assign funct7 = inst[31:25];
assign rs2    = inst[24:20];
assign rs1    = inst[19:15];
assign funct3 = inst[14:12];
assign rd     = inst[11:7];
assign opcode = inst[6:0];
always@(*)
begin
    case(opcode[6:2])
        5'b01100://R-Type 寄存器类型
        begin
            ALU_SRC = 3'b00_0;
            Reg_Write = 1'b1;//需写回寄存器rd
            Branch = 3'b000;
            case({funct7[5],funct3})
                4'b0_000://ADD
                begin
                    ALU_OP = 4'b0000;
                end
                4'b1_000://SUB
                begin
                    ALU_OP = 4'b1000;
                end
                4'b0_001://SLL 逻辑左移
                begin
                    ALU_OP = 4'b0001;
                end
                4'b0_010://SLT 算数小于
                begin
                    ALU_OP = 4'b0010;
                end
                4'b0_011://SLTU 逻辑小于（无符号数）
                begin
                    ALU_OP = 4'b1010;
                end
                4'b0_100://XOR 异或
                begin
                    ALU_OP = 4'b0100;
                end
                4'b0_101://SRL 逻辑右移（高位补0）
                begin
                    ALU_OP = 4'b0101;
                end
                4'b1_101://SRA 算数右移（高位补符号位）
                begin
                    ALU_OP = 4'b1101;
                end
                4'b0_110://OR 按位或
                begin
                    ALU_OP = 4'b0110;
                end
                4'b0_111://AND 按位与
                begin
                    ALU_OP = 4'b0111;
                end
                default://错误编码
                begin
                    ALU_OP = 4'b0;
                end
            endcase
        end
        5'b00000://I-Type 短立即数类型
        begin
            
        end
        5'b11000://B-Type 条件跳转类型
        begin
            
        end
        5'b11011://J-Type JAL无条件跳转类型
        begin
            //ALU执行的操作是计算PC+4
            ALU_OP = 4'b0000;
            ALU_SRC = 3'b10_1;//PC+4
            Reg_Write = 1'b1;
            Branch = 3'b001;//跳转至PC目标
        end
        5'b11001://J-Type JALR无条件跳转类型
        begin
            //ALU执行的操作是计算PC+4
            ALU_OP = 4'b0000;
            ALU_SRC = 3'b10_1;
            Reg_Write = 1'b1;
            Branch = 3'b010;//跳转至寄存器目标
        end
        5'b01000://S-Type 内存存储类型
        begin
            
        end
        5'b01101://U-Type LUI高位立即数类型
        begin
            ALU_OP = 4'b0011;
            ALU_SRC = 3'b01_0;//仅使用立即数
            Reg_Write = 1'b1;
            Branch = 3'b000;
        end
        5'b00101://U-Type AUIPC高位立即数类型
        begin
            ALU_OP = 4'b0000;
            ALU_SRC = 3'b01_1;//PC+IMM
            Reg_Write = 1'b1;
            Branch = 3'b000;
        end
        default:
        begin
            
        end
    endcase
end
endmodule
