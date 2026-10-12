module FloatingRegisterFile (                    //Floating Register File. For now just single preccision 1 input 3 output ports
    input clock,                // Clock signal
    input resetn,               // Active-low reset signal
    input [4:0] read_addr1,     // Address for first read port
    input [4:0] read_addr2,     // Address for second read port
    input [4:0] read_addr3,     // Address for third read port
    input [4:0] write_addr,     // Address for write port
    input [31:0] write_data,    // Data to be written to the register file
    input we,                   // Write enable signal

    output [31:0] read_data1,   // Data read from first read port
    output [31:0] read_data2,    // Data read from second read port
    output [31:0] read_data3    // Data read from third read port

);

    reg [31:0] FloatRF [0:31];  // 32 Floats 32 bits  each
    integer i;                  //loop variable for reset believed to be for simulation

    assign read_data1 = (we && write_addr == read_addr1) ? write_data : FloatRF[read_addr1]; // same logic as RF

    assign read_data2 = (we && write_addr == read_addr2) ? write_data : FloatRF[read_addr2];

    assign read_data3 = (we && write_addr == read_addr3) ? write_data : FloatRF[read_addr3];

    always @(posedge clock or negedge resetn) begin //async reset

        if (!resetn) begin               
            for (i = 0; i < 32; i = i + 1)
                FloatRF[i] <= 32'b0;
        end
        else if (we) begin 
            FloatRF[write_addr] <= write_data; 
        end
    end
endmodule