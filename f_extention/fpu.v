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

    // fcvt.w.s
    wire [7:0]  unbiased_exp   = exp1 - 8'd127;
    wire [47:0] significand48  = {1'b1, mant1, 24'b0};
    wire signed [8:0]  shift_amt = 9'd23 - {1'b0, unbiased_exp};
    wire [47:0] shifted_mant   = (shift_amt >= 0) ? (significand48 >> shift_amt)
                                                   : (significand48 << (-shift_amt));
    wire [31:0] fcvt_w_s_result  = sign1 ? (~shifted_mant[31:0] + 1) : shifted_mant[31:0];
    wire [31:0] fcvt_wu_s_result = shifted_mant[31:0];

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

    wire [7:0]  fcvt_s_w_exp  = (int_abs == 32'b0) ? 8'b0 : (8'd127 + leading_one);
    wire [31:0] int_shifted   = (leading_one >= 5'd23) ? (int_abs >> (leading_one - 5'd23))
                                                       : (int_abs << (5'd23 - leading_one));
    wire [22:0] fcvt_s_w_mant = int_shifted[22:0];

    wire [31:0] fcvt_s_w_result  = (int_abs == 32'b0) ? 32'h00000000
                                                       : {int_negative, fcvt_s_w_exp, fcvt_s_w_mant};
    wire [31:0] fcvt_s_wu_result = (int_abs == 32'b0) ? 32'h00000000
                                                       : {1'b0, fcvt_s_w_exp, fcvt_s_w_mant};

    // Top-level op select
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
                if (is_nan1 || is_inf1) begin
                    result  = is_nan1 ? 32'h7FFFFFFF : (sign1 ? 32'h80000000 : 32'h7FFFFFFF);
                    invalid = 1'b1;
                end else if (is_zero1 || is_denorm1) begin
                    result  = 32'b0;
                    invalid = 1'b0;
                end else begin
                    result  = (funct3 == 3'b000) ? fcvt_w_s_result : fcvt_wu_s_result;
                    invalid = 1'b0;
                end
            end
            F5_FCVT_S_W: begin
                result  = (funct3 == 3'b000) ? fcvt_s_w_result : fcvt_s_wu_result;
                invalid = 1'b0;
            end
            default: begin
                result  = 32'b0;
                invalid = 1'b0;
            end
        endcase
    end

endmodule