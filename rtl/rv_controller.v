// ============================================================================
// Module: rv_controller
// Author: QiShui47
// Created: 2025-09-28
// Description: 
// - Instruction Decoder
// ============================================================================
import my_pkg.sv::*;
module rv_controller(
    input  wire [DATA_WIDTH - 1 : 0] inst        ,//指令码传入
    output reg                       mem_write   ,//Mem写使能
    output reg                       mem_to_reg  ,//从Mem写回Reg
    output reg                       reg_write   ,//从ALU写回Reg
    output reg  [2 : 0]              mem_op      ,//Mem读写格式（字节数/是否进行符号扩展）
    output reg  [3 : 0]              alu_op      ,//ALU控制指令
    output reg  [2 : 0]              alu_src     ,//低1位表示操作数1选择rs1(0)/pc(1)，高2位表示操作数2选择rs2(00)/imm(01)/常数4(10)
    output reg  [2 : 0]              imm_op      ,//立即数类型（对应top模块中的imm-gen部分）
    output reg  [2 : 0]              branch       //跳转类型
    );
//intruction decode//
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
        5'b01100://r-type 寄存器类型
        begin
            alu_src = 3'b00_0;
            reg_write = 1'b1;//需写回寄存器rd
            branch = 3'b000; //不跳转
            imm_op = 3'b000; //不生成立即数
            mem_write = 1'b0;
            mem_op = 3'b000;  //无需操作存储器
            mem_to_reg = 1'b0;
            case({funct7[5],funct3})
                4'b0_000://add
                    alu_op = 4'b0000;
                4'b1_000://sub
                    alu_op = 4'b1000;
                4'b0_001://sll 逻辑左移
                    alu_op = 4'b0001;
                4'b0_010://slt 算数小于
                    alu_op = 4'b0010;
                4'b0_011://sltu 逻辑小于（无符号数）
                    alu_op = 4'b1010;
                4'b0_100://xor 异或
                    alu_op = 4'b0100;
                4'b0_101://srl 逻辑右移（高位补0）
                    alu_op = 4'b0101;
                4'b1_101://sra 算数右移（高位补符号位）
                    alu_op = 4'b1101;
                4'b0_110://or 按位或
                    alu_op = 4'b0110;
                4'b0_111://and 按位与
                    alu_op = 4'b0111;
                default: //错误编码
                    alu_op = 4'b0000;
            endcase
        end
        5'b00000://i-type 短立即数类型（内存读取）
        begin
            alu_op = 4'b0000; //alu做加法运算
            alu_src = 3'b01_0;//rs1+imm
            reg_write = 1'b0;
            branch = 3'b000;
            imm_op = 3'b001;  //immi
            mem_write = 1'b0;
            mem_to_reg = 1'b1;
            case(funct3)
                3'b000://lb 读出该地址的1字节数据
                    mem_op = 3'b001;
                3'b001://lh 读出该地址的2字节数据
                    mem_op = 3'b010;
                3'b010://lw 读出该地址的4字节数据
                    mem_op = 3'b011;
                3'b100://lbu 读出该地址的1字节数据（不使用符号扩展）
                    mem_op = 3'b101;
                3'b101://lhu 读出该地址的2字节数据（不使用符号扩展）
                    mem_op = 3'b110;
                default:
                    mem_op = 3'b000;
            endcase
        end
        5'b00100://i-type 短立即数类型
        begin
            alu_src = 3'b01_0;//rs1+imm
            reg_write = 1'b1;//需写回寄存器rd
            branch = 3'b000; //不跳转
            imm_op = 3'b001; //immi
            mem_write = 1'b0;
            mem_op = 3'b000;  //无需操作存储器
            mem_to_reg = 1'b0;
            case(funct3)
                3'b000://addi
                    alu_op = 4'b0000;
                3'b010://slti
                    alu_op = 4'b0010;
                3'b011://sltiu
                    alu_op = 4'b1010;
                3'b100://xori
                    alu_op = 4'b0100;
                3'b110://ori
                    alu_op = 4'b0110;
                3'b111://andi
                    alu_op = 4'b0111;
                3'b001://slli
                    alu_op = 4'b0001;
                3'b101://srli || srai
                    alu_op = {funct7[5],3'b101};
                default://错误编码
                    alu_op = 4'b0000;
            endcase
        end
        5'b11000://b-type 条件跳转类型
        begin
            //alu做sub运算输出zero/less标志位，pc计算使用专用加法器
            //有一种备选方案是alu做slt运算输出标志位（这样可以与无符号数条件跳转指令统一起来）
            alu_src = 3'b00_0;
            reg_write = 1'b0;//无需写回寄存器
            imm_op = 3'b100; //immb
            mem_write = 1'b0;
            mem_op = 3'b000;  //无需操作存储器
            mem_to_reg = 1'b0;
            case(funct3)
                3'b000://beq 相等时跳转
                begin
                    alu_op = 4'b1000;
                    branch = 3'b100; //相等时跳转
                end
                3'b001://bne 不等时跳转
                begin
                    alu_op = 4'b1000;
                    branch = 3'b101; //不等时跳转
                end
                3'b100://blt rs1小于rs2时跳转
                begin
                    alu_op = 4'b1000;
                    branch = 3'b110; //小于时跳转
                end
                3'b101://bge rs1大于等于rs2时跳转
                begin
                    alu_op = 4'b1000;
                    branch = 3'b111; //不小于时跳转
                end
                3'b110://bltu rs1小于rs2时跳转（操作数均为无符号数）
                begin
                    alu_op = 4'b1010;//alu使用sltu运算输出zero/less标志位
                    branch = 3'b110; //小于时跳转
                end
                3'b111://bgeu rs1大于等于rs2时跳转（操作数均为无符号数）
                begin
                    alu_op = 4'b1010;//alu使用sltu运算输出zero/less标志位
                    branch = 3'b111; //不小于时跳转
                end
                default:
                begin
                    alu_op = 4'b0000;
                    branch = 3'b000;
                end
            endcase
        end
        5'b11011://j-type jal无条件跳转类型
        begin
            //alu执行的操作是计算pc+4
            alu_op = 4'b0000;
            alu_src = 3'b10_1;//pc+4
            reg_write = 1'b1;
            branch = 3'b001;//无条件跳转至pc目标
            imm_op = 3'b101;//immj
            mem_write = 1'b0;
            mem_op = 3'b000;  //无需操作存储器
            mem_to_reg = 1'b0;
        end
        5'b11001://j-type jalr无条件跳转类型
        begin
            //alu执行的操作是计算pc+4
            alu_op = 4'b0000;
            alu_src = 3'b10_1;
            reg_write = 1'b1;
            branch = 3'b010;//无条件跳转至寄存器目标
            imm_op = 3'b001;//immi
            mem_write = 1'b0;
            mem_op = 3'b000;  //无需操作存储器
            mem_to_reg = 1'b0;
        end
        5'b01000://s-type 内存存储类型
        begin
            alu_op = 4'b0000; //alu做加法运算
            alu_src = 3'b01_0;//rs1+imm
            reg_write = 1'b0;
            branch = 3'b000;
            imm_op = 3'b011;  //imms
            mem_write = 1'b1;
            mem_to_reg = 1'b0;
            case(funct3)
                3'b000://sb 将rs2的最低的1个字节存入
                    mem_op = 3'b001;
                3'b001://sh 将rs2的最低的2个字节存入
                    mem_op = 3'b010;
                3'b010://sw 将rs2的全部的4个字节存入
                    mem_op = 3'b011;
                default:
                    mem_op = 3'b000;
            endcase
        end
        5'b01101://u-type lui高位立即数类型
        begin
            alu_op = 4'b0011;
            alu_src = 3'b01_0;//仅使用立即数
            reg_write = 1'b1;
            branch = 3'b000;
            imm_op = 3'b010;  //immu
            mem_write = 1'b0;
            mem_op = 3'b000;  //无需操作存储器
            mem_to_reg = 1'b0;
        end
        5'b00101://u-type auipc高位立即数类型
        begin
            alu_op = 4'b0000;
            alu_src = 3'b01_1;//pc+imm
            reg_write = 1'b1;
            branch = 3'b000;
            imm_op = 3'b010;  //immu
            mem_write = 1'b0;
            mem_op = 3'b000;  //无需操作存储器
            mem_to_reg = 1'b0;
        end
        default:
        begin
            alu_op = 4'b0000;
            alu_src = 3'b00_0;
            reg_write = 1'b0;
            branch = 3'b000;
            imm_op = 3'b000;  //不产生立即数
            mem_write = 1'b0;
            mem_op = 3'b000;  //无需操作存储器
            mem_to_reg = 1'b0;
        end
    endcase
end
endmodule
