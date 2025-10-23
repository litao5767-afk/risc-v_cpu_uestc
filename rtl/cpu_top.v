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
    
    pc_reg u_pc_reg(
        .clk        (clk          ),
        .rst_n      (rst_n        ),
        .en         (1'b1         ),
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
    wire en_s1_s2 = 1'b1;
    wire clr_s1_s2 = 1'b0;
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
        .data_rd1 (data_rd1_s2         ),  
        .data_rd2 (data_rd2_s2         )
    );

    // stage-5 write-back registers (declare here to avoid implicit net creation
    // when used earlier in module instantiations)
    // (stage-5 regs declared earlier)

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
    wire en_s2_s3 = 1'b1;
    wire clr_s2_s3 = 1'b0;
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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
        end 
        else if(clr_s2_s3) begin
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
        end
        else if(en_s2_s3) begin
            imm_s3        <= imm_s2       ;
            data_rd1_s3   <= data_rd1_s2  ;
            data_rd2_s3   <= data_rd2_s2  ;
            alu_op_s3     <= alu_op_s2    ;
            alu_src_s3    <= alu_src_s2   ;
            branch_s3     <= branch_s2    ;
            mem_write_s3  <= mem_write_s2 ;
            mem_to_reg_s3 <= mem_to_reg_s2;
            mem_op_s3     <= mem_op_s2    ;
            reg_write_s3  <= reg_write_s2 ;
            addr_wr_s3    <= addr_wr_s2   ;
            pc_current_s3 <= pc_current_s2;
        end
    end

    wire [DATA_WIDTH - 1 : 0] data_src1;
    wire [DATA_WIDTH - 1 : 0] data_src2;
    alu_src_sel u_alu_src_sel_s3(
        .rs1    (data_rd1_s3),
        .pc     (pc_current_s3 ),
        .rs2    (data_rd2_s3   ),
        .imm    (imm_s3        ),
        .alu_src(alu_src_s3    ),
        .data1  (data_src1  ),
        .data2  (data_src2  )
    );
    
    wire [DATA_WIDTH - 1 : 0] alu_result_s3;
    wire zero_s3;
    wire less_s3;
    alu u_alu_s3(
        .a      (data_src1  ),
        .b      (data_src2  ),
        .alu_op (alu_op_s3     ),
        .result (alu_result_s3 ),
        .zero   (zero_s3       ),
        .less   (less_s3       )
    );
    
    reg zero_s4;
    reg less_s4;
    reg [DATA_WIDTH - 1 : 0] alu_result_s4;
    reg mem_write_s4;
    reg mem_to_reg_s4;
    reg [2 : 0] mem_op_s4;
    reg reg_write_s4;
    reg [4 : 0] addr_wr_s4;
    reg [2 : 0] branch_s4;
    reg [ADDR_WIDTH - 1 : 0] pc_current_s4;
    reg [DATA_WIDTH - 1 : 0] data_rd1_s4;
    reg [DATA_WIDTH - 1 : 0] data_rd2_s4;
    reg [DATA_WIDTH - 1 : 0] imm_s4;
    wire en_s3_s4 = 1'b1;
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            zero_s4        <= 1'b0;
            less_s4        <= 1'b0;
            alu_result_s4  <= {DATA_WIDTH{1'b0}};
            mem_write_s4   <= 1'b0;
            mem_to_reg_s4  <= 1'b0;
            mem_op_s4      <= 3'b0;
            reg_write_s4   <= 1'b0;
            addr_wr_s4     <= 5'b0;
            branch_s4      <= 3'b0;
            pc_current_s4  <= {ADDR_WIDTH{1'b0}};
            data_rd1_s4    <= {DATA_WIDTH{1'b0}};
            data_rd2_s4    <= {DATA_WIDTH{1'b0}};
            imm_s4         <= {DATA_WIDTH{1'b0}};
        end 
        else if(en_s3_s4) begin
            zero_s4        <= zero_s3       ;
            less_s4        <= less_s3       ;
            alu_result_s4  <= alu_result_s3 ;
            mem_write_s4   <= mem_write_s3  ;
            mem_to_reg_s4  <= mem_to_reg_s3 ;
            mem_op_s4      <= mem_op_s3     ;
            reg_write_s4   <= reg_write_s3  ;
            addr_wr_s4     <= addr_wr_s3    ;
            branch_s4      <= branch_s3     ;
            pc_current_s4  <= pc_current_s3 ;
            data_rd1_s4    <= data_rd1_s3   ;
            data_rd2_s4    <= data_rd2_s3   ;
            imm_s4         <= imm_s3        ;
        end 
    end

    rv_nextpc_gen u_rv_nextpc_gen_s4(
        .zero   (zero_s4       ),
        .less   (less_s4       ),
        .branch (branch_s4     ),
        .pc     (pc_current_s4 ),
        .rs     (data_rd1_s4   ),
        .imm    (imm_s4        ),
        .nextpc (nextpc     )
    );

    wire [DATA_WIDTH - 1 : 0] data_rd_s4;
    data_mem u_data_mem_s4(
        .clk    (clk        ),
        .rst_n  (rst_n      ),
        .wr_en  (mem_write_s4  ),
        .mem_op (mem_op_s4     ),
        .addr   (alu_result_s4 ),
        .data_wr(data_rd2_s4   ),
        .data_rd(data_rd_s4    )
    );

    reg mem_to_reg_s5;
    reg [DATA_WIDTH - 1 : 0] data_rd_s5;
    reg [DATA_WIDTH - 1 : 0] alu_result_s5;
    wire en_s4_s5 = 1'b1;
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_to_reg_s5  <= 1'b0;
            alu_result_s5  <= {DATA_WIDTH{1'b0}};
            data_rd_s5     <= {DATA_WIDTH{1'b0}};
            addr_wr_s5     <= 5'b0;
            reg_write_s5   <= 1'b0;
        end 
        else if(en_s4_s5) begin
            mem_to_reg_s5  <= mem_to_reg_s4 ;
            alu_result_s5  <= alu_result_s4 ;
            data_rd_s5     <= data_rd_s4    ;
            addr_wr_s5     <= addr_wr_s4    ;
            reg_write_s5   <= reg_write_s4  ;
        end
    end
    write_back_sel u_write_back_sel_s5(
        .mem_to_reg     (mem_to_reg_s5     ),
        .data_mem_read  (data_rd_s5        ),
        .data_alu_result(alu_result_s5     ),
        .data_wr_back   (data_wr_back_s5   )
    );

    // rv_scheduler u_rv_scheduler_s2(
    //     .rsE1       (inst_s2[19 : 15]  ),
    //     .rsE2       (inst_s2[24 : 20]  ),
    //     .wr_back_rd (addr_wr_s5         ),
    //     .mem_rd     (addr_wr_s4         ),
    //     .mem_to_reg (mem_to_reg_s4      ),
    //     .reg_write  (reg_write_s5       )
    // );
endmodule