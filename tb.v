// Whole testbench is based on the idea that x31 will be 1 iff all tests pass. 
// After x31 gets the value 1 we enter an inf loop. Thats why we only print x31.

`timescale 1ns/1ps
`include "cpu.v"
module tb;

// localparam IMEM_BASE = 0x00000000;
// localparam DMEM_BASE = 0x0fc10000;

reg clock;
reg resetn;

CPU dut (
    .clock (clock),
    .resetn(resetn)
);

// Clock
initial begin
    clock = 0;
    forever #5 clock = ~clock;
end

// Reset
initial begin
    resetn = 0;
    #20;
    resetn = 1;
end

// Load Program imem/dmem
initial begin
    $readmemh("build/imem.hex", dut.imem.memory);
    $readmemh("build/dmem.hex", dut.dmem.memory);
end

// Waveforms
integer i;
initial begin
    $dumpfile("cpu.vcd");
    $dumpvars(0, tb.dut);
    for (i = 0; i < 4096; i = i + 1) begin
        $dumpvars(0, tb.dut.imem.memory[i]);
    end
    for (i = 0; i < 32; i = i + 1) begin
        $dumpvars(0, tb.dut.rf.regFile[i]);
    end
end

// Stop Simulation
initial begin
    #2000;

    if (tb.dut.rf.regFile[31] == 32'd31)    // check if x31==31
        $display("Passed all tests.");
    else
        $display("Failed a test. (Check waveforms)");

    $display("Simulation timeout.");
    $finish;
end

// // Register Monitor
// always @(posedge clock) begin
//     $display(
//         "PC=%h x31=%h",
//         dut.pc,
//         dut.rf.regFile[31]
//     );
// end

endmodule