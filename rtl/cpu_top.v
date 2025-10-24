// filepath: /home/zhonglitao/proj/risc-v_cpu_uestc/rtl/cpu_top.v
// ============================================================================
// Module: cpu_top
// Author: Zhong Litao
// Created: 2025-09-25
// Description: 
// top connection
// ============================================================================

`timescale 1ns / 1ps
import my_pkg::*;
module cpu_top
(
    input wire         clk      ,
    input wire         rst_n    
);

    wire [ADDR_WIDTH - 1 : 0]   pc_current_s1;
    wire [ADDR_WIDTH - 1 : 0]   nextpc;
    reg stallF;
    reg stallD;
    reg flushD;
    reg flushE;
    pc_reg u_pc_reg(
        .clk        (clk          ),
        .rst_n      (rst_n        ),
        .en         (~stallF      ),
        .pc_next    (nextpc       ),
        .pc_current (pc_current_s1)
    );

    wire [DATA_WIDTH - 1 : 0] inst_s1;
    inst_mem u_inst_mem_s1(
        .addr  (pc_current_s1),
        .inst  (inst_s1      )
    );

    reg [ADDR_WIDTH - 1 : 0] pc_current_s2;
    reg [DATA_WIDTH - 1 : 0] inst_s2;
    wire en_s1_s2 = ~stallD;
    wire clr_s1_s2 = flushD;
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_current_s2 <= {ADDR_WIDTH{1'b0}};
            inst_s2 <= {DATA_WIDTH{1'b0}};
        end
        else if(clr_s1_s2) begin
            pc_current_s2 <= {ADDR_WIDTH{1'b0}};
            inst_s2 <= {DATA_WIDTH{1'b0}};
        end
        else if(en_s1_s2) begin
            pc_current_s2 <= pc_current_s1;
            inst_s2 <= inst_s1;
        end
    end

    wire reg_write_s2;
    wire [4 : 0]addr_wr_s2;
    assign addr_wr_s2 = inst_s2[11 : 7];

    // 原始读出值（来自寄存器堆）
    wire [DATA_WIDTH - 1 : 0] data_rd1_s2_raw;
    wire [DATA_WIDTH - 1 : 0] data_rd2_s2_raw;

    // 带 WB->D 旁路后的读值（供后续流水线使用）
    wire [DATA_WIDTH - 1 : 0] data_rd1_s2;
    wire [DATA_WIDTH - 1 : 0] data_rd2_s2;

    reg [4 : 0] addr_wr_s5;
    reg reg_write_s5;
    reg [DATA_WIDTH - 1 : 0] data_wr_back_s5;
    reg_file u_reg_file_s2(
        .clk      (clk              ),
        .rst_n    (rst_n            ),
        .wr_en    (reg_write_s5     ),
        .addr_wr  (addr_wr_s5       ),
        .addr_rd1 (inst_s2[19 : 15] ),
        .addr_rd2 (inst_s2[24 : 20] ),
        .data_wr  (data_wr_back_s5  ),
        .data_rd1 (data_rd1_s2_raw  ),  
        .data_rd2 (data_rd2_s2_raw  )
    );

    // WB->D 旁路：同拍读写同一寄存器时，优先取写回数据
    assign data_rd1_s2 = (reg_write_s5 && (addr_wr_s5 != 5'd0) && (addr_wr_s5 == inst_s2[19:15]))
                       ? data_wr_back_s5 : data_rd1_s2_raw;
    assign data_rd2_s2 = (reg_write_s5 && (addr_wr_s5 != 5'd0) && (addr_wr_s5 == inst_s2[24:20]))
                       ? data_wr_back_s5 : data_rd2_s2_raw;

    wire mem_write_s2;
    wire mem_to_reg_s2;
    wire [2 : 0] mem_op_s2 ;
    wire [3 : 0] alu_op_s2 ;
    wire [2 : 0] alu_src_s2;
    wire [2 : 0] branch_s2 ;
    rv_controller u_rv_controller_s2(
        .inst       (inst_s2    ),
        .mem_write  (mem_write_s2  ),
        .mem_to_reg (mem_to_reg_s2 ),
        .reg_write  (reg_write_s2  ),
        .mem_op     (mem_op_s2     ),
        .alu_op     (alu_op_s2     ),
        .alu_src    (alu_src_s2    ),
        .branch     (branch_s2     )
    );

    wire [DATA_WIDTH - 1 : 0] imm_s2;
    imm_gen u_imm_gen_s2(
        .inst (inst_s2),
        .imm  (imm_s2 )
    );

    reg [DATA_WIDTH - 1 : 0] imm_s3;
    reg [DATA_WIDTH - 1 : 0] data_rd1_s3;
    reg [DATA_WIDTH - 1 : 0] data_rd2_s3;
    reg [3 : 0] alu_op_s3;
    reg [2 : 0] alu_src_s3;
    reg [2 : 0] branch_s3;
    reg mem_write_s3;
    reg mem_to_reg_s3;
    reg [2 : 0] mem_op_s3;
    reg reg_write_s3;
    reg [4 : 0]addr_wr_s3;
    reg [ADDR_WIDTH - 1 : 0] pc_current_s3;
    reg [4:0] rs1_addr_s3;
    reg [4:0] rs2_addr_s3;
    wire clr_s2_s3 = flushE;
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n || clr_s2_s3) begin
            imm_s3        <= {DATA_WIDTH{1'b0}};
            data_rd1_s3   <= {DATA_WIDTH{1'b0}};
            data_rd2_s3   <= {DATA_WIDTH{1'b0}};
            alu_op_s3     <= 4'b0;
            alu_src_s3    <= 3'b0;
            branch_s3     <= 3'b0;
            mem_write_s3  <= 1'b0;
            mem_to_reg_s3 <= 1'b0;
            mem_op_s3     <= 3'b0;
            reg_write_s3  <= 1'b0;
            addr_wr_s3    <= 5'b0;
            pc_current_s3 <= {ADDR_WIDTH{1'b0}};
            rs1_addr_s3   <= 5'b0;
            rs2_addr_s3   <= 5'b0;
        end
        else begin
            imm_s3        <= imm_s2        ;
            data_rd1_s3   <= data_rd1_s2   ;
            data_rd2_s3   <= data_rd2_s2   ;
            alu_op_s3     <= alu_op_s2     ;
            alu_src_s3    <= alu_src_s2    ;
            branch_s3     <= branch_s2     ;
            mem_write_s3  <= mem_write_s2  ;
            mem_to_reg_s3 <= mem_to_reg_s2 ;
            mem_op_s3     <= mem_op_s2     ;
            reg_write_s3  <= reg_write_s2  ;
            addr_wr_s3    <= addr_wr_s2    ;
            pc_current_s3 <= pc_current_s2 ;
            rs1_addr_s3   <= inst_s2[19:15];
            rs2_addr_s3   <= inst_s2[24:20];
        end
    end

    // --- 前推后再做源操作数选择 ---
    wire [DATA_WIDTH - 1 : 0] rs1_fwd_s3;
    wire [DATA_WIDTH - 1 : 0] rs2_fwd_s3;

    wire [1:0] forward_rs1E;
    wire [1:0] forward_rs2E;

    // MEM阶段的可前推值（考虑 mem_to_reg）
    wire [DATA_WIDTH - 1:0] forward_data_M;
    // 先声明，稍后赋值
    // ...existing code...

    wire [DATA_WIDTH - 1 : 0] data_src1;
    wire [DATA_WIDTH -  1: 0] data_src2;
    alu_src_sel u_alu_src_sel_s3(
        .rs1    (rs1_fwd_s3     ), // 改为使用前推后的寄存器值
        .pc     (pc_current_s3  ),
        .rs2    (rs2_fwd_s3     ),
        .imm    (imm_s3         ),
        .alu_src(alu_src_s3     ),
        .data1  (data_src1      ),
        .data2  (data_src2      )
    );

    // ALU 输入改为 alu_src_sel 的输出，防止前推覆盖 PC/IMM/常数4
    wire [DATA_WIDTH - 1 : 0] alu_result_s3;
    wire zero_s3;
    wire less_s3;
    alu u_alu_s3(
        .a       (data_src1       ),
        .b       (data_src2       ),
        .alu_op  (alu_op_s3       ),
        .result  (alu_result_s3   ),
        .zero    (zero_s3         ),
        .less    (less_s3         )
    );

    wire br_taken;
    wire [ADDR_WIDTH - 1 : 0] nextpc_ex;
    rv_nextpc_gen u_rv_nextpc_gen(
        .zero     (zero_s3        ),
        .less     (less_s3        ),
        .branch   (branch_s3      ),
        .pc       (pc_current_s3  ),
        .rs       (data_rd1_s3    ),
        .imm      (imm_s3         ),
        .nextpc   (nextpc_ex      ),  // 使用中间线承接 EX 生成的目标PC
        .br_taken (br_taken       )
    );

    wire [ADDR_WIDTH - 1 : 0] nextpc_seq = pc_current_s1 + {{(ADDR_WIDTH-3){1'b0}}, 3'b100};
    assign nextpc     = br_taken ? nextpc_ex : nextpc_seq;

    reg [DATA_WIDTH - 1 : 0] alu_result_s4;
    reg [DATA_WIDTH - 1 : 0] data_rd2_s4;
    reg mem_write_s4;
    reg mem_to_reg_s4;
    reg [2 : 0] mem_op_s4;
    reg reg_write_s4;
    reg [4 : 0]addr_wr_s4;
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_result_s4 <= {DATA_WIDTH{1'b0}};
            data_rd2_s4   <= {DATA_WIDTH{1'b0}};
            mem_write_s4  <= 1'b0;
            mem_to_reg_s4 <= 1'b0;
            mem_op_s4     <= 3'b0;
            reg_write_s4  <= 1'b0;
            addr_wr_s4    <= 5'b0;
        end
        else begin
            alu_result_s4 <= alu_result_s3;
            data_rd2_s4   <= data_rd2_s3;
            mem_write_s4  <= mem_write_s3;
            mem_to_reg_s4 <= mem_to_reg_s3;
            mem_op_s4     <= mem_op_s3;
            reg_write_s4  <= reg_write_s3;
            addr_wr_s4    <= addr_wr_s3;
        end
    end

    wire [DATA_WIDTH - 1 : 0] data_mem_read_s4;
    data_mem u_data_mem_s4(
        .clk     (clk              ),
        .rst_n   (rst_n            ),
        .wr_en   (mem_write_s4     ),
        .mem_op  (mem_op_s4        ),
        .addr    (alu_result_s4    ),
        .data_wr (data_rd2_s4      ),
        .data_rd (data_mem_read_s4 )
    );

    reg [DATA_WIDTH - 1 : 0] alu_result_s5;
    reg [DATA_WIDTH - 1 : 0] data_mem_read_s5;
    reg mem_to_reg_s5;
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_result_s5    <= {DATA_WIDTH{1'b0}};
            data_mem_read_s5 <= {DATA_WIDTH{1'b0}};
            mem_to_reg_s5    <= 1'b0;
            reg_write_s5     <= 1'b0;
            addr_wr_s5       <= 5'b0;
        end
        else begin
            alu_result_s5    <= alu_result_s4;
            data_mem_read_s5 <= data_mem_read_s4;
            mem_to_reg_s5    <= mem_to_reg_s4;
            reg_write_s5     <= reg_write_s4;
            addr_wr_s5       <= addr_wr_s4;
        end
    end

    write_back_sel u_write_back_sel_s5(
        .mem_to_reg      (mem_to_reg_s5     ),
        .data_mem_read   (data_mem_read_s5  ),
        .data_alu_result (alu_result_s5     ),
        .data_wr_back    (data_wr_back_s5   )
    );

    rv_scheduler_control u_rv_scheduler_control(
        .rs1E         (rs1_addr_s3    ),
        .rs2E         (rs2_addr_s3    ),
        .rdM          (addr_wr_s4     ),
        .rdW          (addr_wr_s5     ),
        .reg_writeM   (reg_write_s4   ),
        .reg_writeW   (reg_write_s5   ),
        .mem_to_regM  (mem_to_reg_s4  ),
        .br_taken     (br_taken       ),
        .forward_rs1E (forward_rs1E   ),
        .forward_rs2E (forward_rs2E   ),
        .stallF       (stallF         ),
        .stallD       (stallD         ),
        .flushD       (flushD         ),
        .flushE       (flushE         )
    );

    // MEM阶段可用于前推的数据（含LD旁路）
    assign forward_data_M = mem_to_reg_s4 ? data_mem_read_s4 : alu_result_s4;

    // 将“寄存器读数”送入前推多路器，输出 rs1/rs2 的前推结果
    rv_scheduler_data u_rv_scheduler_data(
        .alu_src1_data (data_rd1_s3    ), // 改为原始寄存器读数
        .alu_src2_data (data_rd2_s3    ), // 改为原始寄存器读数
        .alu_resultM   (forward_data_M ), // MEM->EX 前推
        .dataW         (data_wr_back_s5),
        .forward_rs1E  (forward_rs1E   ),
        .forward_rs2E  (forward_rs2E   ),
        .data1E        (rs1_fwd_s3     ), // 输出前推后的 rs1
        .data2E        (rs2_fwd_s3     )  // 输出前推后的 rs2
    );
    
endmodule