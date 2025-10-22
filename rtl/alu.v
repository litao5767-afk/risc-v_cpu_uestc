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
wire [DATA_WIDTH-1:0] add_sub_result;   // 加减法结果
wire [DATA_WIDTH:0]   add_sub_ext;      // 扩展位用于进位/借位 (DATA_WIDTH+1 位)
wire [DATA_WIDTH-1:0] sll_result;       // 左移结果
wire [DATA_WIDTH-1:0] srl_result;       // 逻辑右移结果
wire [DATA_WIDTH-1:0] sra_result;       // 算术右移结果

localparam integer SHAMT_BITS = $clog2(DATA_WIDTH);

// 判断是否为比较操作
wire is_slt = (alu_op == ALU_SLT);
wire is_sltu = (alu_op == ALU_SLTU);
wire is_compare = is_slt | is_sltu;

// 统一的加减法单元 - 处理ADD、SUB和比较操作
wire do_subtract = (alu_op == ALU_SUB) | is_compare;
// 使用带进位的加法来获得可靠的进位/借位信息：
// 当做减法时，使用 A + (~B) + 1，这样 add_sub_ext[DATA_WIDTH] 为 carry_out
assign add_sub_ext = do_subtract ?
                     ({1'b0, a} + (~{1'b0, b}) + 1'b1) :
                     ({1'b0, a} + {1'b0, b});

assign add_sub_result = add_sub_ext[DATA_WIDTH-1:0];

wire slt_result, sltu_result;       // 逻辑小于及无符号小于

// 算术小于
assign slt_result = (a[DATA_WIDTH-1] != b[DATA_WIDTH-1]) ?
                   (a[DATA_WIDTH-1] & ~b[DATA_WIDTH-1]) :
                   add_sub_result[DATA_WIDTH-1];

// 逻辑小于(SLTU) - 无符号比较
// 直接使用无符号比较表达更清晰且综合友好
assign sltu_result = (a < b);

// 比较标志输出
assign less = is_slt ? slt_result :
              is_sltu ? sltu_result :
              1'b0;

// 移位单元
assign sll_result = a << b[SHAMT_BITS-1:0];
assign srl_result = a >> b[SHAMT_BITS-1:0];
assign sra_result = $signed(a) >>> b[SHAMT_BITS-1:0];  // 算术右移保持符号位

// 主ALU组合逻辑
always @(*) begin
    case (alu_op)
        ALU_ADD:  result = add_sub_result;
        ALU_SUB:  result = add_sub_result;
        ALU_SLL:  result = sll_result;
        ALU_SLT:  result = {{(DATA_WIDTH-1){1'b0}}, slt_result};
        ALU_SLTU: result = {{(DATA_WIDTH-1){1'b0}}, sltu_result};
        ALU_XOR:  result = a ^ b;
        ALU_LUI:  result = b; // LUI: upper immediate already provided on operand b
        ALU_SRL:  result = srl_result;
        ALU_SRA:  result = sra_result;
        ALU_OR:   result = a | b;
        ALU_AND:  result = a & b;
        default:  result = {DATA_WIDTH{1'b0}};  // 默认输出0
    endcase
end

// 零标志
assign zero = (result == {DATA_WIDTH{1'b0}});

endmodule