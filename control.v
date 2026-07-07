`timescale 1ns / 1ps

module main_control_unit (
    input [6:0] opcode_i,
    input [11:0] instr_i,

    output reg reg_write_o,         // Control signal to enable writing to the register file
    output reg ALU_src_o,           // Control signal to select the second ALU operand (0 for register, 1 for immediate) //todo
    output reg mem_read_o,          // Control signal to enable reading from memory
    output reg mem_write_o,         // Control signal to enable writing to memory
    output reg [1:0] mem_to_reg_o,  // Control signal to select the source of data for the register file
    output reg branch_o,            // Control signal to enable branching (this is used with the zero flag from the ALU)
    output reg jump_o,              // Control signal to enable jumping (Either to an immediate address or to a register address)
    output reg [1:0] ALU_op_o,      // Control signal to select the ALU operation
    output reg ALU_srcA_o,          // Control signal to select the first ALU operand (0 for rs1, 1 for PC -- used by AUIPC)
    output reg is_ecall_o,          // Control signal to indicate env calling  
    output reg is_ebreak_o,         // Control signal to indicate env breaking  // curently ecall, ebreak, fence are treaded are nops but their control signals exist
    output reg is_fence_o           // Control signal to indicate fencing
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
       
        case (opcode_i)
            OP_R_TYPE: begin       // R-type instructions
                reg_write_o = 1'b1; 
                ALU_src_o = 1'b0;
                mem_read_o = 1'b0;   
                mem_write_o = 1'b0; 
                mem_to_reg_o = 2'b0; 
                branch_o = 1'b0;   
                jump_o = 1'b0;     
                ALU_op_o = 2'b10;
                ALU_srcA_o = 1'b0;
                is_ecall_o  = 1'b0;
                is_ebreak_o = 1'b0;
                is_fence_o  = 1'b0;
                end
            OP_I_TYPE: begin       // I-type instructions (e.g., immediate arithmetic)
                reg_write_o = 1'b1;  
                ALU_src_o = 1'b1;    
                mem_read_o = 1'b0;   
                mem_write_o = 1'b0;  
                mem_to_reg_o = 2'b0;  
                branch_o = 1'b0;    
                jump_o = 1'b0;      
                ALU_op_o = 2'b10;
                ALU_srcA_o = 1'b0;
                is_ecall_o  = 1'b0;
                is_ebreak_o = 1'b0;
                is_fence_o  = 1'b0;
            end
            OP_LOAD: begin       // Load instructions (e.g., lw)
                reg_write_o = 1'b1;  
                ALU_src_o = 1'b1;    
                mem_read_o = 1'b1;   
                mem_write_o = 1'b0;  
                mem_to_reg_o = 2'b01; 
                branch_o = 1'b0;    
                jump_o = 1'b0;      
                ALU_op_o = 2'b00;
                ALU_srcA_o = 1'b0;
                is_ecall_o  = 1'b0;
                is_ebreak_o = 1'b0;
                is_fence_o  = 1'b0;
            end
            OP_STORE: begin        // Store instructions (e.g., sw)
                reg_write_o = 1'b0;  
                ALU_src_o = 1'b1;    
                mem_read_o = 1'b0;   
                mem_write_o = 1'b1;  
                mem_to_reg_o = 2'b0;  
                branch_o = 1'b0;    
                jump_o = 1'b0;      
                ALU_op_o = 2'b00;
                ALU_srcA_o = 1'b0;
                is_ecall_o  = 1'b0;
                is_ebreak_o = 1'b0;
                is_fence_o  = 1'b0;
            end
            OP_BRANCH: begin          // branch instructions (e.g., beq)
                reg_write_o = 1'b0;  
                ALU_src_o = 1'b0;    
                mem_read_o = 1'b0;   
                mem_write_o = 1'b0;  
                mem_to_reg_o = 2'b0;  
                branch_o = 1'b1;    
                jump_o = 1'b0;      
                ALU_op_o = 2'b01;
                ALU_srcA_o = 1'b0;
                is_ecall_o  = 1'b0;
                is_ebreak_o = 1'b0;
                is_fence_o  = 1'b0;
            end
            OP_JUMP: begin           // jump instructions (e.g., jal)
                reg_write_o = 1'b1;  
                ALU_src_o = 1'b0;    
                mem_read_o = 1'b0;   
                mem_write_o = 1'b0;  
                mem_to_reg_o = 2'b10; 
                branch_o = 1'b0;    
                jump_o = 1'b1;      
                ALU_op_o = 2'b00;
                ALU_srcA_o = 1'b0;
                is_ecall_o  = 1'b0;
                is_ebreak_o = 1'b0;
                is_fence_o  = 1'b0;
            end
            OP_JALR: begin           // jalr instructions
                reg_write_o = 1'b1;  
                ALU_src_o = 1'b1;    
                mem_read_o = 1'b0;   
                mem_write_o = 1'b0;  
                mem_to_reg_o = 2'b10; 
                branch_o = 1'b0;    
                jump_o = 1'b1;      
                ALU_op_o = 2'b00;
                ALU_srcA_o = 1'b0;
                is_ecall_o  = 1'b0;
                is_ebreak_o = 1'b0;
                is_fence_o  = 1'b0;
            end
            OP_LUI: begin           // LUI instructions
                reg_write_o = 1'b1;  
                ALU_src_o = 1'b1;    
                mem_read_o = 1'b0;   
                mem_write_o = 1'b0;  
                mem_to_reg_o = 2'b00; 
                branch_o = 1'b0;    
                jump_o = 1'b0;      
                ALU_op_o = 2'b11;
                ALU_srcA_o = 1'b0;
                is_ecall_o  = 1'b0;
                is_ebreak_o = 1'b0;
                is_fence_o  = 1'b0;
            end
            OP_AUIPC: begin           // AUIPC instructions
                reg_write_o = 1'b1;  
                ALU_src_o = 1'b1;    
                mem_read_o = 1'b0;   
                mem_write_o = 1'b0;  
                mem_to_reg_o = 2'b00; 
                branch_o = 1'b0;    
                jump_o = 1'b0;      
                ALU_op_o = 2'b00;
                ALU_srcA_o = 1'b1;
                is_ecall_o  = 1'b0;
                is_ebreak_o = 1'b0;
                is_fence_o  = 1'b0;
            end
            OP_SYSTEM: begin // ECALL / EBREAK
                reg_write_o  =  1'b0;
                ALU_src_o    =  1'b0;
                ALU_srcA_o   =  1'b0;
                mem_read_o   =  1'b0;
                mem_write_o  =  1'b0;
                mem_to_reg_o  = 2'b00;
                branch_o    =  1'b0;
                jump_o      =  1'b0;
                ALU_op_o     = 2'b00;
                is_ecall_o  = (instr_i == 12'b0);
                is_ebreak_o = (instr_i == 12'b000000000001);
                is_fence_o  = 1'b0;
            end
            OP_FENCE: begin // FENCE
                reg_write_o  = 1'b0;
                ALU_src_o    = 1'b0;
                ALU_srcA_o   = 1'b0;
                mem_read_o   = 1'b0;
                mem_write_o  = 1'b0;
                mem_to_reg_o  = 2'b0;
                branch_o    = 1'b0;
                jump_o      = 1'b0;
                ALU_op_o     = 2'b00;
                is_ecall_o  = 1'b0;
                is_ebreak_o = 1'b0;
                is_fence_o  = 1'b1;  
            end
            default: begin              // This should NOT happen
                reg_write_o = 1'b0;  
                ALU_src_o = 1'b0;    
                mem_read_o = 1'b0;   
                mem_write_o = 1'b0;  
                mem_to_reg_o = 2'b00; 
                branch_o = 1'b0;    
                jump_o = 1'b0;      
                ALU_op_o = 2'b00;
                ALU_srcA_o = 1'b0;
                is_ecall_o  = 1'b0;
                is_ebreak_o = 1'b0;
                is_fence_o  = 1'b0;
            end
        endcase 
    end
endmodule