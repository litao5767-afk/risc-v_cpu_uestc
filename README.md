# risc-v_cpu_uestc

本仓库实现了一个基于 RISC‑V RV32I 指令集的教学 CPU 核，作为课程设计（UESTC）。

## 参数

| 参数名 | 大小 | 描述 |
|---:|:---:|:---|
| `DATA_WIDTH` | `32` | 数据位宽（位） |
| `ADDR_WIDTH` | `32` | 地址位宽（位） |
| `MEM_DATA_DEPTH` | `4096` | 数据存储器深度 |
| `MEM_INST_DEPTH` | `4096` | 指令存储器深度 |

## 通用接口

| 信号名 | 方向 | 位宽 | 描述 |
|---|---|---:|---|
| `clk` | input | `1` | 时钟 |
| `rst_n` | input | `1` | 异步复位（低有效） |

---

# RISC‑V RV32I 简要参考

以下内容为 RV32I 的简要说明（非完整手册）。具体以 RISC‑V Foundation 的官方文档为准。

## 指令位域概览

- 所有指令固定为 32 位。
- 指令常见类型：R/I/S/B/U/J，各类型在指令字中字段位置不同（opcode、rd、funct3、rs1、rs2、funct7、imm）。

常见类型及位域（低位至高位示意）：

- R-type: opcode[6:0], rd[11:7], funct3[14:12], rs1[19:15], rs2[24:20], funct7[31:25]
- I-type: opcode[6:0], rd[11:7], funct3[14:12], rs1[19:15], imm[31:20]
- S-type: opcode[6:0], imm[4:0]=inst[11:7], funct3[14:12], rs1[19:15], rs2[24:20], imm[11:5]=inst[31:25]
- B-type: opcode[6:0], imm[11]=inst[7], imm[4:1]=inst[11:8], funct3[14:12], rs1[19:15], rs2[24:20], imm[10:5]=inst[30:25], imm[12]=inst[31]
- U-type: opcode[6:0], rd[11:7], imm[31:12]=inst[31:12]
- J-type: opcode[6:0], rd[11:7], imm[19:12]=inst[19:12], imm[11]=inst[20], imm[10:1]=inst[30:21], imm[20]=inst[31]

## 立即数重组（要点）

- I-type: imm[11:0] = inst[31:20]，符号扩展到 32 位。
- S-type: imm[11:5]=inst[31:25], imm[4:0]=inst[11:7]，合并后符号扩展。
- B-type: imm = sign_extend({inst[31], inst[7], inst[30:25], inst[11:8], 1'b0})（注意最低位为 0，表示相对偏移以 2 字节对齐的位移）。
- J-type: imm = sign_extend({inst[31], inst[19:12], inst[20], inst[30:21], 1'b0})（最低位为 0）。
- U-type: imm = {inst[31:12], 12'b0}（高 20 位直接作为立即数高位）。

数学表示（J-type 示例）：

$$imm = \{\{12\{inst[31]\}\}, inst[19:12], inst[20], inst[30:21], 1'b0 \}$$

## jalr 注意事项

- `jalr rd, offset(rs1)` 的目标 PC 必须清除最低位：

	PC = (rs1 + offset) & ~1

	这是 RV32I 规范要求，以保证跳转目标对齐。

## 常见指令编码（示例）

- R-type 算术： `add/sub/sll/slt/sltu/xor/srl/sra/or/and`（opcode=0110011，funct3/funct7 区分具体操作）
- I-type 算术/逻辑： `addi/slti/sltiu/xori/ori/andi/slli/srli/srai`（opcode=0010011）
- Loads： `lb/lh/lw/lbu/lhu`（opcode=0000011）
- Stores： `sb/sh/sw`（opcode=0100011）
- Branches： `beq/bne/blt/bge/bltu/bgeu`（opcode=1100011）
- Jumps： `jal`（opcode=1101111）, `jalr`（opcode=1100111，funct3=000）
- U-type： `lui`（0110111）, `auipc`（0010111）

（具体 funct3/funct7 编码请参阅官方文档或代码中 `my_pkg.sv` 的定义。）

---


# 关键模块

以下为仓库中典型模块的功能简述与端口信号表（按源码定义）。表中位宽使用 `DATA_WIDTH` / `ADDR_WIDTH` 等参数名以便对应源码。

### cpu_top
描述：CPU 顶层连接模块，提供 `clk` / `rst_n` 输入并实例化子模块。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `clk` | input | 1 | 时钟 |
| `rst_n` | input | 1 | 异步复位（低有效） |

---

### pc_reg
描述：程序计数器寄存器。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `clk` | input | 1 | 时钟 |
| `rst_n` | input | 1 | 异步复位（低有效） |
| `pc_next` | input | `ADDR_WIDTH` | 下一个 PC 值 |
| `pc_current` | output (reg) | `ADDR_WIDTH` | 当前 PC 输出 |

---

### inst_mem
描述：指令只读存储器，通过地址输出 32 位指令。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `addr` | input | `ADDR_WIDTH` | 指令地址（字节地址） |
| `inst` | output | `DATA_WIDTH` | 输出的指令字（32 位） |

---

### reg_file
描述：通用寄存器文件，32 个寄存器，x0 常为 0，写入 x0 被忽略。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `clk` | input | 1 | 时钟 |
| `rst_n` | input | 1 | 复位 |
| `wr_en` | input | 1 | 写使能 |
| `addr_wr` | input | 5 | 写地址（rd） |
| `addr_rd1` | input | 5 | 读端口 1 地址（rs1） |
| `addr_rd2` | input | 5 | 读端口 2 地址（rs2） |
| `data_wr` | input | `DATA_WIDTH` | 写入数据 |
| `data_rd1` | output | `DATA_WIDTH` | 读端口 1 数据输出 |
| `data_rd2` | output | `DATA_WIDTH` | 读端口 2 数据输出 |

---

### data_mem
描述：数据存储器（字组织），支持字/半字/字节的读写和字内偏移掩码。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `clk` | input | 1 | 时钟 |
| `rst_n` | input | 1 | 复位 |
| `wr_en` | input | 1 | 写使能（同步） |
| `mem_op` | input | 3 | 内存操作类型（`MEM_*` 编码） |
| `addr` | input | `ADDR_WIDTH` | 数据访问地址（字节地址） |
| `data_wr` | input | `DATA_WIDTH` | 写数据 |
| `data_rd` | output (reg) | `DATA_WIDTH` | 读出数据 |

---

### alu
描述：算术逻辑单元，执行加减、移位、逻辑及比较等操作。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `a` | input | `DATA_WIDTH` | 操作数 A |
| `b` | input | `DATA_WIDTH` | 操作数 B |
| `alu_op` | input | 4 | ALU 操作编码 |
| `result` | output (reg) | `DATA_WIDTH` | ALU 运算结果 |
| `zero` | output | 1 | 结果是否为 0 标志 |
| `less` | output | 1 | 小于比较结果标志 |

---

### imm_gen
描述：从指令位域生成带符号的立即数（I/S/B/U/J 型）。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `inst` | input | `DATA_WIDTH` | 指令字（32 位） |
| `imm` | output (reg) | `DATA_WIDTH` | 生成的立即数（已符号扩展） |

---

### alu_src_sel
描述：根据 `alu_src` 信号选择 ALU 的两个操作数来源（rs1/pc 与 rs2/imm/const4）。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `rs1` | input | `DATA_WIDTH` | 寄存器 rs1 数据 |
| `pc` | input | `ADDR_WIDTH` | 当前 PC（取低位给 DATA_WIDTH） |
| `rs2` | input | `DATA_WIDTH` | 寄存器 rs2 数据 |
| `imm` | input | `DATA_WIDTH` | 立即数 |
| `alu_src` | input | 3 | 选择编码（`ALU_SRC_*`） |
| `data1` | output | `DATA_WIDTH` | ALU 操作数 1 |
| `data2` | output | `DATA_WIDTH` | ALU 操作数 2 |

---

### rv_controller
描述：指令译码器，根据 opcode/funct3/funct7 生成控制信号（寄存器写、内存访问、ALU 控制、分支类型等）。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `inst` | input | `DATA_WIDTH` | 指令字 |
| `mem_write` | output | 1 | 内存写使能 |
| `mem_to_reg` | output | 1 | 写回选择（来自内存） |
| `reg_write` | output | 1 | 寄存器写使能 |
| `mem_op` | output | 3 | 内存操作类型 |
| `alu_op` | output | 4 | ALU 操作编码 |
| `alu_src` | output | 3 | ALU 源选择编码 |
| `branch` | output | 3 | 分支/跳转类型编码 |

---

### rv_nextpc_gen
描述：NextPC 生成器，根据分支类型、标志位和立即数计算下一个 PC。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `zero` | input | 1 | ALU zero 标志 |
| `less` | input | 1 | ALU less 标志 |
| `branch` | input | 3 | 分支类型编码 |
| `pc` | input | `ADDR_WIDTH` | 当前 PC |
| `rs` | input | `DATA_WIDTH` | rs1 值（用于 jalr） |
| `imm` | input | `DATA_WIDTH` | 立即数 |
| `nextpc` | output (reg) | `ADDR_WIDTH` | 计算得到的下一个 PC |

---

### write_back_sel
描述：选择写回寄存器的数据来源（ALU 结果或内存读出）。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `mem_to_reg` | input | 1 | 写回来源选择（1=来自内存） |
| `data_mem_read` | input | `DATA_WIDTH` | 数据存储器读出数据 |
| `data_alu_result` | input | `DATA_WIDTH` | ALU 结果 |
| `data_wr_back` | output | `DATA_WIDTH` | 最终写回寄存器的数据 |


---

# 使用与仿真

- 仿真与综合命令依赖你的本地工具链（例如 Synopsys VCS、ModelSim/Questa、Icarus Verilog 等）。
- 项目中有 Makefile ，通常可以使用：

```bash
# 在工程根目录
dmk vcs
```

请根据你的仿真环境调整命令。

---

# 参考文档
- RISC‑V 官方文档（基础整数指令集、用户级架构）： https://riscv.org/specifications/ 
