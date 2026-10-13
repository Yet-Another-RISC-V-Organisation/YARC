`timescale 1ns / 1ps

module hazard (
    // integer
    input [4:0] rs1_ID,
    input [4:0] rs2_ID,
    input [4:0] rd_EX,
    input       mem_read_EX,

    // FP: flw into FP rs1/rs2 causes same load-use hazard
    input [4:0] fp_rs1_ID,
    input [4:0] fp_rs2_ID,
    input       fp_mem_read_EX,  // high when flw is in EX
    input [4:0] fp_rd_EX,

    output reg stall
);

    always @(*) begin
        // integer load-use hazard
        if (mem_read_EX && rd_EX != 5'b0 &&
           (rd_EX == rs1_ID || rd_EX == rs2_ID))
            stall = 1'b1;
        // FP load-use hazard (flw result needed by next FP instruction)
        else if (fp_mem_read_EX &&
                (fp_rd_EX == fp_rs1_ID || fp_rd_EX == fp_rs2_ID))
            stall = 1'b1;
        else
            stall_o = 1'b0;
    end

endmodule