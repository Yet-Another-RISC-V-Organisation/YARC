module predictor #(parameter SIZE=16)(
    input [31:0] instruction,
    input was_it_taken, //feedback...
    output reg prediction
);

    reg [SIZE-1:0] cache [33:0];
    integer i;



    always @(instruction) begin
        for(i=0; i<SIZE; i=i+1) begin //this is bs, it's linear, I'm just putting this here to add it to tb and stuff later..
            if(cache[i]==instruction) 
                prediction = (cache[i][1:0]>1)?1:0;
        end
    end





endmodule