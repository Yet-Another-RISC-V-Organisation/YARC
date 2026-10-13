`include "btb.v"
`timescale 1ns/1ns
module btbTB;

    reg clock = 0;
    reg resetn = 1;
    reg [31:0] pc = 0;
    reg [31:0] update_pc = 0;
    reg update_en = 0;
    reg [31:0] update_target;

    wire hit;
    wire [31:0] target;

    btb dut(clock, resetn, pc, update_en, update_pc, update_target, hit, target);


    initial forever #10 clock = ~clock;
    integer i;

    initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    for(i=0; i<256; i=i+1)begin
        $dumpvars(0, btbTB.dut.valid[i]);
        $dumpvars(0, btbTB.dut.targetmem[i]);
        $dumpvars(0, btbTB.dut.tag[i]);
    end
    end

    initial begin

        resetn = 0; pc = 32'h100;
        #100 resetn = 1; pc = 32'h100;
        if (hit !== 0) $display("FAIL: check valid bits!!!!");
        #10 update_en = 1; update_pc = 32'h100; update_target = 1;
        #10;
        #10 if(hit !== 1) $display("FAIL: check hit logic!!!!");
        #10 update_target = 2;
        #10;
        #10 if(target !== 2) $display("FAIL: check target logic!!!!");
        #10;
        #10 pc = 32'b00000001000000000000000100000000;
        #10;
        #10 if(hit !== 0) $display("FAIL: check tag logic!!!!");
        $display("DONE");
        $finish;
    end


endmodule