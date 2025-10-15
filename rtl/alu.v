`timescale 1ns / 1ps
import my_pkg::*;
module alu (
    input  wire [DATA_WIDTH - 1 : 0]    a       ,           // 操作数A
    input  wire [DATA_WIDTH - 1 : 0]    b       ,           // 操作数B
    input  wire [3 : 0]                 alu_op  ,           // ALU控制信号
    output reg  [DATA_WIDTH - 1 : 0]    result  ,           // 运算结果
    output wire                         zero    ,           // 零标志
    output wire                         less                // 小于标志
);

// 内部信号
wire [31:0] add_sub_result;   // 加减法结果
wire [32:0] add_sub_ext;      // 扩展位用于比较
wire [31:0] sll_result;       // 左移结果
wire [31:0] srl_result;       // 逻辑右移结果
wire [31:0] sra_result;       // 算术右移结果

// 判断是否为比较操作
wire is_slt = (alu_op == ALU_SLT);
wire is_sltu = (alu_op == ALU_SLTU);
wire is_compare = is_slt | is_sltu;

// 统一的加减法单元 - 处理ADD、SUB和比较操作
wire do_subtract = (alu_op == ALU_SUB) | is_compare;
assign add_sub_ext = do_subtract ? 
                    {1'b0, a} - {1'b0, b} :  // 减法（包括比较）
                    {1'b0, a} + {1'b0, b};   // 加法

assign add_sub_result = add_sub_ext[31:0];

wire slt_result, sltu_result;       // 逻辑小于及算术小于

// 算术小于
assign slt_result = (a[31] != b[31]) ? 
                   a[31] & ~b[31] :     // 符号不同时,a负b正则a<b
                   add_sub_result[31];   // 符号相同时，看减法结果的符号位

// 逻辑小于(SLTU) - 无符号比较  
// 使用统一减法单元的借位标志
assign sltu_result = add_sub_ext[32];  // 借位标志取反

// 比较标志输出
assign less = is_compare ? 
             (is_slt ? slt_result : sltu_result) : 
             1'b0;

// 移位单元
assign sll_result = a << b[4:0];  // 取b的低5位作为移位位数
assign srl_result = a >> b[4:0];
assign sra_result = $signed(a) >>> b[4:0];  // 算术右移保持符号位

// 主ALU组合逻辑
always @(*) begin
    case (alu_op)
        ALU_ADD:  result = add_sub_result;
        ALU_SUB:  result = add_sub_result;
        ALU_SLL:  result = sll_result;
        ALU_SLT:  result = {31'b0, slt_result};
        ALU_SLTU: result = {31'b0, sltu_result};
        ALU_XOR:  result = a ^ b;
        ALU_SRL:  result = srl_result;
        ALU_SRA:  result = sra_result;
        ALU_OR:   result = a | b;
        ALU_AND:  result = a & b;
        default:  result = 32'b0;  // 默认输出0
    endcase
end

// 零标志
assign zero = (result == 32'b0);

endmodule