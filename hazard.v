module hazard (
    input [4:0] rs1_ID_i,         // source registers of instruction currently in ID
    input [4:0] rs2_ID_i,


    input [4:0] rd_EX_i,          // destination of instruction currently in EX 
    input       mem_read_EX_i,    // high only for load instructions

    output reg stall_o            // stall PC and IF/ID, flush ID/EX
);

    always @(*) begin
        if (mem_read_EX_i && rd_EX_i != 5'b0 &&
           (rd_EX_i == rs1_ID_i || rd_EX_i == rs2_ID_i))
            stall_o = 1'b1;  
        else
            stall_o = 1'b0;
    end

endmodule