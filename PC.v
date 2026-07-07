`timescale 1ns / 1ps

module Program_counter (
    input clock,                                    // Clock signal
    input resetn,                                   // Active-low reset signal  
    input stall,                                    // freeze PC during load-use hazard                      
    output reg [31:0] pc,                           // Program counter output
    input [31:0] branch_address,                    // Branch target address
    input branch_taken                              // Signal indicating whether a branch is taken
);

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            pc <= 32'b0;
        end else if (!stall) begin  // only update if not stalled
            if (branch_taken)
                pc <= branch_address;
            else
                pc <= pc + 4;
        end
        // stall: hold current pc, do nothing
    end

endmodule
