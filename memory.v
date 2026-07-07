module memory # (
    parameter Depth = 4096              // number of bytes 
) (                        
    input wire clock_i,                   // std clock
    input wire [31:0] address_i,          // address to r/w
    input wire [31:0] write_data_i,       // write data if w
    input wire [2:0] funct3_i,            // control signal from instr
    input wire mem_write_i,               // write if 1
    input wire mem_read_i,                // read if 1

    output reg [31:0] read_data_o         // output read data
);                                      // r and w should not be 1 at the same time

    reg [7:0] memory [0:Depth-1];   // Simulating byte alinged memory
    always @(posedge clock_i) begin
        if (mem_write_i) begin
            case (funct3_i)
                3'b000: memory[address_i]   <= write_data_i[7:0];              // SB
                3'b001: begin
                    memory[address_i]   <= write_data_i[7:0];                  // SH
                    memory[address_i+1] <= write_data_i[15:8];
                end
                3'b010: begin
                    memory[address_i]   <= write_data_i[7:0];                  // SW
                    memory[address_i+1] <= write_data_i[15:8];
                    memory[address_i+2] <= write_data_i[23:16];
                    memory[address_i+3] <= write_data_i[31:24];
                end
                default:;
            endcase
        end
    end

    always @(*) begin
            if (mem_read_i) begin
                case (funct3_i)
                    3'b000: read_data_o = {{24{memory[address_i][7]}}, memory[address_i]};                                    // LB  signed
                    3'b001: read_data_o = {{16{memory[address_i+1][7]}}, memory[address_i+1], memory[address_i]};               // LH signed
                    3'b010: read_data_o = {memory[address_i+3], memory[address_i+2], memory[address_i+1], memory[address_i]};     // LW
                    3'b100: read_data_o = {24'b0, memory[address_i]};                                                       // LBU unsigned
                    3'b101: read_data_o = {16'b0, memory[address_i+1], memory[address_i]};                                    // LHU unsigned
                    default: read_data_o = 32'b0;
                endcase
            end
            else begin
                read_data_o = 32'b0; // If not reading, output zero
            end
    end
endmodule