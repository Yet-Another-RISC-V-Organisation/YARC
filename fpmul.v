`timescale 1ns / 1ps

module fpmul (
    input  [31:0] input1,
    input  [31:0] input2,
    output reg [31:0] result,
    output reg        invalid
);

    localparam CANONICAL_NAN = 32'h7FC00000;

    // Unpack
    wire        sign1  = input1[31];
    wire [7:0]  exp1   = input1[30:23];
    wire [22:0] mant1  = input1[22:0];
    wire        sign2  = input2[31];
    wire [7:0]  exp2   = input2[30:23];
    wire [22:0] mant2  = input2[22:0];

    // Special value detection
    wire is_nan1  = (exp1 == 8'hFF) && (mant1 != 23'b0);
    wire is_nan2  = (exp2 == 8'hFF) && (mant2 != 23'b0);
    wire is_inf1  = (exp1 == 8'hFF) && (mant1 == 23'b0);
    wire is_inf2  = (exp2 == 8'hFF) && (mant2 == 23'b0);
    wire is_zero1 = (exp1 == 8'h00) && (mant1 == 23'b0);
    wire is_zero2 = (exp2 == 8'h00) && (mant2 == 23'b0);

    wire any_nan     = is_nan1 || is_nan2;
    wire inf_x_zero  = (is_inf1 && is_zero2) || (is_inf2 && is_zero1);
    wire result_sign = sign1 ^ sign2;

    // Significand multiply 
    wire [23:0] sig1 = {(exp1 != 8'h00), mant1};
    wire [23:0] sig2 = {(exp2 != 8'h00), mant2};

    wire [47:0] product = sig1 * sig2;

    // Exponent add
    wire [9:0] exp_sum = {2'b00, exp1} + {2'b00, exp2} - 10'd127;

    // Normalize: leading 1 at bit 47 -> shift right 1, exp+1; bit 46 -> already normalized
    // norm_sig: [26]=hidden, [25:3]=mantissa, [2:0]=GRS
    wire prod_carry = product[47];

    wire [26:0] norm_sig = prod_carry ? product[47:21] : product[46:20];
    wire [9:0]  norm_exp = prod_carry ? (exp_sum + 10'd1) : exp_sum;

    wire sticky = prod_carry ? |product[20:0] : |product[19:0];

    // Round to nearest even
    wire guard_bit  = norm_sig[2];
    wire round_bit  = norm_sig[1];
    wire sticky_bit = norm_sig[0] | sticky;
    wire lsb        = norm_sig[3];

    wire round_up = guard_bit && (round_bit || sticky_bit || lsb);

    wire [23:0] rounded_mant = {1'b0, norm_sig[25:3]} + {23'b0, round_up};
    wire        round_carry  = rounded_mant[23];

    wire [22:0] final_mant = rounded_mant[22:0];
    wire [9:0]  final_exp  = round_carry ? (norm_exp + 10'd1) : norm_exp;

    wire exp_overflow  = (final_exp >= 10'd255);
    wire exp_underflow = final_exp[9];

    always @(*) begin
        invalid = 1'b0;
        if      (any_nan || inf_x_zero)  begin result = CANONICAL_NAN;              invalid = 1'b1; end
        else if (is_inf1 || is_inf2)           result = {result_sign, 8'hFF, 23'b0};
        else if (is_zero1 || is_zero2)         result = {result_sign, 31'b0};
        else if (exp_overflow)                 result = {result_sign, 8'hFF, 23'b0};
        else if (exp_underflow)                result = {result_sign, 31'b0};
        else                                   result = {result_sign, final_exp[7:0], final_mant};
    end

endmodule