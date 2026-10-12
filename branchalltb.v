`timescale 1ns/1ns
`include "direction_predictor.v"
`include "btb.v"
`include "PC.v"
module GeneralBranchTB();
    reg clock=0;
    reg resetn=1;
    reg stall_i=0;

    wire [31:0] pc;
    reg [31:0] branch_address_i;
    reg branch_taken;
    wire id_ex_is_branch;
    reg [31:0] dummy_ifid_pc=0;
    reg [31:0] dummy_idex_pc=0;
    reg [31:0] dummy_target=32'd67;
    reg [2:0] counter=0;

    reg token=0; //This exists solely for the looping pc.

    wire hit;
    wire [31:0] target;

    wire prediction;
    integer i;

    initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    for(i=0; i<256; i=i+1)begin
        $dumpvars(0, GeneralBranchTB.dut2.valid[i]);
        $dumpvars(0, GeneralBranchTB.dut2.targetmem[i]);
        $dumpvars(0, GeneralBranchTB.dut2.tag[i]);
        $dumpvars(0, GeneralBranchTB.dut3.prediction_table[i]);
    end
    end
    Program_counter dut1(clock, resetn, stall_i, branch_address_i, branch_taken, pc);
    btb dut2(clock, resetn, pc, id_ex_is_branch, dummy_idex_pc, dummy_target, hit, target);
    direction_predictor dut3(clock, resetn, pc, prediction, id_ex_is_branch, dummy_idex_pc, counter[2]);


    assign id_ex_is_branch = ((dummy_idex_pc%16==0)&&((dummy_idex_pc!==0)||token));
    always @(posedge clock or negedge resetn) begin
        if(!resetn) dummy_ifid_pc <= 0;
        else dummy_ifid_pc <= pc;
    end 

    always @(posedge clock or negedge resetn) begin
        if(!resetn) dummy_idex_pc <= 0;
        else dummy_idex_pc <= dummy_ifid_pc;
    end

    always @(pc) begin //loop pc every 16 assembly lines
        if(pc==64)begin
            token = 1; branch_address_i = 0; branch_taken = 1;
        end
        else branch_taken=0;
    end

    always @(posedge clock) counter <= counter+1;
    initial forever #5 clock = ~clock;
    

    initial begin
        resetn = 0;
        #100 resetn = 1;
        #2000 $finish;
    end

    initial $monitor("PC=%d, IDEX_PC=%d, Hit=%b, Target=%h, Prediction=%b, Taken=%b", pc, dummy_idex_pc, hit, target, prediction, counter[2]);





endmodule
