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

string IMEM_INIT_FILE = "testbench/test_compiled_with_ldst/rv32ui-p-sw-inst.mem"; // 指令存储器的初始化文件路径
string DMEM_INIT_FILE = "testbench/test_compiled_with_ldst/rv32ui-p-sw-data.mem"; // 指令存储器的初始化文件路径
initial begin
    $readmemh(IMEM_INIT_FILE, u_cpu_top.u_inst_mem_s1.mem);
    $readmemh(DMEM_INIT_FILE, u_cpu_top.u_data_mem_s4.mem);
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
        "testbench/test_compiled_with_ldst/rv32ui-p-lb-inst.mem": monitor_pass(32'h0000041C, 32'h000003FC, "rv32ui-p-lb");
        "testbench/test_compiled_with_ldst/rv32ui-p-lbu-inst.mem": monitor_pass(32'h0000041C, 32'h000003FC, "rv32ui-p-lbu");
        "testbench/test_compiled_with_ldst/rv32ui-p-ld_st-inst.mem": monitor_pass(32'h00001018, 32'h00000FF8, "rv32ui-p-ld_st");
        "testbench/test_compiled_with_ldst/rv32ui-p-lh-inst.mem": monitor_pass(32'h0000044C, 32'h0000042C, "rv32ui-p-lh");
        "testbench/test_compiled_with_ldst/rv32ui-p-lhu-inst.mem": monitor_pass(32'h00000468, 32'h00000448, "rv32ui-p-lhu");
        "testbench/test_compiled_with_ldst/rv32ui-p-lw-inst.mem": monitor_pass(32'h0000047C, 32'h0000045C, "rv32ui-p-lw");
        "testbench/test_compiled_with_ldst/rv32ui-p-sb-inst.mem": monitor_pass(32'h00000624, 32'h00000604, "rv32ui-p-sb");
        "testbench/test_compiled_with_ldst/rv32ui-p-sh-inst.mem": monitor_pass(32'h000006A8, 32'h00000688, "rv32ui-p-sh");
        "testbench/test_compiled_with_ldst/rv32ui-p-st_ld-inst.mem": monitor_pass(32'h00000898, 32'h00000878, "rv32ui-p-st_ld");
        "testbench/test_compiled_with_ldst/rv32ui-p-sw-inst.mem": monitor_pass(32'h000006B4, 32'h00000694, "rv32ui-p-sw");
    endcase
end
endmodule