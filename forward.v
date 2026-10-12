`timescale 1ns / 1ps

module forward (
    input [4:0] rs1_EX,// integer sources in EX
    input [4:0] rs2_EX,

    input [4:0] rd_MEM,// integer EX/MEM
    input       reg_write_MEM,

    input [4:0] rd_WB,// integer MEM/WB
    input       reg_write_WB,

    input [4:0] fp_rs1_EX,// FP sources in EX
    input [4:0] fp_rs2_EX,

    input [4:0] fp_rd_MEM,// FP EX/MEM
    input       fp_reg_write_MEM,

    input [4:0] fp_rd_WB,// FP MEM/WB
    input       fp_reg_write_WB,

    // 00 = regfile, 01 = EX/MEM, 10 = MEM/WB
    output reg [1:0] fwd_a,
    output reg [1:0] fwd_b,

    // 00 = regfile, 01 = EX/MEM, 10 = MEM/WB
    output reg [1:0] fp_fwd_a,
    output reg [1:0] fp_fwd_b
);

    always @(*) begin
        // integer forward A
        if (reg_write_MEM && rd_MEM != 5'b0 && rd_MEM == rs1_EX)
            fwd_a = 2'b01;
        else if (reg_write_WB && rd_WB != 5'b0 && rd_WB == rs1_EX)
            fwd_a = 2'b10;
        else
            fwd_a = 2'b00;

        // integer forward B
        if (reg_write_MEM && rd_MEM != 5'b0 && rd_MEM == rs2_EX)
            fwd_b = 2'b01;
        else if (reg_write_WB && rd_WB != 5'b0 && rd_WB == rs2_EX)
            fwd_b = 2'b10;
        else
            fwd_b = 2'b00;

        // FP forward A 
        if (fp_reg_write_MEM && fp_rd_MEM == fp_rs1_EX)
            fp_fwd_a = 2'b01;
        else if (fp_reg_write_WB && fp_rd_WB == fp_rs1_EX)
            fp_fwd_a = 2'b10;
        else
            fp_fwd_a = 2'b00;

        // FP forward B
        if (fp_reg_write_MEM && fp_rd_MEM == fp_rs2_EX)
            fp_fwd_b = 2'b01;
        else if (fp_reg_write_WB && fp_rd_WB == fp_rs2_EX)
            fp_fwd_b = 2'b10;
        else
            fp_fwd_b = 2'b00;
    end

endmodule