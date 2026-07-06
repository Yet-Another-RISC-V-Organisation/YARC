module main_control_unit (
    input [6:0] opcode,
    input [11:0] instr,

    output reg RegWrite,        // Control signal to enable writing to the register file
    output reg ALUSrc,          // Control signal to select the second ALU operand (0 for register, 1 for immediate)
    output reg MemRead,         // Control signal to enable reading from memory
    output reg MemWrite,        // Control signal to enable writing to memory
    output reg [1:0] MemtoReg,  // Control signal to select the source of data for the register file
    output reg Branch,          // Control signal to enable branching (this is used with the zero flag from the ALU)
    output reg Jump,            // Control signal to enable jumping (Either to an immediate address or to a register address)
    output reg [1:0] ALUOp,     // Control signal to select the ALU operation
    output reg ALUSrcA,         // Control signal to select the first ALU operand (0 for rs1, 1 for PC -- used by AUIPC)
    output reg is_ecall,        // Control signal to indicate env calling  
    output reg is_ebreak,       // Control signal to indicate env breaking  // curently ecall, ebreak, fence are treaded are nops but their control signals exist
    output reg is_fence         // Control signal to indicate fencing
);

    // LOCAL PARAMETERS //
    localparam OP_R_TYPE = 7'b0110011;
    localparam OP_I_TYPE = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JUMP   = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_SYSTEM = 7'b1110011;
    localparam OP_FENCE  = 7'b0001111;

    always @(*) begin
       
        case (opcode)
            OP_R_TYPE: begin       // R-type instructions
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
                is_fence  = 1'b0;
                end
            OP_I_TYPE: begin       // I-type instructions (e.g., immediate arithmetic)
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
                is_fence  = 1'b0;
            end
            OP_LOAD: begin       // Load instructions (e.g., lw)
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
                is_fence  = 1'b0;
            end
            OP_STORE: begin        // Store instructions (e.g., sw)
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
                is_fence  = 1'b0;
            end
            OP_BRANCH: begin          // Branch instructions (e.g., beq)
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
                is_fence  = 1'b0;
            end
            OP_JUMP: begin           // Jump instructions (e.g., jal)
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
                is_fence  = 1'b0;
            end
            OP_JALR: begin           // jalr instructions
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
                is_fence  = 1'b0;
            end
            OP_LUI: begin           // LUI instructions
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
                is_fence  = 1'b0;
            end
            OP_AUIPC: begin           // AUIPC instructions
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
                is_fence  = 1'b0;
            end
            OP_SYSTEM: begin // ECALL / EBREAK
                RegWrite  =  1'b0;
                ALUSrc    =  1'b0;
                ALUSrcA   =  1'b0;
                MemRead   =  1'b0;
                MemWrite  =  1'b0;
                MemtoReg  = 2'b00;
                Branch    =  1'b0;
                Jump      =  1'b0;
                ALUOp     = 2'b00;
                is_ecall  = (instr == 12'b0);
                is_ebreak = (instr == 12'b000000000001);
                is_fence  = 1'b0;
            end
            OP_FENCE: begin // FENCE
                RegWrite  = 1'b0;
                ALUSrc    = 1'b0;
                ALUSrcA   = 1'b0;
                MemRead   = 1'b0;
                MemWrite  = 1'b0;
                MemtoReg  = 2'b0;
                Branch    = 1'b0;
                Jump      = 1'b0;
                ALUOp     = 2'b00;
                is_ecall  = 1'b0;
                is_ebreak = 1'b0;
                is_fence  = 1'b1;  
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
                is_fence  = 1'b0;
            end
        endcase 
        
    end

endmodule
