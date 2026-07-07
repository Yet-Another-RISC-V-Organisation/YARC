`timescale 1ns / 1ps

module ALU (
    input [31:0] input1,        // First operand for the ALU operation
    input [31:0] input2,        // Second operand for the ALU operation
    input [3:0] alu_op,         // Control signal to determine the ALU operation
    output reg [31:0] result,   // Result of the ALU operation
    output  zero,               // Flag indicating if the result is zero
    output  lt,                 // signed less-than
    output  ltu,                // unsigned less-than
    output  negative            // result[31]
);

    always @(*) begin
        case (alu_op)
            4'b0000: result = input1 + input2; // ADD
            4'b0001: result = input1 - input2; // SUB
            4'b0010: result = input1 & input2; // AND
            4'b0011: result = input1 | input2; // OR
            4'b0100: result = input1 ^ input2; // XOR
            4'b0101: result = input1 << input2[4:0]; // SLL
            4'b0110: result = input1 >> input2[4:0]; // SRL
            4'b0111: result = $signed(input1) >>> input2[4:0]; // SRA   
            4'b1000: result = ($signed(input1) < $signed(input2)) ? 32'b1 : 32'b0; // SLT
            4'b1001: result = (input1 < input2) ? 32'b1 : 32'b0; // SLTU
            4'b1010: result = input2; // pass B 
            default: result = 32'b0; // Default case
        endcase
        
    end
    assign zero = (result == 32'b0) ? 1'b1 : 1'b0;          // Set zero flag if result is zero
    assign lt = ($signed(input1) < $signed(input2));        //flag for signed less than(pretty much slt's job but it is used for branching)
    assign negative = result[31];                           // negative flag has the same purpose.
    assign ltu = (input1 < input2);                         // flag for unsigned less than (used by BLTU/BGEU)

endmodule