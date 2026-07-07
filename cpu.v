`timescale 1ns / 1ps
`include "alu.v"
`include "alu_control.v"
`include "control.v"
`include "immGen.v"
`include "memory.v"
`include "PC.v"
`include "RegFile.v"
`include "forward.v"
`include "hazard.v"

module CPU (
    input clock,
    input resetn
);

localparam IMEM_BASE = 32'h0;
localparam [31:0] DMEM_BASE = 32'h0fc10000;

        // WIRES //

    // IF STAGE //
    wire [31:0] instr_IF;
    wire        stall;
    wire        branch_taken;
    wire [31:0] next_pc;
    wire [31:0] pc;

    // IFID //
    reg [31:0] IFID_pc;
    reg [31:0] IFID_pc_plus4;
    reg [31:0] IFID_instr;

    // ID STAGE //
    
    // decode wires //
    wire [6:0]  opcode_ID   = IFID_instr[6:0];
    wire [4:0]  rs1_ID      = IFID_instr[19:15];
    wire [4:0]  rs2_ID      = IFID_instr[24:20];
    wire [4:0]  rd_ID       = IFID_instr[11:7];
    wire [2:0]  funct3_ID   = IFID_instr[14:12];
    wire        funct7_5_ID = IFID_instr[30];
    wire [31:0] imm_ID;
    wire [31:0] rs1_data_ID;
    wire [31:0] rs2_data_ID;

    // control signals //
    wire        reg_write_ID;
    wire        alu_src_ID;
    wire        alu_src_a_ID;
    wire        mem_read_ID;
    wire        mem_write_ID;
    wire [1:0]  mem_to_reg_ID;
    wire        branch_ID;
    wire        jump_ID;
    wire [1:0]  alu_op_coarse_ID;
    wire        is_ecall_ID;
    wire        is_ebreak_ID;
    wire        is_fence_ID;

    // IDEX //
    reg [31:0] IDEX_pc;
    reg [31:0] IDEX_pc_plus4;
    reg [31:0] IDEX_rs1_data;
    reg [31:0] IDEX_rs2_data;
    reg [31:0] IDEX_imm;
    reg [4:0]  IDEX_rs1;
    reg [4:0]  IDEX_rs2;
    reg [4:0]  IDEX_rd;
    reg        IDEX_reg_write;
    reg        IDEX_alu_src;
    reg        IDEX_alu_src_a;
    reg        IDEX_mem_read;
    reg        IDEX_mem_write;
    reg [1:0]  IDEX_mem_to_reg;
    reg        IDEX_branch;
    reg        IDEX_jump;
    reg [1:0]  IDEX_alu_op_coarse;
    reg [2:0]  IDEX_funct3;
    reg        IDEX_funct7_5;
    reg [6:0]  IDEX_opcode;
    reg IDEX_is_ecall;
    reg IDEX_is_ebreak;
    reg IDEX_is_fence;

    // EX STAGE //

    wire [3:0]  alu_op_EX;
    wire [1:0]  fwd_a;
    wire [1:0]  fwd_b;
    wire [31:0] alu_a_pre_EX;
    wire [31:0] alu_a_EX;
    wire [31:0] alu_b_pre_EX;
    wire [31:0] alu_b_EX;
    wire [31:0] alu_result_EX;
    wire        zero_EX;
    wire        lt_EX;
    wire        ltu_EX;

    wire [31:0] branch_target_EX = IDEX_pc + IDEX_imm;
    wire [31:0] jalr_target_EX   = (alu_a_pre_EX + IDEX_imm) & ~32'b1;
    wire        is_jalr_EX        = IDEX_jump & IDEX_alu_src;

    // branch condition

    wire branch_cond_EX =
        (IDEX_funct3 == 3'b000) ?  zero_EX  :
        (IDEX_funct3 == 3'b001) ? ~zero_EX  :
        (IDEX_funct3 == 3'b100) ?    lt_EX  :
        (IDEX_funct3 == 3'b101) ?   ~lt_EX  :
        (IDEX_funct3 == 3'b110) ?   ltu_EX  :
                                   ~ltu_EX;

    assign branch_taken = (IDEX_branch & branch_cond_EX) | IDEX_jump;

    assign next_pc = IDEX_jump                     ? (is_jalr_EX ? jalr_target_EX : branch_target_EX) :
                    (IDEX_branch & branch_cond_EX) ? branch_target_EX :
                                                    IFID_pc_plus4;

    wire flush_IFID = branch_taken;
    wire flush_IDEX = branch_taken | stall;

    // EXMEM //
    reg [31:0] EXMEM_pc_plus4;
    reg [31:0] EXMEM_alu_result;
    reg [31:0] EXMEM_rs2_data;
    reg [4:0]  EXMEM_rd;
    reg        EXMEM_reg_write;
    reg        EXMEM_mem_read;
    reg        EXMEM_mem_write;
    reg [1:0]  EXMEM_mem_to_reg;
    reg [2:0]  EXMEM_funct3;
    reg        EXMEM_is_ecall;
    reg        EXMEM_is_ebreak;
    reg        EXMEM_is_fence;

    // MEMWB //
    reg [31:0] MEMWB_pc_plus4;
    reg [31:0] MEMWB_alu_result;
    reg [31:0] MEMWB_mem_data;
    reg [4:0]  MEMWB_rd;
    reg        MEMWB_reg_write;
    reg [1:0]  MEMWB_mem_to_reg;
    reg        MEMWB_is_ecall;
    reg        MEMWB_is_ebreak;
    reg        MEMWB_is_fence;

    // WB STAGE //

    wire [31:0] mem_read_data_MEM;
    wire [31:0] wb_data = (MEMWB_mem_to_reg == 2'b00) ? MEMWB_alu_result :
                          (MEMWB_mem_to_reg == 2'b01) ? MEMWB_mem_data   :
                                                        MEMWB_pc_plus4;

    // FORWARDING MUXES  
 
        assign alu_a_pre_EX = (fwd_a == 2'b01) ? EXMEM_alu_result :
                            (fwd_a == 2'b10) ? wb_data          :
                                                IDEX_rs1_data;

        assign alu_a_EX     = IDEX_alu_src_a ? IDEX_pc : alu_a_pre_EX;

        assign alu_b_pre_EX = (fwd_b == 2'b01) ? EXMEM_alu_result :
                              (fwd_b == 2'b10) ? wb_data          :
                                                 IDEX_rs2_data;

        assign alu_b_EX     = IDEX_alu_src ? IDEX_imm : alu_b_pre_EX;




        // PIPELINES //

    // IFID //

    always @(posedge clock or negedge resetn) begin
        if (!resetn || flush_IFID) begin
            IFID_pc       <= 32'b0;
            IFID_pc_plus4 <= 32'b0;
            IFID_instr    <= 32'b0;
        end else if (!stall) begin
            IFID_pc       <= pc;
            IFID_pc_plus4 <= pc + 4;
            IFID_instr    <= instr_IF;
        end
    end

    // IDEX //

    always @(posedge clock or negedge resetn) begin
        if (!resetn || flush_IDEX) begin
            IDEX_pc            <= 32'b0;
            IDEX_pc_plus4      <= 32'b0;
            IDEX_rs1_data      <= 32'b0;
            IDEX_rs2_data      <= 32'b0;
            IDEX_imm           <= 32'b0;
            IDEX_rs1           <= 5'b0;
            IDEX_rs2           <= 5'b0;
            IDEX_rd            <= 5'b0;
            IDEX_reg_write     <= 1'b0;
            IDEX_alu_src       <= 1'b0;
            IDEX_alu_src_a     <= 1'b0;
            IDEX_mem_read      <= 1'b0;
            IDEX_mem_write     <= 1'b0;
            IDEX_mem_to_reg    <= 2'b0;
            IDEX_branch        <= 1'b0;
            IDEX_jump          <= 1'b0;
            IDEX_alu_op_coarse <= 2'b0;
            IDEX_funct3        <= 3'b0;
            IDEX_funct7_5      <= 1'b0;
            IDEX_opcode        <= 7'b0;
            IDEX_is_ebreak     <= 1'b0;
            IDEX_is_ecall      <= 1'b0;
            IDEX_is_fence      <= 1'b0;
        end else begin
            IDEX_pc            <= IFID_pc;
            IDEX_pc_plus4      <= IFID_pc_plus4;
            IDEX_rs1_data      <= rs1_data_ID;
            IDEX_rs2_data      <= rs2_data_ID;
            IDEX_imm           <= imm_ID;
            IDEX_rs1           <= rs1_ID;
            IDEX_rs2           <= rs2_ID;
            IDEX_rd            <= rd_ID;
            IDEX_reg_write     <= reg_write_ID;
            IDEX_alu_src       <= alu_src_ID;
            IDEX_alu_src_a     <= alu_src_a_ID;
            IDEX_mem_read      <= mem_read_ID;
            IDEX_mem_write     <= mem_write_ID;
            IDEX_mem_to_reg    <= mem_to_reg_ID;
            IDEX_branch        <= branch_ID;
            IDEX_jump          <= jump_ID;
            IDEX_alu_op_coarse <= alu_op_coarse_ID;
            IDEX_funct3        <= funct3_ID;
            IDEX_funct7_5      <= funct7_5_ID;
            IDEX_opcode        <= opcode_ID;
            IDEX_is_ecall      <= is_ecall_ID;
            IDEX_is_ebreak     <= is_ebreak_ID;
            IDEX_is_fence      <= is_fence_ID;            
        end
    end

    // EXMEM //

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            EXMEM_pc_plus4   <= 32'b0;
            EXMEM_alu_result <= 32'b0;
            EXMEM_rs2_data   <= 32'b0;
            EXMEM_rd         <= 5'b0;
            EXMEM_reg_write  <= 1'b0;
            EXMEM_mem_read   <= 1'b0;
            EXMEM_mem_write  <= 1'b0;
            EXMEM_mem_to_reg <= 2'b0;
            EXMEM_funct3     <= 3'b0;
            EXMEM_is_ecall   <= 1'b0;
            EXMEM_is_ebreak  <= 1'b0;
            EXMEM_is_fence   <= 1'b0;
        end else begin
            EXMEM_pc_plus4   <= IDEX_pc_plus4;
            EXMEM_alu_result <= alu_result_EX;
            EXMEM_rs2_data   <= alu_b_pre_EX;
            EXMEM_rd         <= IDEX_rd;
            EXMEM_reg_write  <= IDEX_reg_write;
            EXMEM_mem_read   <= IDEX_mem_read;
            EXMEM_mem_write  <= IDEX_mem_write;
            EXMEM_mem_to_reg <= IDEX_mem_to_reg;
            EXMEM_funct3     <= IDEX_funct3;
            EXMEM_is_ecall  <= IDEX_is_ecall;
            EXMEM_is_ebreak <= IDEX_is_ebreak;
            EXMEM_is_fence  <= IDEX_is_fence;
        end
    end

    // MEMWB //

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            MEMWB_pc_plus4   <= 32'b0;
            MEMWB_alu_result <= 32'b0;
            MEMWB_mem_data   <= 32'b0;
            MEMWB_rd         <= 5'b0;
            MEMWB_reg_write  <= 1'b0;
            MEMWB_mem_to_reg <= 2'b0;
            MEMWB_is_ecall   <= 1'b0;
            MEMWB_is_ebreak  <= 1'b0;
            MEMWB_is_fence   <= 1'b0;
        end else begin 
            MEMWB_pc_plus4   <= EXMEM_pc_plus4;
            MEMWB_alu_result <= EXMEM_alu_result;
            MEMWB_mem_data   <= mem_read_data_MEM;
            MEMWB_rd         <= EXMEM_rd;
            MEMWB_reg_write  <= EXMEM_reg_write;
            MEMWB_mem_to_reg <= EXMEM_mem_to_reg;
            MEMWB_is_ecall   <= EXMEM_is_ecall;
            MEMWB_is_ebreak  <= EXMEM_is_ebreak;
            MEMWB_is_fence   <= EXMEM_is_fence;  
        end
    end

        // MODULES //

    Program_counter pc_reg (
        .clock_i          (clock),
        .reset_ni         (resetn),
        .stall_i          (stall),
        .branch_address_i (next_pc),
        .branch_taken_i   (branch_taken),
        .pc_o             (pc)
    );

    memory #(.Depth(4096)) imem (
        .clock_i      (clock),
        .address_i    (pc - IMEM_BASE),
        .write_data_i (32'b0),
        .funct3_i     (3'b010),
        .mem_write_i  (1'b0),
        .mem_read_i   (1'b1),
        .read_data_o  (instr_IF)
    );

    immidiateGen ig (
        .instruction_i (IFID_instr),
        .immidiate_o   (imm_ID)
    );

    main_control_unit ctrl ( 
        .opcode_i    (opcode_ID),
        .instr_i     (IFID_instr[31:20]),
        .reg_write_o  (reg_write_ID),
        .ALU_src_o    (alu_src_ID),
        .ALU_srcA_o   (alu_src_a_ID),
        .mem_read_o   (mem_read_ID),
        .mem_write_o  (mem_write_ID),
        .mem_to_reg_o  (mem_to_reg_ID),
        .branch_o    (branch_ID),
        .jump_o      (jump_ID),
        .ALU_op_o     (alu_op_coarse_ID),
    );

    register_file rf (
        .clock_i      (clock),
        .reset_ni     (resetn),
        .read_addr1_i (rs1_ID),
        .read_addr2_i (rs2_ID),
        .write_addr_i (MEMWB_rd),
        .write_data_i (wb_data),
        .we_i         (MEMWB_reg_write),
        .read_data1_o (rs1_data_ID),
        .read_data2_o (rs2_data_ID)
    );

    hazard haz (
        .rs1_ID_i      (rs1_ID),
        .rs2_ID_i      (rs2_ID),
        .rd_EX_i       (IDEX_rd),
        .mem_read_EX_i (IDEX_mem_read),
        .stall_o       (stall)
    );

    forward fwd_unit (
        .rs1_EX_i        (IDEX_rs1),
        .rs2_EX_i        (IDEX_rs2),
        .rd_MEM_i        (EXMEM_rd),
        .reg_write_MEM_i (EXMEM_reg_write),
        .rd_WB_i         (MEMWB_rd),
        .reg_write_WB_i  (MEMWB_reg_write),
        .fwd_a_o         (fwd_a),
        .fwd_b_o         (fwd_b)
    );

    alu_control alu_ctrl (
        .opcode_i   (IDEX_opcode),
        .ALUOp_i    (IDEX_alu_op_coarse),
        .funct3_i   (IDEX_funct3),
        .funct7_5_i (IDEX_funct7_5),
        .ALU_op_o   (alu_op_EX)
    );

    ALU alu (
        .input1_i   (alu_a_EX),
        .input2_i   (alu_b_EX),
        .ALU_op_i   (alu_op_EX),
        .result_o   (alu_result_EX),
        .zero_o     (zero_EX),
        .lt_o       (lt_EX),
        .ltu_o      (ltu_EX),
        .negative_o ()
    );

    memory #(.Depth(4096)) dmem (
        .clock_i      (clock),
        .address_i    (EXMEM_alu_result - DMEM_BASE),
        .write_data_i (EXMEM_rs2_data),
        .funct3_i     (EXMEM_funct3),
        .mem_write_i  (EXMEM_mem_write),
        .mem_read_i   (EXMEM_mem_read),
        .read_data_o  (mem_read_data_MEM)
    );



endmodule