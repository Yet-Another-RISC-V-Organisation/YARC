// Forward Unit:
// Currently consists of forward from: EX/MEM, MEM/WB, None

module forward (
    input [4:0] rs1_EX,          // source registers of instruction in EX
    input [4:0] rs2_EX,

    input [4:0] rd_MEM,          // destination and write-enable of instruction in EX/MEM
    input       reg_write_MEM,

    input [4:0] rd_WB,           // destination and write-enable of instruction in MEM/WB
    input       reg_write_WB,

    // 00 = use register file   (No forward)
    // 01 = forward from EX/MEM (one cycle ago)
    // 10 = forward from MEM/WB (two cycles ago)
    output reg [1:0] fwd_a,  // forwarding select for ALU input A
    output reg [1:0] fwd_b   // forwarding select for ALU input B
);

    always @(*) begin
        // forward A 
        if (reg_write_MEM && rd_MEM != 5'b0 && rd_MEM == rs1_EX)
            fwd_a = 2'b01;  // forward from EX/MEM
        else if (reg_write_WB && rd_WB != 5'b0 && rd_WB == rs1_EX)
            fwd_a = 2'b10;  // forward from MEM/WB
        else
            fwd_a = 2'b00;  // use register file

        // forward B 
        if (reg_write_MEM && rd_MEM != 5'b0 && rd_MEM == rs2_EX)
            fwd_b = 2'b01;  // forward from EX/MEM
        else if (reg_write_WB && rd_WB != 5'b0 && rd_WB == rs2_EX)
            fwd_b = 2'b10;  // forward from MEM/WB
        else
            fwd_b = 2'b00;  // use register file
    end

endmodule