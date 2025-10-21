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

string IMEM_INIT_FILE = "testbench/test_compiled/rv32ui-p-auipc.mem"; // 指令存储器的初始化文件路径
initial begin
    $readmemh(IMEM_INIT_FILE, u_cpu_top.u_inst_mem.mem);
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
    prev_pc = u_cpu_top.pc_current;
    while (cycles_local < max_cycles_local) begin
        @(posedge clk);
        cycles_local++;
        curr_pc = u_cpu_top.pc_current;
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
        "testbench/test_compiled/rv32ui-p-add.mem": monitor_pass(32'h00000690, 32'h00000670, "rv32ui-p-add");
        "testbench/test_compiled/rv32ui-p-addi.mem": monitor_pass(32'h00000438, 32'h00000418, "rv32ui-p-addi");
        "testbench/test_compiled/rv32ui-p-and.mem": monitor_pass(32'h00000668, 32'h00000648, "rv32ui-p-and");
        "testbench/test_compiled/rv32ui-p-andi.mem": monitor_pass(32'h00000370, 32'h00000350, "rv32ui-p-andi");
        "testbench/test_compiled/rv32ui-p-auipc.mem": monitor_pass(32'h000001F4, 32'h000001D4, "rv32ui-p-auipc");
        "testbench/test_compiled/rv32ui-p-beq.mem": monitor_pass(32'h00000470, 32'h00000450, "rv32ui-p-beq");
        "testbench/test_compiled/rv32ui-p-bge.mem": monitor_pass(32'h000004D0, 32'h000004B0, "rv32ui-p-bge");
        "testbench/test_compiled/rv32ui-p-bgeu.mem": monitor_pass(32'h00000504, 32'h000004E4, "rv32ui-p-bgeu");
        "testbench/test_compiled/rv32ui-p-blt.mem": monitor_pass(32'h00000470, 32'h00000450, "rv32ui-p-blt");
        "testbench/test_compiled/rv32ui-p-bltu.mem": monitor_pass(32'h000004A4, 32'h00000484, "rv32ui-p-bltu");
        "testbench/test_compiled/rv32ui-p-bne.mem": monitor_pass(32'h00000474, 32'h00000454, "rv32ui-p-bne");
        "testbench/test_compiled/rv32ui-p-fence_i.mem": monitor_pass(32'h0000027C, 32'h0000025C, "rv32ui-p-fence_i");
        "testbench/test_compiled/rv32ui-p-jal.mem": monitor_pass(32'h00000204, 32'h000001E4, "rv32ui-p-jal");
        "testbench/test_compiled/rv32ui-p-jalr.mem": monitor_pass(32'h000002A4, 32'h00000284, "rv32ui-p-jalr");
        "testbench/test_compiled/rv32ui-p-lb.mem": monitor_pass(32'h0000041C, 32'h000003FC, "rv32ui-p-lb");
        "testbench/test_compiled/rv32ui-p-lbu.mem": monitor_pass(32'h0000041C, 32'h000003FC, "rv32ui-p-lbu");
        "testbench/test_compiled/rv32ui-p-ld_st.mem": monitor_pass(32'h00001018, 32'h00000FF8, "rv32ui-p-ld_st");
        "testbench/test_compiled/rv32ui-p-lh.mem": monitor_pass(32'h0000044C, 32'h0000042C, "rv32ui-p-lh");
        "testbench/test_compiled/rv32ui-p-lhu.mem": monitor_pass(32'h00000468, 32'h00000448, "rv32ui-p-lhu");
        "testbench/test_compiled/rv32ui-p-lui.mem": monitor_pass(32'h00000210, 32'h000001F0, "rv32ui-p-lui");
        "testbench/test_compiled/rv32ui-p-lw.mem": monitor_pass(32'h0000047C, 32'h0000045C, "rv32ui-p-lw");
        "testbench/test_compiled/rv32ui-p-or.mem": monitor_pass(32'h00000674, 32'h00000654, "rv32ui-p-or");
        "testbench/test_compiled/rv32ui-p-ori.mem": monitor_pass(32'h0000038C, 32'h0000036C, "rv32ui-p-ori");
        "testbench/test_compiled/rv32ui-p-sb.mem": monitor_pass(32'h00000624, 32'h00000604, "rv32ui-p-sb");
        "testbench/test_compiled/rv32ui-p-sh.mem": monitor_pass(32'h000006A8, 32'h00000688, "rv32ui-p-sh");
        "testbench/test_compiled/rv32ui-p-sll.mem": monitor_pass(32'h00000700, 32'h000006E0, "rv32ui-p-sll");
        "testbench/test_compiled/rv32ui-p-slli.mem": monitor_pass(32'h00000434, 32'h00000414, "rv32ui-p-slli");
        "testbench/test_compiled/rv32ui-p-slt.mem": monitor_pass(32'h00000678, 32'h00000658, "rv32ui-p-slt");
        "testbench/test_compiled/rv32ui-p-slti.mem": monitor_pass(32'h00000424, 32'h00000404, "rv32ui-p-slti");
        "testbench/test_compiled/rv32ui-p-sltiu.mem": monitor_pass(32'h00000424, 32'h00000404, "rv32ui-p-sltiu");
        "testbench/test_compiled/rv32ui-p-sltu.mem": monitor_pass(32'h00000678, 32'h00000658, "rv32ui-p-sltu");
        "testbench/test_compiled/rv32ui-p-sra.mem": monitor_pass(32'h0000074C, 32'h0000072C, "rv32ui-p-sra");
        "testbench/test_compiled/rv32ui-p-srai.mem": monitor_pass(32'h00000468, 32'h00000448, "rv32ui-p-srai");
        "testbench/test_compiled/rv32ui-p-srl.mem": monitor_pass(32'h00000734, 32'h00000714, "rv32ui-p-srl");
        "testbench/test_compiled/rv32ui-p-srli.mem": monitor_pass(32'h00000450, 32'h00000430, "rv32ui-p-srli");
        "testbench/test_compiled/rv32ui-p-st_ld.mem": monitor_pass(32'h00000898, 32'h00000878, "rv32ui-p-st_ld");
        "testbench/test_compiled/rv32ui-p-sub.mem": monitor_pass(32'h00000670, 32'h00000650, "rv32ui-p-sub");
        "testbench/test_compiled/rv32ui-p-sw.mem": monitor_pass(32'h000006B4, 32'h00000694, "rv32ui-p-sw");
        "testbench/test_compiled/rv32ui-p-xor.mem": monitor_pass(32'h00000670, 32'h00000650, "rv32ui-p-xor");
        "testbench/test_compiled/rv32ui-p-xori.mem": monitor_pass(32'h00000394, 32'h00000374, "rv32ui-p-xori");
        "testbench/test_compiled/rv32um-p-div.mem": monitor_pass(32'h0000028C, 32'h0000026C, "rv32um-p-div");
        "testbench/test_compiled/rv32um-p-divu.mem": monitor_pass(32'h00000290, 32'h00000270, "rv32um-p-divu");
        "testbench/test_compiled/rv32um-p-mul.mem": monitor_pass(32'h00000678, 32'h00000658, "rv32um-p-mul");
        "testbench/test_compiled/rv32um-p-mulh.mem": monitor_pass(32'h00000678, 32'h00000658, "rv32um-p-mulh");
        "testbench/test_compiled/rv32um-p-mulhsu.mem": monitor_pass(32'h00000678, 32'h00000658, "rv32um-p-mulhsu");
        "testbench/test_compiled/rv32um-p-mulhu.mem": monitor_pass(32'h00000678, 32'h00000658, "rv32um-p-mulhu");
        "testbench/test_compiled/rv32um-p-rem.mem": monitor_pass(32'h0000028C, 32'h0000026C, "rv32um-p-rem");
        "testbench/test_compiled/rv32um-p-remu.mem": monitor_pass(32'h0000028C, 32'h0000026C, "rv32um-p-remu");
    endcase
end
endmodule