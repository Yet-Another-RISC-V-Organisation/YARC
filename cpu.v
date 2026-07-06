`timescale 1ns / 1ps

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
        .clock          (clock),
        .resetn         (resetn),
        .stall          (stall),
        .pc             (pc),
        .branch_address (next_pc),
        .branch_taken   (branch_taken)
    );

    memory #(.DEPTH(4096)) imem (
        .clock      (clock),
        .address    (pc - IMEM_BASE),
        .write_data (32'b0),
        .funct3     (3'b010),
        .mem_write  (1'b0),
        .mem_read   (1'b1),
        .read_data  (instr_IF)
    );

    immidiateGen ig (
        .instruction (IFID_instr),
        .immidiate   (imm_ID)
    );

    main_control_unit ctrl (
        .opcode    (opcode_ID),
        .instr     (IFID_instr[31:20]),
        .RegWrite  (reg_write_ID),
        .ALUSrc    (alu_src_ID),
        .ALUSrcA   (alu_src_a_ID),
        .MemRead   (mem_read_ID),
        .MemWrite  (mem_write_ID),
        .MemtoReg  (mem_to_reg_ID),
        .Branch    (branch_ID),
        .Jump      (jump_ID),
        .ALUOp     (alu_op_coarse_ID),
        .is_ecall  (is_ecall_ID),
        .is_ebreak (is_ebreak_ID),
        .is_fence  (is_fence_ID)
    );

    register_file rf (
        .clock      (clock),
        .resetn     (resetn),
        .read_addr1 (rs1_ID),
        .read_addr2 (rs2_ID),
        .write_addr (MEMWB_rd),
        .write_data (wb_data),
        .we         (MEMWB_reg_write),
        .read_data1 (rs1_data_ID),
        .read_data2 (rs2_data_ID)
    );

    hazard haz (
        .rs1_ID      (rs1_ID),
        .rs2_ID      (rs2_ID),
        .rd_EX       (IDEX_rd),
        .mem_read_EX (IDEX_mem_read),
        .stall       (stall)
    );

    forward fwd_unit (
        .rs1_EX        (IDEX_rs1),
        .rs2_EX        (IDEX_rs2),
        .rd_MEM        (EXMEM_rd),
        .reg_write_MEM (EXMEM_reg_write),
        .rd_WB         (MEMWB_rd),
        .reg_write_WB  (MEMWB_reg_write),
        .fwd_a         (fwd_a),
        .fwd_b         (fwd_b)
    );

    alu_control alu_ctrl (
        .opcode   (IDEX_opcode),
        .ALUOp    (IDEX_alu_op_coarse),
        .funct3   (IDEX_funct3),
        .funct7_5 (IDEX_funct7_5),
        .alu_op   (alu_op_EX)
    );

    ALU alu (
        .input1   (alu_a_EX),
        .input2   (alu_b_EX),
        .alu_op   (alu_op_EX),
        .result   (alu_result_EX),
        .zero     (zero_EX),
        .lt       (lt_EX),
        .ltu      (ltu_EX),
        .negative ()
    );

    memory #(.DEPTH(4096)) dmem (
        .clock      (clock),
        .address    (EXMEM_alu_result - DMEM_BASE),
        .write_data (EXMEM_rs2_data),
        .funct3     (EXMEM_funct3),
        .mem_write  (EXMEM_mem_write),
        .mem_read   (EXMEM_mem_read),
        .read_data  (mem_read_data_MEM)
    );



endmodule