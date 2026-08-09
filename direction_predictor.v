module direction_predictor #(parameter INDEX_BITS=8)(
    input clock,
    input resetn,

    input [31:0] pc,
    output prediction

);

    localparam TABLE_SIZE = 1<<INDEX_BITS;

    reg [1:0] prediction_table [0:TABLE_SIZE-1];

    wire [INDEX_BITS-1:0] index = pc[INDEX_BITS+1:2];

    integer i;
    always @(posedge clock or negedge resetn)begin
        if(!resetn)begin
            for(i=0; i<TABLE_SIZE; i=i+1) 
                prediction_table[i] <= 2'b01;
        end
    end

    assign prediction = prediction_table[index][1];


endmodule
/*wire        update_en     = id_ex_is_branch;      // only branches update the table
wire [31:0] update_pc     = id_ex_pc;
wire        actual_taken  = branch_condition_result;  // computed combinationally in EX, LOOK INTO THIS LATER!!! */