# risc-v_cpu_uestc
Design a cpu core using risc-v instruction set. This project is a courese design of UESTC guided by LiHui.


# 参数
|参数名称|参数大小|描述|
|-----|------|-----|
|`DATA_WIDTH`|`32`|数据位宽|
|`ADDR_WIDTH`|`32`|地址位宽|

# 接口
|信号名称|方向|位宽|描述|
|-------|----|----|---|
|`clk`|input|`1`|时钟|
|`rst_n`|input|`1`|复位|

# RISC-V RV32I 基础整数指令集

## 1. 指令格式总览

| **指令类型** | **编码结构** | **主要用途** | **典型指令** |
|--------------|--------------|--------------|--------------|
| **R-type** | `funct7[7]` \| `rs2[5]` \| `rs1[5]` \| `funct3[3]` \| `rd[5]` \| `opcode[7]` | 寄存器-寄存器操作 | `add`, `sub`, `and` |
| **I-type** | `imm[12]` \| `rs1[5]` \| `funct3[3]` \| `rd[5]` \| `opcode[7]` | 立即数操作/加载 | `addi`, `lw`, `jalr` |
| **S-type** | `imm[7]` \| `rs2[5]` \| `rs1[5]` \| `funct3[3]` \| `imm[5]` \| `opcode[7]` | 存储操作 | `sw`, `sb`, `sh` |
| **B-type** | `imm[7]` \| `rs2[5]` \| `rs1[5]` \| `funct3[3]` \| `imm[5]` \| `opcode[7]` | 条件分支 | `beq`, `bne`, `blt` |
| **J-type** | `imm[20]` \| `rd[5]` \| `opcode[7]` | 长跳转 | `jal` |
| **U-type** | `imm[20]` \| `rd[5]` \| `opcode[7]` | 高位立即数 | `lui`, `auipc` |

**位宽说明**：  
- `[n]` 表示该字段占用的位数  
- 立即数字段需符号扩展为32位  
- 所有指令总长度固定为32位

## 2.立即数映射
| **指令类型** | **立即数映射** |
|----------|----------|
| **I-type** |`inst[31:20]->imm[11:0]`|
| **S-type** |`inst[31:25]->imm[11:5]`<br>`inst[11:7]->imm[4:0]`|
| **B-type** |`inst[31:25]->imm[12\|10:5]`<br>`inst[11:7]->imm[4:1\|11]`|
| **J-type** |`inst[31:12]->imm[20\|10:1\|11\|19:12]`|
| **U-type** |`inst[31:12]->imm[31:12]`|


## 3.完整指令集编码表

### 3.1 整数运算指令

| **指令** | **汇编格式** | **类型** | **opcode** | **funct3** | **funct7** | **操作** |
|----------|--------------|----------|------------|------------|------------|----------|
| `add`    | `add rd, rs1, rs2` | R-type | `0110011` | `000` | `0000000` | rd = rs1 + rs2 |
| `sub`    | `sub rd, rs1, rs2` | R-type | `0110011` | `000` | `0100000` | rd = rs1 - rs2 |
| `sll`    | `sll rd, rs1, rs2` | R-type | `0110011` | `001` | `0000000` | rd = rs1 << rs2[4:0] |
| `slt`    | `slt rd, rs1, rs2` | R-type | `0110011` | `010` | `0000000` | rd = (rs1 < rs2) ? 1 : 0 (有符号) |
| `sltu`   | `sltu rd, rs1, rs2` | R-type | `0110011` | `011` | `0000000` | rd = (rs1 < rs2) ? 1 : 0 (无符号) |
| `xor`    | `xor rd, rs1, rs2` | R-type | `0110011` | `100` | `0000000` | rd = rs1 ^ rs2 |
| `srl`    | `srl rd, rs1, rs2` | R-type | `0110011` | `101` | `0000000` | rd = rs1 >> rs2[4:0] (逻辑) |
| `sra`    | `sra rd, rs1, rs2` | R-type | `0110011` | `101` | `0100000` | rd = rs1 >> rs2[4:0] (算术) |
| `or`     | `or rd, rs1, rs2` | R-type | `0110011` | `110` | `0000000` | rd = rs1 \| rs2 |
| `and`    | `and rd, rs1, rs2` | R-type | `0110011` | `111` | `0000000` | rd = rs1 & rs2 |
| `addi`   | `addi rd, rs1, imm` | I-type | `0010011` | `000` | - | rd = rs1 + imm |
| `slti`   | `slti rd, rs1, imm` | I-type | `0010011` | `010` | - | rd = (rs1 < imm) ? 1 : 0 (有符号) |
| `sltiu`  | `sltiu rd, rs1, imm` | I-type | `0010011` | `011` | - | rd = (rs1 < imm) ? 1 : 0 (无符号) |
| `xori`   | `xori rd, rs1, imm` | I-type | `0010011` | `100` | - | rd = rs1 ^ imm |
| `ori`    | `ori rd, rs1, imm` | I-type | `0010011` | `110` | - | rd = rs1 \| imm |
| `andi`   | `andi rd, rs1, imm` | I-type | `0010011` | `111` | - | rd = rs1 & imm |
| `slli`   | `slli rd, rs1, shamt` | I-type | `0010011` | `001` | `0000000` | rd = rs1 << shamt |
| `srli`   | `srli rd, rs1, shamt` | I-type | `0010011` | `101` | `0000000` | rd = rs1 >> shamt (逻辑) |
| `srai`   | `srai rd, rs1, shamt` | I-type | `0010011` | `101` | `0100000` | rd = rs1 >> shamt (算术) |

### 3.2 加载/存储指令

| **指令** | **汇编格式** | **类型** | **opcode** | **funct3** | **操作** |
|----------|--------------|----------|------------|------------|----------|
| `lb`     | `lb rd, offset(rs1)` | I-type | `0000011` | `000` | rd = SignExtend(Mem[rs1+offset][7:0]) |
| `lh`     | `lh rd, offset(rs1)` | I-type | `0000011` | `001` | rd = SignExtend(Mem[rs1+offset][15:0]) |
| `lw`     | `lw rd, offset(rs1)` | I-type | `0000011` | `010` | rd = Mem[rs1+offset] |
| `lbu`    | `lbu rd, offset(rs1)` | I-type | `0000011` | `100` | rd = ZeroExtend(Mem[rs1+offset][7:0]) |
| `lhu`    | `lhu rd, offset(rs1)` | I-type | `0000011` | `101` | rd = ZeroExtend(Mem[rs1+offset][15:0]) |
| `sb`     | `sb rs2, offset(rs1)` | S-type | `0100011` | `000` | Mem[rs1+offset][7:0] = rs2[7:0] |
| `sh`     | `sh rs2, offset(rs1)` | S-type | `0100011` | `001` | Mem[rs1+offset][15:0] = rs2[15:0] |
| `sw`     | `sw rs2, offset(rs1)` | S-type | `0100011` | `010` | Mem[rs1+offset] = rs2 |

### 3.3 分支/跳转指令

| **指令** | **汇编格式** | **类型** | **opcode** | **funct3** | **操作** |
|----------|--------------|----------|------------|------------|----------|
| `beq`    | `beq rs1, rs2, offset` | B-type | `1100011` | `000` | if (rs1 == rs2) PC += offset×2 |
| `bne`    | `bne rs1, rs2, offset` | B-type | `1100011` | `001` | if (rs1 != rs2) PC += offset×2 |
| `blt`    | `blt rs1, rs2, offset` | B-type | `1100011` | `100` | if (rs1 < rs2) PC += offset×2 (有符号) |
| `bge`    | `bge rs1, rs2, offset` | B-type | `1100011` | `101` | if (rs1 >= rs2) PC += offset×2 (有符号) |
| `bltu`   | `bltu rs1, rs2, offset` | B-type | `1100011` | `110` | if (rs1 < rs2) PC += offset×2 (无符号) |
| `bgeu`   | `bgeu rs1, rs2, offset` | B-type | `1100011` | `111` | if (rs1 >= rs2) PC += offset×2 (无符号) |
| `jal`    | `jal rd, offset` | J-type | `1101111` | - | rd = PC+4; PC += offset×2 |
| `jalr`   | `jalr rd, offset(rs1)` | I-type | `1100111` | `000` | rd = PC+4; PC = rs1 + offset |

## 3.4 其他指令
| **指令** | **汇编格式** | **类型** | **opcode** | **操作** |
|----------|--------------|----------|------------|----------|
| `lui`    | `lui rd, imm` | U-type | `0110111` | rd = imm << 12 |
| `auipc`  | `auipc rd, imm` | U-type | `0010111` | rd = PC + (imm << 12) |

# 关键模块
## 1.reg_file
- 描述：寄存器文件模块，用于存取计算数据。同步写，异步读。0寄存器写保护。
- 端口:

|信号名称|方向|位宽|描述|
|-------|----|----|---|
|`clk`|input|`1`|时钟|
|`rst_n`|input|`1`|复位|
|`wr_en`|input|`1`|写使能|
|`addr_wr`|input|`5`|写地址|
|`addr_rd1`|input|`5`|读地址1|
|`addr_rd2`|input|`5`|读地址2|
|`data_wr`|input|`DATA_WIDTH`|写数据|
|`data_rd1`|output|`DATA_WIDTH`|读数据1|
|`data_rd2`|output|`DATA_WIDTH`|读数据2|

## 2.data_mem
- 描述：数据存储器建模。字节寻址，大小`64KB`。同步读写。
- 端口：

|信号名称|方向|位宽|描述|
|-------|----|----|---|
|`clk`|input|`1`|时钟|
|`rst_n`|input|`1`|复位|
|`wr_en`|input|`1`|写使能|
|`addr`|input|`ADDR_WIDTH`|读写地址|
|`data_wr`|input|`DATA_WIDTH`|写数据|
|`data_rd`|output|`DATA_WIDTH`|读数据|

## 3.inst_mem
- 描述：指令存储器建模，只读。字节寻址，大小`64KB`。同步读。
- 端口：

|信号名称|方向|位宽|描述|
|-------|----|----|---|
|`clk`|input|`1`|时钟|
|`rst_n`|input|`1`|复位|
|`addr`|input|`ADDR_WIDTH`|读地址|
|`inst`|output|`DATA_WIDTH`|读指令|

## 4.alu
- 描述：算术运算单元。支持加减运算，逻辑运算。

## 5.pc_counter
- 描述：得到下一条指令的地址。复位到地址`0x0000_1000`.
- 端口：

|信号名称|方向|位宽|描述|
|-------|----|----|---|
|`clk`|input|`1`|时钟|
|`rst_n`|input|`1`|复位|
|`pc_next`|input|`DATA_WIDTH`|下一条指令地址|
|`pc_current`|output|`DATA_WIDTH`|当前执行指令地址|

## 6.imm_gen
- 描述：根据指令类型生成相应格式的立即数
- 端口：

|信号名称|方向|位宽|描述|
|-------|----|----|---|
|`inst`|input|`DATA_WIDTH`|指令|
|`imm` |output|`DATA_WIDTH`|立即数|

## 7.controller
- 描述：产生数据通路各个模块的控制选择信号。
- 端口：

|信号名称|方向|位宽|描述|
|-------|----|----|---|
|`inst`|input|`DATA_WIDTH`|指令|
|`branch`|output|`3`|跳转|
|`mem_read`|output|`1`|数据存储器读控制?|
|`mem_write`|output|`1`|数据存储器写控制|
|`mem_to_reg`|output|`1`|数据存储器写回|
|`mem_op`|output|`3`|存储器读写格式|
|`alu_op`|output|`4`|ALU控制指令|
|`alu_src`|output|`3`|ALU选择源操作数|
|`imm_op`|output|`3`|立即数类型|
|`reg_write`|output|`1`|寄存器文件写控制|

- ALU控制指令编码:

|alu_op|ALU操作|
|------|------|
|`0000`|add|
|`1000`|sub|
|`0001`|sll|
|`0010`|slt|
|`1010`|sltu|
|`0100`|xor|
|`0101`|srl|
|`1101`|sra|
|`0110`|or|
|`0111`|and|