`timescale 1ns / 1ps

module immidiateGen (
    input [31:0] instruction_i,   // The instruction from which to extract the immidiate value

    output reg [31:0] immidiate_o // immidiate output
    );

    localparam OP_R_TYPE = 7'b0110011;
    localparam OP_I_TYPE = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JUMP   = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;

    always @(*) begin
        case (instruction_i[6:0]) // opcode

        OP_R_TYPE: immidiate_o = 32'b0; // R-type

        OP_AUIPC,
        OP_LUI: immidiate_o = {instruction_i[31:12], 12'b0};// U-type

        OP_I_TYPE: immidiate_o = {{20{instruction_i[31]}}, instruction_i[31:20]};// I-type

        OP_JALR,
        OP_LOAD: immidiate_o = {{20{instruction_i[31]}}, instruction_i[31:20]};// Load and JALR

        OP_STORE: immidiate_o = {{20{instruction_i[31]}}, instruction_i[31:25], instruction_i[11:7]};// S-type
        
        OP_BRANCH: immidiate_o = {{20{instruction_i[31]}}, instruction_i[7], instruction_i[30:25], instruction_i[11:8], 1'b0};// B-type
        
        OP_JUMP: immidiate_o = {{12{instruction_i[31]}}, instruction_i[19:12], instruction_i[20], instruction_i[30:21], 1'b0};// J-type

        default: immidiate_o = 32'b0;
    endcase
end
endmodule