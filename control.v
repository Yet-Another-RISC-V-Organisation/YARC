module main_control_unit (
    input [6:0] opcode,

    output reg RegWrite,        // Control signal to enable writing to the register file
    output reg ALUSrc,          // Control signal to select the second ALU operand (0 for register, 1 for immediate)
    output reg MemRead,         // Control signal to enable reading from memory
    output reg MemWrite,        // Control signal to enable writing to memory
    output reg [1:0] MemtoReg,  // Control signal to select the source of data for the register file
    output reg Branch,          // Control signal to enable branching (this is used with the zero flag from the ALU)
    output reg Jump,            // Control signal to enable jumping (Either to an immediate address or to a register address)
    output reg [1:0] ALUOp,     // Control signal to select the ALU operation
    output reg ALUSrcA          // Control signal to select the first ALU operand (0 for rs1, 1 for PC -- used by AUIPC)
    output reg is_ecall,        // Control signal to indicate env calling
    output reg is_ebreak        // Control signal to indicate env breaking
);
    always @(*) begin
       
        case (opcode)
            7'b0110011: begin       // R-type instructions
                RegWrite = 1'b1; 
                ALUSrc = 1'b0;
                MemRead = 1'b0;   
                MemWrite = 1'b0; 
                MemtoReg = 2'b0; 
                Branch = 1'b0;   
                Jump = 1'b0;     
                ALUOp = 2'b10;
                ALUSrcA = 1'b0;
                is_ecall  = 1'b0;
                is_ebreak = 1'b0;
                end
            7'b0010011: begin       // I-type instructions (e.g., immediate arithmetic)
                RegWrite = 1'b1;  
                ALUSrc = 1'b1;    
                MemRead = 1'b0;   
                MemWrite = 1'b0;  
                MemtoReg = 2'b0;  
                Branch = 1'b0;    
                Jump = 1'b0;      
                ALUOp = 2'b10;
                ALUSrcA = 1'b0;
                is_ecall  = 1'b0;
                is_ebreak = 1'b0;
            end
            7'b0000011: begin       // Load instructions (e.g., lw)
                RegWrite = 1'b1;  
                ALUSrc = 1'b1;    
                MemRead = 1'b1;   
                MemWrite = 1'b0;  
                MemtoReg = 2'b01; 
                Branch = 1'b0;    
                Jump = 1'b0;      
                ALUOp = 2'b00;
                ALUSrcA = 1'b0;
                is_ecall  = 1'b0;
                is_ebreak = 1'b0;
            end
            7'b0100011: begin        // Store instructions (e.g., sw)
                RegWrite = 1'b0;  
                ALUSrc = 1'b1;    
                MemRead = 1'b0;   
                MemWrite = 1'b1;  
                MemtoReg = 2'b0;  
                Branch = 1'b0;    
                Jump = 1'b0;      
                ALUOp = 2'b00;
                ALUSrcA = 1'b0;
                is_ecall  = 1'b0;
                is_ebreak = 1'b0;
            end
            7'b1100011: begin          // Branch instructions (e.g., beq)
                RegWrite = 1'b0;  
                ALUSrc = 1'b0;    
                MemRead = 1'b0;   
                MemWrite = 1'b0;  
                MemtoReg = 2'b0;  
                Branch = 1'b1;    
                Jump = 1'b0;      
                ALUOp = 2'b01;
                ALUSrcA = 1'b0;
                is_ecall  = 1'b0;
                is_ebreak = 1'b0;
            end
            7'b1101111: begin           // Jump instructions (e.g., jal)
                RegWrite = 1'b1;  
                ALUSrc = 1'b0;    
                MemRead = 1'b0;   
                MemWrite = 1'b0;  
                MemtoReg = 2'b10; 
                Branch = 1'b0;    
                Jump = 1'b1;      
                ALUOp = 2'b00;
                ALUSrcA = 1'b0;
                is_ecall  = 1'b0;
                is_ebreak = 1'b0;
            end
            7'b1100111: begin           // jalr instructions
                RegWrite = 1'b1;  
                ALUSrc = 1'b1;    
                MemRead = 1'b0;   
                MemWrite = 1'b0;  
                MemtoReg = 2'b10; 
                Branch = 1'b0;    
                Jump = 1'b1;      
                ALUOp = 2'b00;
                ALUSrcA = 1'b0;
                is_ecall  = 1'b0;
                is_ebreak = 1'b0;
            end
            7'b0110111: begin           // LUI instructions
                RegWrite = 1'b1;  
                ALUSrc = 1'b1;    
                MemRead = 1'b0;   
                MemWrite = 1'b0;  
                MemtoReg = 2'b00; 
                Branch = 1'b0;    
                Jump = 1'b0;      
                ALUOp = 2'b11;
                ALUSrcA = 1'b0;
                is_ecall  = 1'b0;
                is_ebreak = 1'b0;
            end
            7'b0010111: begin           // AUIPC instructions
                RegWrite = 1'b1;  
                ALUSrc = 1'b1;    
                MemRead = 1'b0;   
                MemWrite = 1'b0;  
                MemtoReg = 2'b00; 
                Branch = 1'b0;    
                Jump = 1'b0;      
                ALUOp = 2'b00;
                ALUSrcA = 1'b1;
                is_ecall  = 1'b0;
                is_ebreak = 1'b0;
            end
            7'b1110011: begin // ECALL / EBREAK
                RegWrite  = 1'b0;
                ALUSrc    = 1'b0;
                ALUSrcA   = 1'b0;
                MemRead   = 1'b0;
                MemWrite  = 1'b0;
                MemtoReg  = 2'b0;
                Branch    = 1'b0;
                Jump      = 1'b0;
                ALUOp     = 2'b00;
                is_ecall  = (instr[31:20] == 12'b0);
                is_ebreak = (instr[31:20] == 12'b000000000001);
            end
            default: begin              // This should NOT happen
                RegWrite = 1'b0;  
                ALUSrc = 1'b0;    
                MemRead = 1'b0;   
                MemWrite = 1'b0;  
                MemtoReg = 2'b00; 
                Branch = 1'b0;    
                Jump = 1'b0;      
                ALUOp = 2'b00;
                ALUSrcA = 1'b0;
                is_ecall  = 1'b0;
                is_ebreak = 1'b0;
            end
        endcase 
        
    end

endmodule
