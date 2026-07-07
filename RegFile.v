`timescale 1ns / 1ps

module register_file (
    input clock,                // Clock signal
    input resetn,               // Active-low reset signal
    input [4:0] read_addr1,     // Address for first read port
    input [4:0] read_addr2,     // Address for second read port
    input [4:0] write_addr,     // Address for write port
    input [31:0] write_data,    // Data to be written to the register file
    input we,                   // Write enable signal

    output [31:0] read_data1,   // Data read from first read port
    output [31:0] read_data2    // Data read from second read port
);
    //  Async read, sync write.  
    reg [31:0] regFile [0:31];  // 32 registers, each 32 bits wide explained in the comment bellow
    integer i;                  //loop variable for reset believed to be for simulation

    assign read_data1 = (we && write_addr == read_addr1 && read_addr1 != 0) ? write_data : regFile[read_addr1]; // This is in a sense write before read 

    assign read_data2 = (we && write_addr == read_addr2 && read_addr2 != 0) ? write_data : regFile[read_addr2];

    always @(posedge clock or negedge resetn) begin //async reset

        if (!resetn) begin               
            for (i = 0; i < 32; i = i + 1)          //right now i believe this for loop is just for simulation purposes. Might be wrong
                regFile[i] <= 32'b0;
        end
        else if (we && write_addr != 0) begin  //x0=0 always
            regFile[write_addr] <= write_data; 
        end
    end

endmodule
