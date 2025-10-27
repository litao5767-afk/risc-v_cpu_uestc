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
- 移位立即数类（I-type 中的 slli/srli/srai）：shamt = inst[24:20]，其中 srai 需要 funct7 区分算术/逻辑右移。

数学表示（J-type 示例）：

$$imm = \{\{12\{inst[31]\}\}, inst[19:12], inst[20], inst[30:21], 1'b0 \}$$

## jal/jalr 注意事项

- `jal rd, imm`: 跳转至 PC + imm，并向 rd 写回返回地址 PC+4。
- `jalr rd, offset(rs1)`：
  - 目标 PC 必须清除最低位：PC = (rs1 + offset) & ~1
  - 向 rd 写回返回地址 PC+4（这里的 PC 指发起跳转前的取值）。
  - 该行为与是否实现压缩指令无关，属于 RV32I 基本规范要求。

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

读写语义说明：
- 读操作由 `mem_write=0` 且 `mem_op` 选择具体宽度/符号扩展：
  - lb/lh/lw/lbu/lhu 对应字节/半字/字的有符号或无符号读，按 `addr[1:0]` 选择字内偏移。
  - 读数据在模块内部完成对齐与符号扩展后输出至 `data_rd`。
- 写操作由 `wr_en` 有效且 `mem_write=1` 时生效：
  - sb/sh/sw 按 `addr[1:0]` 生成字节使能掩码，进行部分写。
- 未对齐访问：
  - 字（lw/sw）要求 `addr[1:0]==2'b00`；半字（lh/lhu/sh）要求 `addr[0]==1'b0`。
  - 若发生未对齐行为，当前教学实现通常“按字节掩码写入/读出+拼接”或视为未定义行为；具体以实现代码为准。

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

说明：
- 常见组合：A 取 rs1 或 pc，B 取 rs2、imm 或常数 4（用于 jal/jalr 的返回地址计算）。
- 具体编码请参见 `my_pkg.sv` 中的 `ALU_SRC_*` 定义。

---

### rv_controller
描述：指令译码器，根据 opcode/funct3/funct7 生成控制信号（寄存器写、内存访问、ALU 控制、分支类型等）。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `inst` | input | `DATA_WIDTH` | 指令字 |
| `mem_write` | output | 1 | 内存写使能 |
| `mem_to_reg` | output | 1 | 写回选择（1=来自内存） |
| `reg_write` | output | 1 | 寄存器写使能 |
| `mem_op` | output | 3 | 内存操作类型 |
| `alu_op` | output | 4 | ALU 操作编码 |
| `alu_src` | output | 3 | ALU 源选择编码 |
| `branch` | output | 3 | 分支/跳转类型编码 |

说明：
- `mem_to_reg=0` 时，写回来自 ALU；`mem_to_reg=1` 时，写回来自数据存储器。
- jal/jalr 采用 ALU+常数 4 生成返回地址写回 rd。

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

说明：
- jal：nextpc = pc + imm
- jalr：nextpc = (rs1 + imm) & ~1
- branch：按 `branch` 类型与标志位计算，成立时 pc + imm，否则 pc + 4

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

### rv_scheduler_control
描述：流水线控制/仲裁模块，负责数据前推控制、Load-Use 冒险暂停，以及分支失效时的冲刷控制（取指/译码/执行级）。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `rs1E` | input | 5 | 执行级源寄存器 rs1 编号 |
| `rs2E` | input | 5 | 执行级源寄存器 rs2 编号 |
| `rdM` | input | 5 | 访存级目的寄存器 rd 编号 |
| `rdW` | input | 5 | 写回级目的寄存器 rd 编号 |
| `reg_writeM` | input | 1 | 访存级是否写回寄存器 |
| `reg_writeW` | input | 1 | 写回级是否写回寄存器 |
| `mem_to_regM` | input | 1 | 访存级是否为 Load（1 表示从内存写回） |
| `br_taken` | input | 1 | 分支预测失败/实际跳转发生需冲刷 |
| `forward_rs1E` | output | 2 | rs1 的前推选择：00 无、01 WB→EX、10 MEM→EX |
| `forward_rs2E` | output | 2 | rs2 的前推选择：00 无、01 WB→EX、10 MEM→EX |
| `stallF` | output | 1 | 取指级暂停（与 `stallD` 同时拉高） |
| `stallD` | output | 1 | 译码级暂停（Load-Use 冒险时） |
| `flushD` | output | 1 | 冲刷 IF/ID（分支失效优先） |
| `flushE` | output | 1 | 冲刷 ID/EX（分支失效或插入气泡） |

说明：
- 前推优先级 MEM→EX 高于 WB→EX；不启用 EX→EX 以避免零时延组合环。
- 分支预测失败优先于 Load-Use 冒险：若 `br_taken=1`，同时拉高 `flushD/flushE`；否则当 `mem_to_regM=1` 且 `rdM` 命中 `rs1E/rs2E` 时，`stallF=stallD=1` 且 `flushE=1` 插入气泡。

---

### rv_scheduler_data
描述：流水线数据前推多路选择模块。根据 `forward_rs1E/forward_rs2E` 选择 EX 级实际送入 ALU 的两个源操作数。

端口：

| 信号名 | 方向 | 位宽 | 描述 |
|---|---:|---:|---|
| `alu_src1_data` | input | `DATA_WIDTH` | alu_src_sel 判决后的源操作数1（默认值） |
| `alu_src2_data` | input | `DATA_WIDTH` | alu_src_sel 判决后的源操作数2（默认值） |
| `alu_resultM` | input | `DATA_WIDTH` | 访存级的 ALU 结果（用于 MEM→EX 前推） |
| `dataW` | input | `DATA_WIDTH` | 写回级的数据（用于 WB→EX 前推） |
| `forward_rs1E` | input | 2 | 源1前推选择：00 默认、01 WB→EX、10 MEM→EX |
| `forward_rs2E` | input | 2 | 源2前推选择：00 默认、01 WB→EX、10 MEM→EX |
| `data1E` | output | `DATA_WIDTH` | EX 级实际送入的源操作数1 |
| `data2E` | output | `DATA_WIDTH` | EX 级实际送入的源操作数2 |

---

# 使用与仿真

- 仿真与综合命令依赖你的本地工具链（例如 Synopsys VCS、ModelSim/Questa、Icarus Verilog、Verilator 等）。
- 项目中有 Makefile ，通常可以使用：

```bash
# 在工程根目录
dmk vcs
```

请根据你的仿真环境调整命令与顶层 testbench 文件名。

---

# 参考文档
- RISC‑V 官方文档（基础整数指令集、用户级架构）： https://riscv.org/specifications/
