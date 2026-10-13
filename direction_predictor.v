module direction_predictor #(parameter INDEX_BITS=8)(
    input clock,
    input resetn,

    input [31:0] pc,
    output prediction,

    input update_en,
    input [31:0] update_pc,
    input was_it_taken

);

    localparam TABLE_SIZE = 1<<INDEX_BITS;

    reg [1:0] prediction_table [0:TABLE_SIZE-1];

    wire [INDEX_BITS-1:0] index = pc[INDEX_BITS+1:2];
    wire [INDEX_BITS-1:0] update_index = update_pc[INDEX_BITS+1:2];
    integer i;
    always @(posedge clock or negedge resetn)begin
        if(!resetn)begin
            for(i=0; i<TABLE_SIZE; i=i+1) 
                prediction_table[i] <= 2'b01;
        end
        else if (update_en) begin
            if (was_it_taken&&(prediction_table[update_index]!=2'b11))
                prediction_table[update_index] <= prediction_table[update_index]+1;
            else if (!was_it_taken&&(prediction_table[update_index]!=2'b00))
                prediction_table[update_index] <= prediction_table[update_index]-1;
            end
        end


    assign prediction = prediction_table[index][1];



endmodule
/*wire        update_en     = id_ex_is_branch;      // only branches update the table
wire [31:0] update_pc     = id_ex_pc;
wire        actual_taken  = branch_taken;  // computed combinationally in EX, LOOK INTO THIS LATER!!! */

//This stores all PCs, I dont quite like that. I want to only store branches here. Needs fixing (what if we have a bigger program?). This will probably pass all the tests we have but still.
//BTB needs WORK.

//https://www.geeksforgeeks.org/computer-organization-architecture/correlating-branch-prediction/