module btb #(
    parameter INDEX_BITS = 8,
    parameter TAG_BITS  = 32 - INDEX_BITS
)(
    input clock,
    input resetn,
    input [31:0] pc,
    input update_en,
    input [31:0] update_pc,
    input [31:0] update_target,

    output hit,
    output [31:0] target

);

    localparam MEM_SIZE = 1<<INDEX_BITS;

    //Memory Registers
    reg valid [0:MEM_SIZE-1];
    reg [TAG_BITS-1:0] tag [0:MEM_SIZE-1];
    reg [31:0] targetmem [0:MEM_SIZE-1];

    //Hit Logic, Indexes/Tags
    wire [INDEX_BITS-1:0] read_index = pc[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0] read_tag = pc[31:INDEX_BITS+2];

    wire [INDEX_BITS-1:0] update_index = update_pc[INDEX_BITS+1:2];
    wire [TAG_BITS-1:0] update_tag = update_pc[31:INDEX_BITS+2];

    assign hit = valid[read_index]&&(tag[read_index]==read_tag);
    assign target = targetmem[read_index];

    //Reset and Update Logic
    integer i;

    always @(posedge clock or negedge resetn)begin
        if(!resetn)begin
            for(i=0; i<MEM_SIZE; i=i+1)begin
                valid[i]<=0;
            end
        end
        else if (update_en) begin
            valid[update_index] <= 1;
            tag[update_index] <= update_tag;
            targetmem[update_index] <= update_target;
        end
    end


endmodule

/*wire update_en_pht = id_ex_is_branch;              // PHT always learns direction, taken or not
wire update_en_btb = id_ex_is_branch && actual_taken;  // BTB only learns a target when actually taken*/
