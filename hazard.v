`timescale 1ns / 1ps

module hazard (
    input [4:0] rs1_ID,         // source registers of instruction currently in ID
    input [4:0] rs2_ID,


    input [4:0] rd_EX,          // destination of instruction currently in EX 
    input       mem_read_EX,    // high only for load instructions

    output reg stall            // stall PC and IF/ID, flush ID/EX
);

    always @(*) begin
        if (mem_read_EX && rd_EX != 5'b0 &&
           (rd_EX == rs1_ID || rd_EX == rs2_ID))
            stall = 1'b1;  
        else
            stall = 1'b0;
    end

endmodule