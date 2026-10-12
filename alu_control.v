`timescale 1ns / 1ps

module alu_control (
    input [6:0] opcode,
    input [1:0] ALUOp,           // Control signal from the main control unit to determine the ALU operation
    input [2:0] funct3,          // funct3 field from the instruction (used for R-type and I-type instructions)
    input       funct7_5,        // funct7 field from the instruction (used for R-type instructions)
    input       use_fpu, 

    output reg [3:0] alu_op      // Control signal to select the specific ALU operation
);
        always @(*) begin
        if (use_fpu) begin
            alu_op = 4'b0000;  // FPU active, integer ALU idles
        end else begin
            case (ALUOp)
                2'b00: alu_op = 4'b0000;
                2'b01: alu_op = 4'b0001;
                2'b10: begin
                    case (funct3)
                        3'b000: begin
                            if (opcode == 7'b0110011 && funct7_5)
                                alu_op = 4'b0001;  // SUB
                            else
                                alu_op = 4'b0000;  // ADD/ADDI
                        end
                        3'b001: alu_op = 4'b0101;  // SLL/SLLI
                        3'b010: alu_op = 4'b1000;  // SLT/SLTI
                        3'b011: alu_op = 4'b1001;  // SLTU/SLTIU
                        3'b100: alu_op = 4'b0100;  // XOR/XORI
                        3'b101: begin
                            if (funct7_5)
                                alu_op = 4'b0111;  // SRA/SRAI
                            else
                                alu_op = 4'b0110;  // SRL/SRLI
                        end
                        3'b110: alu_op = 4'b0011;  // OR/ORI
                        3'b111: alu_op = 4'b0010;  // AND/ANDI
                        default: alu_op = 4'b0000;
                    endcase
                end
                2'b11:    alu_op = 4'b1010;
                default:  alu_op = 4'b0000;
            endcase
        end
    end
endmodule