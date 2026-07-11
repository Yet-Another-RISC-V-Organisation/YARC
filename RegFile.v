`timescale 1ns / 1ps

module register_file (
    input clock_i,                // Clock signal
    input reset_ni,               // Active-low reset signal
    input [4:0] read_addr1_i,     // Address for first read port
    input [4:0] read_addr2_i,     // Address for second read port
    input [4:0] write_addr_i,     // Address for write port
    input [31:0] write_data_i,    // Data to be written to the register file
    input we_i,                   // Write enable signal

    output [31:0] read_data1_o,   // Data read from first read port
    output [31:0] read_data2_o    // Data read from second read port
);
    //  Async read, sync write.  
    reg [31:0] regFile [0:31];  // 32 registers, each 32 bits wide explained in the comment bellow
    integer i;                  //loop variable for reset believed to be for simulation

    assign read_data1_o = (we_i && write_addr_i == read_addr1_i && read_addr1_i != 0) ? write_data_i : regFile[read_addr1_i]; // This is in a sense write before read 

    assign read_data2_o = (we_i && write_addr_i == read_addr2_i && read_addr2_i != 0) ? write_data_i : regFile[read_addr2_i];

    always @(posedge clock_i or negedge reset_ni) begin //async reset

        if (!reset_ni) begin               
            for (i = 0; i < 32; i = i + 1)          //right now i believe this for loop is just for simulation purposes. Might be wrong
                regFile[i] <= 32'b0;
        end
        else if (we_i && write_addr_i != 0) begin  //x0=0 always
            regFile[write_addr_i] <= write_data_i; 
        end
    end

endmodule
