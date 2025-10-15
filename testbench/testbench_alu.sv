import my_pkg::*;
module testbench_alu();

`define DUMP;
string dump_file;
initial begin
    `ifdef DUMP
        if($value$plusargs("FSDB=%s",dump_file))
            $display("dump_file = %s",dump_file);
        $fsdbDumpfile(dump_file);        
        $fsdbDumpvars(0, testbench_alu);
        $fsdbDumpMDA();
    `endif

end

parameter vcd_start = 100000;
parameter vcd_hold = 100;

initial begin
    `ifdef VCD_ON
        #vcd_start;
        $dumpfile("./vcd_alu.vcd");
        $dumpvars(0,testbench_alu.dut);
        #vcd_hold;
        # 100;
        $fclose("./vcd_alu.vcd");
    `endif
end


parameter t = 100;
parameter rst_time = 5;
parameter rst_time_delete = 10;
parameter finish_time = 1000001;

logic [DATA_WIDTH - 1 : 0] a     ;
logic [DATA_WIDTH - 1 : 0] b     ;
logic [3 : 0] alu_op;
logic [DATA_WIDTH - 1 : 0] result;
logic zero;
logic less;

class alu_op_class;
    randc logic [3 : 0] alu_op;
    constraint alu_op_cons{
        alu_op inside{
            ALU_ADD ,
            ALU_SUB ,
            ALU_SLL ,
            ALU_SLT ,
            ALU_SLTU,
            ALU_XOR ,
            ALU_SRL ,
            ALU_SRA ,
            ALU_OR  ,
            ALU_AND 
        };
    }
endclass

alu dut(
	.a     (a     ),
	.b     (b     ),
	.alu_op(alu_op),
	.result(result),
	.zero  (zero  ),
	.less  (less  )
);

initial begin       //finish
    # finish_time;
    $finish;
end

initial begin
    alu_op_class alu_op_instance;
    alu_op_instance = new();
    for(int i = 0 ; i <= 100 ; i ++) begin
        # 100;
        if(i == 100) begin
            a = $urandom;
            b = a;
            alu_op = ALU_SUB;
        end
        else begin
            alu_op_instance.randomize();
            a = $urandom;
            b = $urandom;
            alu_op = alu_op_instance.alu_op;
        end
    end
end

endmodule