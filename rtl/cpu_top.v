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

    wire [ADDR_WIDTH - 1 : 0]   pc_current;
    wire [ADDR_WIDTH - 1 : 0]   nextpc;
    
    pc_reg u_pc_reg(
        .clk        (clk        ),
        .rst_n      (rst_n      ),
        .pc_next    (nextpc     ),
        .pc_current (pc_current )
    );

    wire [DATA_WIDTH - 1 : 0] inst;
    inst_mem u_inst_mem(
        .clk   (clk         ),
        .rst_n (rst_n       ),
        .addr  (pc_current  ),
        .inst  (inst        )
    );

    wire reg_write;
    wire [DATA_WIDTH - 1 : 0] data_rd1;
    wire [DATA_WIDTH - 1 : 0] data_rd2;
    wire [DATA_WIDTH - 1 : 0] data_wr_back;
    reg_file u_reg_file(
        .clk      (clk          ),
        .rst_n    (rst_n        ),
        .wr_en    (reg_write    ),
        .addr_wr  (inst[11 : 7] ),
        .addr_rd1 (inst[19 : 15]),
        .addr_rd2 (inst[24 : 20]),
        .data_wr  (data_wr_back ),
        .data_rd1 (data_rd1     ),
        .data_rd2 (data_rd2     )
    );

    wire mem_write;
    wire mem_to_reg;
    wire [2 : 0] mem_op ;
    wire [3 : 0] alu_op ;
    wire [2 : 0] alu_src;
    wire [2 : 0] branch ;
    rv_controller u_rv_controller(
        .inst       (inst       ),
        .mem_write  (mem_write  ),
        .mem_to_reg (mem_to_reg ),
        .reg_write  (reg_write  ),
        .mem_op     (mem_op     ),
        .alu_op     (alu_op     ),
        .alu_src    (alu_src    ),
        .branch     (branch     )
    );

    wire [DATA_WIDTH - 1 : 0] imm;
    imm_gen u_imm_gen(
        .inst (inst),
        .imm  (imm )
    );

    wire [DATA_WIDTH - 1 : 0] data_src1;
    wire [DATA_WIDTH - 1 : 0] data_src2;
    alu_src_sel u_alu_src_sel(
        .rs1    (data_rd1   ),
        .pc     (pc_current ),
        .rs2    (data_rd2   ),
        .imm    (imm        ),
        .alu_src(alu_src    ),
        .data1  (data_src1  ),
        .data2  (data_src2  )
    );

    wire [DATA_WIDTH - 1 : 0] alu_result;
    wire zero;
    wire less;
    alu u_alu(
        .a      (data_src1  ),
        .b      (data_src2  ),
        .alu_op (alu_op     ),
        .result (alu_result ),
        .zero   (zero       ),
        .less   (less       )
    );
    
    rv_nextpc_gen u_rv_nextpc_gen(
        .zero   (zero       ),
        .less   (less       ),
        .branch (branch     ),
        .pc     (pc_current ),
        .rs     (data_rd1   ),
        .imm    (imm        ),
        .nextpc (nextpc     )
    );

    wire [DATA_WIDTH - 1 : 0] data_rd;
    data_mem u_data_mem(
        .clk    (clk        ),
        .rst_n  (rst_n      ),
        .wr_en  (mem_write  ),
        .mem_op (mem_op     ),
        .addr   (alu_result ),
        .data_wr(data_rd2   ),
        .data_rd(data_rd    )
    );

    write_back_sel u_write_back_sel(
        .mem_to_reg     (mem_to_reg     ),
        .data_mem_read  (data_rd        ),
        .data_alu_result(alu_result     ),
        .data_wr_back   (data_wr_back   )
    );
endmodule