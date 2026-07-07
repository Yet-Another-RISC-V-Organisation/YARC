`timescale 1ns / 1ps

module alu_control (
    input [6:0] opcode_i,
    input [1:0] ALUOp_i,           // Control signal from the main control unit to determine the ALU operation
    input [2:0] funct3_i,          // funct3 field from the instruction (used for R-type and I-type instructions)
    input       funct7_5_i,        // funct7 field from the instruction (used for R-type instructions)
    
    output reg [3:0] ALU_op_o      // Control signal to select the specific ALU operation
);
    always @(*) begin
        case (ALUOp_i)
            2'b00: begin
                ALU_op_o = 4'b0000; // For load and store instructions, the ALU performs addition to calculate the address
            end
            2'b01: begin
                ALU_op_o = 4'b0001; // For branch instructions, the ALU performs subtraction to calculate the difference
            end
            2'b10: begin
                case (funct3_i)
                    3'b000: begin
                        if (opcode_i == 7'b0110011 && funct7_5_i)
                            ALU_op_o = 4'b0001; // SUB only for R-type SUB
                        else
                            ALU_op_o = 4'b0000; // ADD or ADDI
                    end

                    3'b001: ALU_op_o = 4'b0101; // SLL/SLLI
                    3'b010: ALU_op_o = 4'b1000; // SLT/SLTI
                    3'b011: ALU_op_o = 4'b1001; // SLTU/SLTIU
                    3'b100: ALU_op_o = 4'b0100; // XOR/XORI

                    3'b101: begin
                        if (funct7_5_i)
                            ALU_op_o = 4'b0111; // SRA/SRAI
                        else
                            ALU_op_o = 4'b0110; // SRL/SRLI
                    end

                    3'b110: ALU_op_o = 4'b0011; // OR/ORI
                    3'b111: ALU_op_o = 4'b0010; // AND/ANDI

                    default: ALU_op_o = 4'b0000;
                endcase
            end
            2'b11: begin
                ALU_op_o = 4'b1010;                   // For JALR instructions, the ALU performs a pass-through of the second operand (the immediate value) to calculate the jump address
            end
            default: ALU_op_o = 4'b0000;              // Default to ADD for safety
        endcase
    end
endmodule