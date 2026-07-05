module immidiateGen (
    input [31:0] instruction,   // The instruction from which to extract the immidiate value
    output reg [31:0] immidiate // immidiate output
    );
    always @(*) begin
        case (instruction[6:0]) // opcode

        7'b0110011: immidiate = 32'b0; // R-type

        7'b0010111,
        7'b0110111: immidiate = {instruction[31:12], 12'b0};// U-type

        7'b0010011: immidiate = {{20{instruction[31]}}, instruction[31:20]};// I-type

        7'b1100111,
        7'b0000011: immidiate = {{20{instruction[31]}}, instruction[31:20]};// Load and JALR

        7'b0100011: immidiate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};// S-type
        
        7'b1100011: immidiate = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};// B-type
        
        7'b1101111: immidiate = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};// J-type

        default: immidiate = 32'b0;
    endcase
end
endmodule
// peep hole optimization TODO: only [31:7] is need from the instruction we can save 6 whole wires