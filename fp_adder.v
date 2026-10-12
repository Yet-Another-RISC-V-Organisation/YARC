`timescale 1ns / 1ps

module fpadder (
    input  [31:0] input1,
    input  [31:0] input2,
    input         is_sub,
    output reg [31:0] result,
    output reg        invalid
);

    localparam CANONICAL_NAN = 32'h7FC00000;
    localparam POS_ZERO      = 32'h00000000;
    localparam NEG_ZERO      = 32'h80000000;

    // Unpack
    wire        sign1     = input1[31];
    wire [7:0]  exp1      = input1[30:23];
    wire [22:0] mant1     = input1[22:0];
    wire        sign2_raw = input2[31];
    wire [7:0]  exp2      = input2[30:23];
    wire [22:0] mant2     = input2[22:0];

    wire sign2 = is_sub ? ~sign2_raw : sign2_raw;

    // Special value detection
    wire is_nan1   = (exp1 == 8'hFF) && (mant1 != 23'b0);
    wire is_nan2   = (exp2 == 8'hFF) && (mant2 != 23'b0);
    wire is_inf1   = (exp1 == 8'hFF) && (mant1 == 23'b0);
    wire is_inf2   = (exp2 == 8'hFF) && (mant2 == 23'b0);
    wire is_zero1  = (exp1 == 8'h00) && (mant1 == 23'b0);
    wire is_zero2  = (exp2 == 8'h00) && (mant2 == 23'b0);

    wire any_nan    = is_nan1 || is_nan2;
    wire both_inf   = is_inf1 && is_inf2;
    wire inf_cancel = both_inf && (sign1 != sign2);  // Inf - Inf -> NaN

    // Swap so exp_a >= exp_b
    wire swap   = (exp2 > exp1) || ((exp2 == exp1) && (mant2 > mant1));

    wire        sign_a = swap ? sign2  : sign1;
    wire        sign_b = swap ? sign1  : sign2;
    wire [7:0]  exp_a  = swap ? exp2   : exp1;
    wire [7:0]  exp_b  = swap ? exp1   : exp2;
    wire [22:0] mant_a = swap ? mant2  : mant1;
    wire [22:0] mant_b = swap ? mant1  : mant2;

    // Restore hidden bit; working significands are 27 bits: [26:3] significand, [2:0] GRS
    wire hidden_a = (exp_a != 8'h00);
    wire hidden_b = (exp_b != 8'h00);

    wire [26:0] sig_a      = {hidden_a, mant_a, 3'b000};
    wire [26:0] sig_b_full = {hidden_b, mant_b, 3'b000};

    wire [7:0] exp_diff = exp_a - exp_b;
    wire [4:0] shift_amt = (exp_diff > 8'd26) ? 5'd27 : exp_diff[4:0];

    wire [26:0] sig_b_shifted = sig_b_full >> shift_amt;

    // Sticky: OR of all bits shifted out past position 0
    wire sticky_raw = (exp_diff > 8'd26) ? |sig_b_full : |(sig_b_full << (7'd27 - {2'b00, shift_amt}));

    wire [26:0] sig_b_aligned = {sig_b_shifted[26:1], sig_b_shifted[0] | sticky_raw};

    // Effective subtract when signs differ
    wire eff_sub = (sign_a != sign_b);

    wire [27:0] add_result = eff_sub ? ({1'b0, sig_a} - {1'b0, sig_b_aligned})
                                     : ({1'b0, sig_a} + {1'b0, sig_b_aligned});

    wire result_sign = sign_a;
    wire carry_out   = add_result[27];

    // Leading zero count for post-subtract normalization
    reg [4:0] lz;
    always @(*) begin
        casez (add_result[26:0])
            27'b1??????????????????????????: lz = 5'd0;
            27'b01?????????????????????????: lz = 5'd1;
            27'b001????????????????????????: lz = 5'd2;
            27'b0001???????????????????????: lz = 5'd3;
            27'b00001??????????????????????: lz = 5'd4;
            27'b000001?????????????????????: lz = 5'd5;
            27'b0000001????????????????????: lz = 5'd6;
            27'b00000001???????????????????: lz = 5'd7;
            27'b000000001??????????????????: lz = 5'd8;
            27'b0000000001?????????????????: lz = 5'd9;
            27'b00000000001????????????????: lz = 5'd10;
            27'b000000000001???????????????: lz = 5'd11;
            27'b0000000000001??????????????: lz = 5'd12;
            27'b00000000000001?????????????: lz = 5'd13;
            27'b000000000000001????????????: lz = 5'd14;
            27'b0000000000000001???????????: lz = 5'd15;
            27'b00000000000000001??????????: lz = 5'd16;
            27'b000000000000000001?????????: lz = 5'd17;
            27'b0000000000000000001????????: lz = 5'd18;
            27'b00000000000000000001???????: lz = 5'd19;
            27'b000000000000000000001??????: lz = 5'd20;
            27'b0000000000000000000001?????: lz = 5'd21;
            27'b00000000000000000000001????: lz = 5'd22;
            27'b000000000000000000000001???: lz = 5'd23;
            27'b0000000000000000000000001??: lz = 5'd24;
            27'b00000000000000000000000001?: lz = 5'd25;
            27'b000000000000000000000000001: lz = 5'd26;
            default:                         lz = 5'd27;
        endcase
    end

    // Normalize: carry -> shift right 1; cancellation -> shift left by lz
    wire [26:0] norm_sig = carry_out ? add_result[27:1] : (add_result[26:0] << lz);
    wire [8:0]  norm_exp = carry_out ? ({1'b0, exp_a} + 9'd1)
                                     : ({1'b0, exp_a} - {4'b0, lz});

    // Round to nearest even
    // norm_sig: [26]=hidden, [25:3]=mantissa, [2]=G, [1]=R, [0]=S
    wire guard_bit  = norm_sig[2];
    wire round_bit  = norm_sig[1];
    wire sticky_bit = norm_sig[0];
    wire lsb        = norm_sig[3];

    wire round_up = guard_bit && (round_bit || sticky_bit || lsb);

    wire [23:0] rounded_mant = {1'b0, norm_sig[25:3]} + {23'b0, round_up};
    wire        round_carry  = rounded_mant[23];
    wire [22:0] final_mant   = rounded_mant[22:0];
    wire [8:0]  final_exp    = round_carry ? (norm_exp + 9'd1) : norm_exp;

    wire exp_overflow   = (final_exp >= 9'd255);
    wire is_result_zero = (lz == 5'd27) && !carry_out;

    always @(*) begin
        invalid = 1'b0;
        if (any_nan || inf_cancel) begin
            result  = CANONICAL_NAN;
            invalid = 1'b1;
        end
        else if (is_inf1)        result = {sign1, 8'hFF, 23'b0};
        else if (is_inf2)        result = {sign2, 8'hFF, 23'b0};
        else if (is_result_zero) result = (sign1 && sign2) ? NEG_ZERO : POS_ZERO;
        else if (exp_overflow)   result = {result_sign, 8'hFF, 23'b0};
        else                     result = {result_sign, final_exp[7:0], final_mant};
    end

endmodule