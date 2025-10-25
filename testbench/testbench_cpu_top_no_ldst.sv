module testbench_cpu_top();

`define DUMP;
string dump_file;
initial begin
    `ifdef DUMP
        if($value$plusargs("FSDB=%s",dump_file))
            $display("dump_file = %s",dump_file);
        $fsdbDumpfile(dump_file);        
        $fsdbDumpvars(0, testbench_cpu_top);
        $fsdbDumpMDA();
    `endif

end

parameter vcd_start = 100000;
parameter vcd_hold = 100;
initial begin
    `ifdef VCD_ON
        #vcd_start;
        $dumpfile("./vcd_cpu_top.vcd");
        $dumpvars(0,testbench_cpu_top.dut);
        #vcd_hold;
        # 100;
        $fclose("./vcd_cpu_top.vcd");
    `endif
end

parameter t = 100;
parameter rst_time = 5;
parameter rst_time_delete = 10;
parameter finish_time = 1000001;

logic clk  ;
logic rst_n;
cpu_top u_cpu_top(
	.clk  (clk  ),
	.rst_n(rst_n)
);

initial begin   //clock
    clk = 1'b0;
    forever begin
        #(t/2) clk = ~clk;
    end
end

initial begin   //reset
    rst_n = 1'b1;
    #rst_time rst_n = 1'b0;
    #rst_time_delete rst_n = 1'b1;
end

initial begin       //finish
    # finish_time;
    $finish;
end

string IMEM_INIT_FILE = "testbench/test_compiled_no_ldst/rv32ui-p-xori-inst.mem"; // 指令存储器的初始化文件路径
initial begin
    $readmemh(IMEM_INIT_FILE, u_cpu_top.u_inst_mem_s1.mem);
end

// Monitor task: wait until we observe a transition from last_inst -> pass_addr
task automatic monitor_pass(
    logic [31:0] pass_addr, 
    logic [31:0] last_addr,
    string testname
);
    int signed last_pc = last_addr;
    int unsigned max_cycles_local = 2000;
    int unsigned cycles_local = 0;
    logic [31:0] prev_pc, curr_pc;
    prev_pc = u_cpu_top.pc_current_s1;
    while (cycles_local < max_cycles_local) begin
        @(posedge clk);
        cycles_local++;
        curr_pc = u_cpu_top.pc_current_s1;
        if (last_pc >= 0) begin
            if ((curr_pc == pass_addr) && (prev_pc == last_pc)) begin
                $display("Test %s passed after %0d cycles.", testname, cycles_local);
                $finish;
            end
        end else begin
            // fallback: accept arrival at pass_addr
            if (curr_pc == pass_addr) begin
                $display("Test %s passed after %0d cycles. (fallback detection)", testname, cycles_local);
                $finish;
            end
        end
        prev_pc = curr_pc;
    end
    $display("Test %s TIMEOUT after %0d cycles.", testname, max_cycles_local);
    $finish;
endtask

initial begin
    case(IMEM_INIT_FILE)
        "testbench/test_compiled_no_ldst/rv32ui-p-add-inst.mem":   monitor_pass(32'h00000690, 32'h00000678, "rv32ui-p-add");
        "testbench/test_compiled_no_ldst/rv32ui-p-addi-inst.mem":  monitor_pass(32'h00000438, 32'h00000420, "rv32ui-p-addi");
        "testbench/test_compiled_no_ldst/rv32ui-p-and-inst.mem":   monitor_pass(32'h00000668, 32'h00000650, "rv32ui-p-and");
        "testbench/test_compiled_no_ldst/rv32ui-p-andi-inst.mem":  monitor_pass(32'h00000370, 32'h00000358, "rv32ui-p-andi");
        "testbench/test_compiled_no_ldst/rv32ui-p-auipc-inst.mem": monitor_pass(32'h000001F4, 32'h000001DC, "rv32ui-p-auipc");
        "testbench/test_compiled_no_ldst/rv32ui-p-beq-inst.mem":   monitor_pass(32'h00000470, 32'h00000458, "rv32ui-p-beq");
        "testbench/test_compiled_no_ldst/rv32ui-p-bge-inst.mem":   monitor_pass(32'h000004D0, 32'h000004B8, "rv32ui-p-bge");
        "testbench/test_compiled_no_ldst/rv32ui-p-bgeu-inst.mem":  monitor_pass(32'h00000504, 32'h000004EC, "rv32ui-p-bgeu");
        "testbench/test_compiled_no_ldst/rv32ui-p-blt-inst.mem":   monitor_pass(32'h00000470, 32'h00000458, "rv32ui-p-blt");
        "testbench/test_compiled_no_ldst/rv32ui-p-bltu-inst.mem":  monitor_pass(32'h000004A4, 32'h0000048C, "rv32ui-p-bltu");
        "testbench/test_compiled_no_ldst/rv32ui-p-bne-inst.mem":   monitor_pass(32'h00000474, 32'h0000045C, "rv32ui-p-bne");
        "testbench/test_compiled_no_ldst/rv32ui-p-fence_i-inst.mem":   monitor_pass(32'h0000027C, 32'h00000264, "rv32ui-p-fence_i");
        "testbench/test_compiled_no_ldst/rv32ui-p-jal-inst.mem":   monitor_pass(32'h00000204, 32'h000001EC, "rv32ui-p-jal");
        "testbench/test_compiled_no_ldst/rv32ui-p-jalr-inst.mem":  monitor_pass(32'h000002A4, 32'h0000028C, "rv32ui-p-jalr");
        "testbench/test_compiled_no_ldst/rv32ui-p-lui-inst.mem":   monitor_pass(32'h00000210, 32'h000001F8, "rv32ui-p-lui");
        "testbench/test_compiled_no_ldst/rv32ui-p-or-inst.mem":    monitor_pass(32'h00000674, 32'h0000065C, "rv32ui-p-or");
        "testbench/test_compiled_no_ldst/rv32ui-p-ori-inst.mem":   monitor_pass(32'h0000038C, 32'h00000374, "rv32ui-p-ori");
        "testbench/test_compiled_no_ldst/rv32ui-p-sll-inst.mem":   monitor_pass(32'h00000700, 32'h000006E8, "rv32ui-p-sll");
        "testbench/test_compiled_no_ldst/rv32ui-p-slli-inst.mem":  monitor_pass(32'h00000434, 32'h0000041C, "rv32ui-p-slli");
        "testbench/test_compiled_no_ldst/rv32ui-p-slt-inst.mem":   monitor_pass(32'h00000678, 32'h00000660, "rv32ui-p-slt");
        "testbench/test_compiled_no_ldst/rv32ui-p-slti-inst.mem":  monitor_pass(32'h00000424, 32'h0000040C, "rv32ui-p-slti");
        "testbench/test_compiled_no_ldst/rv32ui-p-sltiu-inst.mem": monitor_pass(32'h00000424, 32'h0000040C, "rv32ui-p-sltiu");
        "testbench/test_compiled_no_ldst/rv32ui-p-sltu-inst.mem":  monitor_pass(32'h00000678, 32'h00000660, "rv32ui-p-sltu");
        "testbench/test_compiled_no_ldst/rv32ui-p-sra-inst.mem":   monitor_pass(32'h0000074C, 32'h00000734, "rv32ui-p-sra");
        "testbench/test_compiled_no_ldst/rv32ui-p-srai-inst.mem":  monitor_pass(32'h00000468, 32'h00000450, "rv32ui-p-srai");
        "testbench/test_compiled_no_ldst/rv32ui-p-srl-inst.mem":   monitor_pass(32'h00000734, 32'h0000071C, "rv32ui-p-srl");
        "testbench/test_compiled_no_ldst/rv32ui-p-srli-inst.mem":  monitor_pass(32'h00000450, 32'h00000438, "rv32ui-p-srli");
        "testbench/test_compiled_no_ldst/rv32ui-p-sub-inst.mem":   monitor_pass(32'h00000670, 32'h00000658, "rv32ui-p-sub");
        "testbench/test_compiled_no_ldst/rv32ui-p-xor-inst.mem":   monitor_pass(32'h00000670, 32'h00000658, "rv32ui-p-xor");
        "testbench/test_compiled_no_ldst/rv32ui-p-xori-inst.mem":  monitor_pass(32'h00000394, 32'h0000037C, "rv32ui-p-xori");
    endcase
end
endmodule