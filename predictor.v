module predictor #(parameter SIZE=16)(
    input [31:0] instruction, //Instruction input
    input was_it_taken, //Feedback input, arrives later, needs extensive testing
    input resetn, //Active low reset
    output reg prediction //Prediction output
);

    reg [33:0] cache [SIZE-1:0]; //first 2 bits -> prediction
    integer i;

    //REMINDER 00 -> Strongly Not Taken, ..., 11 -> Strongly Taken

    wire opcode = instruction[6:0];
    reg last_index = 0;
    reg last_branch = 0;


    always @(opcode or resetn) begin
        if(!resetn) begin
            for(i=0; i<SIZE; i=i+1)
            cache[i]=0;
        end
        else if(opcode==7'b1100011) begin //branch! 
            for(i=0; i<SIZE; i=i+1) begin
                if(cache[i]==instruction)begin
                    last_index = i;
                    last_branch = instruction;
                    prediction = cache[i][33];
                end
            end
            if(i==SIZE); //LRU goes heres
        end
    end

    always @(was_it_taken) begin
        if((last_branch==instruction)&& //makes sure that the instruction is still there, and it wasn't evicted
        (!((was_it_taken&&(cache[last_index][33:32]==2'b11))
        ||((!was_it_taken)&&(cache[last_index][33:32]==2'b00)))))
            cache[last_index][33:32] = cache[last_index][33:32] + ((was_it_taken)?(1):(-1));
    end





endmodule