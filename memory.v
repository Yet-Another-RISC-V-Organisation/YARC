`timescale 1ns / 1ps

module memory # (
    parameter DEPTH = 4096              // number of bytes 
) (                        
    input wire clock,                   // std clock
    input wire [31:0] address,          // address to r/w
    input wire [31:0] write_data,       // write data if w
    input wire [2:0] funct3,            // control signal from instr
    input wire mem_write,               // write if 1
    input wire mem_read,                // read if 1
    output reg [31:0] read_data         // output read data
);                                      // r and w should not be 1 at the same time

    reg [7:0] memory [0:DEPTH-1];   // Simulating byte alinged memory
    always @(posedge clock) begin
        if (mem_write) begin
            case (funct3)
                3'b000: memory[address]   <= write_data[7:0];              // SB
                3'b001: begin
                    memory[address]   <= write_data[7:0];                  // SH
                    memory[address+1] <= write_data[15:8];
                end
                3'b010: begin
                    memory[address]   <= write_data[7:0];                  // SW
                    memory[address+1] <= write_data[15:8];
                    memory[address+2] <= write_data[23:16];
                    memory[address+3] <= write_data[31:24];
                end
                default:;
            endcase
        end
    end

    always @(*) begin
            if (mem_read) begin
                case (funct3)
                    3'b000: read_data = {{24{memory[address][7]}}, memory[address]};                                    // LB  signed
                    3'b001: read_data = {{16{memory[address+1][7]}}, memory[address+1], memory[address]};               // LH signed
                    3'b010: read_data = {memory[address+3], memory[address+2], memory[address+1], memory[address]};     // LW
                    3'b100: read_data = {24'b0, memory[address]};                                                       // LBU unsigned
                    3'b101: read_data = {16'b0, memory[address+1], memory[address]};                                    // LHU unsigned
                    default: read_data = 32'b0;
                endcase
            end
            else begin
                read_data = 32'b0; // If not reading, output zero
            end
    end
endmodule