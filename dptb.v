`include "direction_predictor.v"
`timescale 1ns/1ns
module direction_predictor_tb;

    reg clock = 0;
    reg resetn = 1;
    reg [31:0] pc = 0;
    reg [31:0] update_pc = 0;
    reg update_en = 0;
    reg actual_taken = 0;
    wire prediction;

    direction_predictor testunit(clock, resetn, pc, prediction, update_en, update_pc, actual_taken);

    initial forever #10 clock = ~clock;
    integer i;

    initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, direction_predictor_tb.testunit);
    for(i=0; i<256; i=i+1)
        $dumpvars(0, direction_predictor_tb.testunit.prediction_table[i]);
    end
    initial begin
        resetn = 0;
        #100 resetn = 1; pc = 32'h100;
        #10;
        if (prediction !== 0) $display("FAIL: expected weakly-not-taken");
        #10 update_pc = 32'h100; update_en = 1; actual_taken = 1;
        #10 update_pc = 32'h100; update_en = 1; actual_taken = 1;
        #10 update_pc = 32'h100; update_en = 1; actual_taken = 1;
        #10 update_pc = 32'h100; update_en = 1; actual_taken = 1;
        #10;
        if (prediction !== 1) $display("FAIL: expected taken after saturation (1)");
        #10 update_pc = 32'h100; update_en = 1; actual_taken = 0;
        #10 update_pc = 32'h100; update_en = 1; actual_taken = 0;
        #10 update_pc = 32'h100; update_en = 1; actual_taken = 0;
        #10 update_pc = 32'h100; update_en = 1; actual_taken = 0;
        #10;
        if (prediction !== 0) $display("FAIL: expected taken after saturation (2)");
        #10 update_en = 0;
        #10 pc = 32'h100;

        $display("DONE");
        $finish;

    end
    
endmodule
