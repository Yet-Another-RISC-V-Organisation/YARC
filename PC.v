`timescale 1ns / 1ps

module Program_counter (
    input clock_i,                                    // Clock signal
    input reset_ni,                                   // Active-low reset signal  
    input stall_i,                                    // freeze PC during load-use hazard                      
    input [31:0] branch_address_i,                    // Branch target address
    input branch_taken_i,                              // Signal indicating whether a branch is taken

    output reg [31:0] pc_o                           // Program counter output
);

    always @(posedge clock_i or negedge reset_ni) begin
        if (!reset_ni) begin
            pc_o <= 32'b0;
        end else if (!stall_i) begin  // only update if not stalled
            if (branch_taken_i)
                pc_o <= branch_address_i;
            else
                pc_o <= pc_o + 4;
        end
        // stall: hold current pc_o, do nothing
    end

endmodule
