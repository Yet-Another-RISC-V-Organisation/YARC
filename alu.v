`timescale 1ns / 1ps

module ALU (
    input [31:0] input1_i,        // First operand for the ALU operation
    input [31:0] input2_i,        // Second operand for the ALU operation
    input [3:0] ALU_op_i,         // Control signal to determine the ALU operation

    output reg [31:0] result_o,   // result of the ALU operation
    output  zero_o,               // Flag indicating if the result is zero
    output  lt_o,                 // signed less-than
    output  ltu_o,                // unsigned less-than
    output  negative_o            // result[31]
);

    always @(*) begin
        case (ALU_op_i)
            4'b0000: result_o = input1_i + input2_i; // ADD
            4'b0001: result_o = input1_i - input2_i; // SUB
            4'b0010: result_o = input1_i & input2_i; // AND
            4'b0011: result_o = input1_i | input2_i; // OR
            4'b0100: result_o = input1_i ^ input2_i; // XOR
            4'b0101: result_o = input1_i << input2_i[4:0]; // SLL
            4'b0110: result_o = input1_i >> input2_i[4:0]; // SRL
            4'b0111: result_o = $signed(input1_i) >>> input2_i[4:0]; // SRA   
            4'b1000: result_o = ($signed(input1_i) < $signed(input2_i)) ? 32'b1 : 32'b0; // SLT
            4'b1001: result_o = (input1_i < input2_i) ? 32'b1 : 32'b0; // SLTU
            4'b1010: result_o = input2_i; // pass B 
            default: result_o = 32'b0; // Default case
        endcase
    end

    assign zero_o = (result_o == 32'b0) ? 1'b1 : 1'b0;          // Set zero flag if result_o is zero
    assign lt_o = ($signed(input1_i) < $signed(input2_i));        //flag for signed less than(pretty much slt's job but it is used for branching)
    assign ltu_o = (input1_i < input2_i);                         // flag for unsigned less than (used by BLTU/BGEU)
    assign negative_o = result_o[31];                           // negative flag has the same purpose.
endmodule