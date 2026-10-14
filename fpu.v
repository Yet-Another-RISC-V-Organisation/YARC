`timescale 1ns / 1ps

module fpu (
    input  [31:0] input1,
    input  [31:0] input2,
    input  [31:0] input3,
    input  [4:0]  fpu_op,
    input  [2:0]  funct3,
    output reg [31:0] result,
    output reg        invalid
);

    // funct5 encodings
    localparam F5_FADD      = 5'b00000;
    localparam F5_FSUB      = 5'b00001;
    localparam F5_FMUL      = 5'b00010;
    localparam F5_FCVT_W_S  = 5'b11000;
    localparam F5_FCVT_S_W  = 5'b11010;
    localparam F5_FMV_X_W   = 5'b11100;
    localparam F5_FMV_W_X   = 5'b11110;
    localparam CANONICAL_NAN = 32'h7FC00000;

    // fpadder instance
    wire [31:0] adder_result;
    wire        adder_invalid;
    wire        is_sub = (fpu_op == F5_FSUB);

    fpadder adder (
        .input1  (input1),
        .input2  (input2),
        .is_sub  (is_sub),
        .result  (adder_result),
        .invalid (adder_invalid)
    );

    // fpmul instance
    wire [31:0] mul_result;
    wire        mul_invalid;

    fpmul multiplier (
        .input1  (input1),
        .input2  (input2),
        .result  (mul_result),
        .invalid (mul_invalid)
    );

    
    // fcvt, fmv
    wire        sign1       = input1[31];
    wire [7:0]  exp1        = input1[30:23];
    wire [22:0] mant1       = input1[22:0];

    wire is_nan1    = (exp1 == 8'hFF) && (mant1 != 23'b0);
    wire is_inf1    = (exp1 == 8'hFF) && (mant1 == 23'b0);
    wire is_zero1   = (exp1 == 8'h00) && (mant1 == 23'b0);
    wire is_denorm1 = (exp1 == 8'h00) && (mant1 != 23'b0);

    // FCVT.W.S / FCVT.WU.S: float -> 32-bit integer, truncate toward zero.
    // A normal float represents {1, mantissa} * 2^(exp1 - 150).
    // Values with exp1 < 127 have magnitude < 1 and truncate to zero.
    wire [31:0] cvt_float_sig32 = {8'b0, 1'b1, mant1};
    wire [31:0] cvt_w_magnitude =
        (exp1 < 8'd127) ? 32'd0 :
        (exp1 < 8'd150) ? (cvt_float_sig32 >> (8'd150 - exp1)) :
                            (cvt_float_sig32 << (exp1 - 8'd150));

    reg [31:0] fcvt_w_result;
    reg        fcvt_w_invalid;
    always @(*) begin
        fcvt_w_result  = 32'd0;
        fcvt_w_invalid = 1'b0;

        if (is_nan1) begin
            // RISC-V saturation rule for NaN.
            fcvt_w_result  = (funct3 == 3'b000) ? 32'h7FFFFFFF : 32'hFFFFFFFF;
            fcvt_w_invalid = 1'b1;
        end else if (is_inf1) begin
            fcvt_w_result  = sign1 ? ((funct3 == 3'b000) ? 32'h80000000 : 32'd0)
                                   : ((funct3 == 3'b000) ? 32'h7FFFFFFF : 32'hFFFFFFFF);
            fcvt_w_invalid = 1'b1;
        end else if (funct3 == 3'b000) begin
            // Signed range: -2^31 through 2^31-1.
            // -2^31 is exactly representable and is not an invalid conversion.
            if ((exp1 >= 8'd158) &&
                !(sign1 && exp1 == 8'd158 && mant1 == 23'd0)) begin
                fcvt_w_result  = sign1 ? 32'h80000000 : 32'h7FFFFFFF;
                fcvt_w_invalid = 1'b1;
            end else begin
                fcvt_w_result = sign1 ? (~cvt_w_magnitude + 32'd1) : cvt_w_magnitude;
            end
        end else begin
            // Unsigned range: 0 through 2^32-1.
            if (sign1 && exp1 >= 8'd127) begin
                fcvt_w_result  = 32'd0;
                fcvt_w_invalid = 1'b1;
            end else if (exp1 >= 8'd159) begin
                fcvt_w_result  = 32'hFFFFFFFF;
                fcvt_w_invalid = 1'b1;
            end else begin
                fcvt_w_result = cvt_w_magnitude;
            end
        end
    end

    // fcvt.s.w
    wire        int_negative = input1[31] && (funct3 == 3'b000);
    wire [31:0] int_abs      = int_negative ? (~input1 + 1) : input1;

    reg [4:0] leading_one;
    always @(*) begin
        casez (int_abs)
            32'b1???????????????????????????????: leading_one = 5'd31;
            32'b01??????????????????????????????: leading_one = 5'd30;
            32'b001?????????????????????????????: leading_one = 5'd29;
            32'b0001????????????????????????????: leading_one = 5'd28;
            32'b00001???????????????????????????: leading_one = 5'd27;
            32'b000001??????????????????????????: leading_one = 5'd26;
            32'b0000001?????????????????????????: leading_one = 5'd25;
            32'b00000001????????????????????????: leading_one = 5'd24;
            32'b000000001???????????????????????: leading_one = 5'd23;
            32'b0000000001??????????????????????: leading_one = 5'd22;
            32'b00000000001?????????????????????: leading_one = 5'd21;
            32'b000000000001????????????????????: leading_one = 5'd20;
            32'b0000000000001???????????????????: leading_one = 5'd19;
            32'b00000000000001??????????????????: leading_one = 5'd18;
            32'b000000000000001?????????????????: leading_one = 5'd17;
            32'b0000000000000001????????????????: leading_one = 5'd16;
            32'b00000000000000001???????????????: leading_one = 5'd15;
            32'b000000000000000001??????????????: leading_one = 5'd14;
            32'b0000000000000000001?????????????: leading_one = 5'd13;
            32'b00000000000000000001????????????: leading_one = 5'd12;
            32'b000000000000000000001???????????: leading_one = 5'd11;
            32'b0000000000000000000001??????????: leading_one = 5'd10;
            32'b00000000000000000000001?????????: leading_one = 5'd9;
            32'b000000000000000000000001????????: leading_one = 5'd8;
            32'b0000000000000000000000001???????: leading_one = 5'd7;
            32'b00000000000000000000000001??????: leading_one = 5'd6;
            32'b000000000000000000000000001?????: leading_one = 5'd5;
            32'b0000000000000000000000000001????: leading_one = 5'd4;
            32'b00000000000000000000000000001???: leading_one = 5'd3;
            32'b000000000000000000000000000001??: leading_one = 5'd2;
            32'b0000000000000000000000000000001?: leading_one = 5'd1;
            32'b00000000000000000000000000000001: leading_one = 5'd0;
            default:                              leading_one = 5'd0;
        endcase
    end

    // FCVT.S.W / FCVT.S.WU: integer -> binary32 (round to nearest, ties even).
    // The leading 1 goes at bit 23. Any shifted-out bits are rounded, not dropped.
    wire [4:0]  cvt_right_shift = (leading_one > 5'd23) ? (leading_one - 5'd23) : 5'd0;
    wire [31:0] cvt_aligned_int = (leading_one > 5'd23)
        ? (int_abs >> cvt_right_shift)
        : (int_abs << (5'd23 - leading_one));
    wire [23:0] cvt_sig24 = cvt_aligned_int[23:0];

    wire cvt_guard = (cvt_right_shift != 5'd0) &&
        ((int_abs & (32'd1 << (cvt_right_shift - 5'd1))) != 32'd0);
    wire cvt_sticky = (cvt_right_shift > 5'd1) &&
        ((int_abs & ((32'd1 << (cvt_right_shift - 5'd1)) - 32'd1)) != 32'd0);
    wire cvt_round_up = cvt_guard && (cvt_sticky || cvt_sig24[0]);
    wire [24:0] cvt_rounded_sig = {1'b0, cvt_sig24} + {24'b0, cvt_round_up};

    // The carry means 1.111... rounded to 10.000... => increase exponent.
    wire [7:0] cvt_float_exp = 8'd127 + {3'b0, leading_one}
                                    + {7'b0, cvt_rounded_sig[24]};
    wire [31:0] fcvt_s_w_result = (int_abs == 32'd0)
        ? 32'd0 : {int_negative, cvt_float_exp, cvt_rounded_sig[22:0]};

    // Actull result selector
    always @(*) begin
        invalid = 1'b0;
        result  = 32'b0;

        case (fpu_op)
            F5_FADD: begin
                result  = adder_result;
                invalid = adder_invalid;
            end
            F5_FSUB: begin
                result  = adder_result;  // fpadder handles is_sub internally
                invalid = adder_invalid;
            end
            F5_FMUL: begin
                result  = mul_result;
                invalid = mul_invalid;
            end
            F5_FMV_X_W: begin
                result  = input1;
                invalid = 1'b0;
            end
            F5_FMV_W_X: begin
                result  = input1;
                invalid = 1'b0;
            end
            F5_FCVT_W_S: begin
                result  = fcvt_w_result;
                invalid = fcvt_w_invalid;
            end
            F5_FCVT_S_W: begin
                result  = fcvt_s_w_result;
                invalid = 1'b0;
            end
            default: begin
                result  = 32'b0;
                invalid = 1'b0;
            end
        endcase
    end

endmodule