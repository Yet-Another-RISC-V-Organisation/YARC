// Forward Unit:
// Currently consists of forward from: EX/MEM, MEM/WB, None

module forward (
    input [4:0] rs1_EX_i,          // source registers of instruction in EX
    input [4:0] rs2_EX_i,

    input [4:0] rd_MEM_i,          // destination and write-enable of instruction in EX/MEM
    input       reg_write_MEM_i,

    input [4:0] rd_WB_i,           // destination and write-enable of instruction in MEM/WB
    input       reg_write_WB_i,

    // 00 = use register file   (No forward)
    // 01 = forward from EX/MEM (one cycle ago)
    // 10 = forward from MEM/WB (two cycles ago)
    output reg [1:0] fwd_a_o,  // forwarding select for ALU input A
    output reg [1:0] fwd_b_o   // forwarding select for ALU input B
);

    always @(*) begin
        // forward A 
        if (reg_write_MEM_i && rd_MEM_i != 5'b0 && rd_MEM_i == rs1_EX_i)
            fwd_a_o = 2'b01;  // forward from EX/MEM
        else if (reg_write_WB_i && rd_WB_i != 5'b0 && rd_WB_i == rs1_EX_i)
            fwd_a_o = 2'b10;  // forward from MEM/WB
        else
            fwd_a_o = 2'b00;  // use register file

        // forward B 
        if (reg_write_MEM_i && rd_MEM_i != 5'b0 && rd_MEM_i == rs2_EX_i)
            fwd_b_o = 2'b01;  // forward from EX/MEM
        else if (reg_write_WB_i && rd_WB_i != 5'b0 && rd_WB_i == rs2_EX_i)
            fwd_b_o = 2'b10;  // forward from MEM/WB
        else
            fwd_b_o = 2'b00;  // use register file
    end

endmodule