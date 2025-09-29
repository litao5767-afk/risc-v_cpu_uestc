module rv_controller(
    input [31:0] inst,       //指令码传入
    output reg [2:0] branch, //跳转
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg [2:0] mem_op, //存储器读写格式
    output reg [3:0] alu_op, //alu控制指令
    output reg [2:0] alu_src,//低1位表示操作数1选择rs1(0)/pc(1)，高2位表示操作数2选择rs2(00)/imm(01)/常数4(10)
    output reg [2:0] imm_op, //立即数类型（对应top模块中的imm-gen部分）
    output reg reg_write     //寄存器写入请求
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
            case({funct7[5],funct3})
                4'b0_000://add
                begin
                    alu_op = 4'b0000;
                end
                4'b1_000://sub
                begin
                    alu_op = 4'b1000;
                end
                4'b0_001://sll 逻辑左移
                begin
                    alu_op = 4'b0001;
                end
                4'b0_010://slt 算数小于
                begin
                    alu_op = 4'b0010;
                end
                4'b0_011://sltu 逻辑小于（无符号数）
                begin
                    alu_op = 4'b1010;
                end
                4'b0_100://xor 异或
                begin
                    alu_op = 4'b0100;
                end
                4'b0_101://srl 逻辑右移（高位补0）
                begin
                    alu_op = 4'b0101;
                end
                4'b1_101://sra 算数右移（高位补符号位）
                begin
                    alu_op = 4'b1101;
                end
                4'b0_110://or 按位或
                begin
                    alu_op = 4'b0110;
                end
                4'b0_111://and 按位与
                begin
                    alu_op = 4'b0111;
                end
                default://错误编码
                begin
                    alu_op = 4'b0;
                end
            endcase
        end
        5'b00000://i-type 短立即数类型
        begin
            
        end
        5'b11000://b-type 条件跳转类型
        begin
            //alu做sub运算输出zero/less标志位，pc计算使用专用加法器
            //有一种备选方案是alu做slt运算输出标志位（这样可以与无符号数条件跳转指令统一起来）
            case(funct3)
                3'b000://beq 相等时跳转
                begin
                    alu_op = 4'b1000;
                    alu_src = 3'b00_0;
                    reg_write = 1'b0;//无需写回寄存器
                    branch = 3'b100; //相等时跳转
                    imm_op = 3'b100; //immb
                end
                3'b001://bne 不等时跳转
                begin
                    alu_op = 4'b1000;
                    alu_src = 3'b00_0;
                    reg_write = 1'b0;//无需写回寄存器
                    branch = 3'b101; //不等时跳转
                    imm_op = 3'b100; //immb
                end
                3'b100://blt rs1小于rs2时跳转
                begin
                    alu_op = 4'b1000;
                    alu_src = 3'b00_0;
                    reg_write = 1'b0;//无需写回寄存器
                    branch = 3'b110; //小于时跳转
                    imm_op = 3'b100; //immb
                end
                3'b101://bge rs1大于等于rs2时跳转
                begin
                    alu_op = 4'b1000;
                    alu_src = 3'b00_0;
                    reg_write = 1'b0;//无需写回寄存器
                    branch = 3'b111; //不小于时跳转
                    imm_op = 3'b100; //immb
                end
                3'b110://bltu rs1小于rs2时跳转（操作数均为无符号数）
                begin
                    alu_op = 4'b1010;//需要alu使用sltu运算输出zero/less标志位
                    alu_src = 3'b00_0;
                    reg_write = 1'b0;//无需写回寄存器
                    branch = 3'b110; //小于时跳转
                    imm_op = 3'b100; //immb
                end
                3'b111://bgeu rs1大于等于rs2时跳转（操作数均为无符号数）
                begin
                    alu_op = 4'b1010;//需要alu使用sltu运算输出zero/less标志位
                    alu_src = 3'b00_0;
                    reg_write = 1'b0;//无需写回寄存器
                    branch = 3'b111; //不小于时跳转
                    imm_op = 3'b100; //immb
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
        end
        5'b11001://j-type jalr无条件跳转类型
        begin
            //alu执行的操作是计算pc+4
            alu_op = 4'b0000;
            alu_src = 3'b10_1;
            reg_write = 1'b1;
            branch = 3'b010;//无条件跳转至寄存器目标
            imm_op = 3'b001;//immi
        end
        5'b01000://s-type 内存存储类型
        begin
            case(funct3)
                3'b000://sb 立即数符号扩展后，与源寄存器1相加作为数据存储器的地址，将源寄存器2的最低字节存入
                begin
                    alu_op = 4'b0000; //alu做加法运算
                    alu_src = 3'b01_0;//rs1+imm
                    reg_write = 1'b0;
                    branch = 3'b000;
                    imm_op = 3'b011; //imms
                    mem_write = 1'b1;
                    mem_op = 3'b000;
                end//end//
            endcase
        end
        5'b01101://u-type lui高位立即数类型
        begin
            alu_op = 4'b0011;
            alu_src = 3'b01_0;//仅使用立即数
            reg_write = 1'b1;
            branch = 3'b000;
            imm_op = 3'b010;//immu
        end
        5'b00101://u-type auipc高位立即数类型
        begin
            alu_op = 4'b0000;
            alu_src = 3'b01_1;//pc+imm
            reg_write = 1'b1;
            branch = 3'b000;
            imm_op = 3'b010;//immu
        end
        default:
        begin
            
        end
    endcase
end
endmodule
