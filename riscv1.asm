.text
.global _start

############################################################
# RISC-V Pipeline Verification Program
#
# Tests:
# 1. Basic ALU operations
# 2. EX->EX forwarding
# 3. Consecutive forwarding
# 4. Double forwarding
# 5. Load-use stall
# 6. Load with one-cycle gap (no stall)
# 7. Store forwarding
# 8. Branch not taken
# 9. Branch taken (flush)
# 10. JAL flush
# 11. x0 protection
#
# Every test ends with comparisons.
# If a comparison fails, execution jumps to FAIL_x.
############################################################

_start:

############################################################
# TEST 1 : BASIC ALU
############################################################

lui  x1 ,0x12345        # x1 = 0x12345000
lui  x2, 0x12345        # x2 = 0x12345000
bne  x1 ,x2, FAIL1      # idk how to test for lui

auipc x2 ,0             # x2 = PC of this instruction
auipc x3 ,0             # x3 = PC of this instruction
addi  x20,x2 ,4         # x20= PC of x2 + 4 = x3
bne   x3 ,x20,FAIL1     # x2 + 4 (should be) = x3

addi x1, x0, 1          # x1 = 1
add  x4 ,x0 ,4          # x4 = 4
addi x20,x0 ,4          # x20 = 4
bne  x4 ,x20,FAIL1

sub  x5 ,x4 ,x1          # x5 = 3
addi x20,x0 ,3          # x20 = 3
bne  x5 ,x20,FAIL1

# XOR / OR / AND and immediate forms #

xor  x6 ,x4 ,x5         # x6 = 7
addi x20,x0 ,7          # x20= 7
bne  x6 ,x20,FAIL1  

or   x7 ,x4 ,x5         # x7 = 7
addi x20,x0 ,7          # x20= 7
bne  x7 ,x20,FAIL1

and  x8 ,x4 ,x5         # x8 = 0
bne  x8 ,x0,FAIL1

xori x9 ,x4 ,3          # x9 = 7
addi x20,x0 ,7          # x20= 7
bne  x9 ,x20,FAIL1

ori  x10,x4 ,3          # x10= 7
addi x20,x0 ,7          # x20= 7
bne  x10,x20,FAIL1

andi x11,x4 ,3         # x11= 0
bne  x11,x0,FAIL1

# SLL / SRL / SRA and immediate forms #

addi x6, x0, 1
addi x7, x0, 3
sll  x1 ,x6 ,x7         # x1 = 1<<3 = 8
addi x20,x0 ,8          # x20= 8
bne  x1 ,x20,FAIL1

slli x2,x6 ,3           # x2 = 1<<3 = 8
bne  x2,x20,FAIL1

srl  x3 ,x20,x7         # x3 = 8>>3 = 1
addi x20,x0 ,1          # x20= 1
bne  x3 ,x20,FAIL1

srli x4 ,x2 ,3          # x4 = 8>>3 = 1
addi x20,x0 ,1          # x20= 1
bne  x4 ,x20,FAIL1

addi x1 ,x0,-16         # x1 = -16
addi x2 ,x0,4           # x2 = 4
sra  x5 ,x1,x2          # x5 = -16 >>> 4 = -1
addi x20,x0,-1          # x20 = -1
bne  x3 ,x4,FAIL1

srai x6 ,x1,2           # -16 >>> 2 = -4
addi x20,x0,-4          # x20 = -4
bne  x3 ,x4,FAIL1

# SLT / SLTU and immediate forms #

addi x1, x0, -1
addi x2, x0, 1

slt  x3 ,x1 ,x2         # x3 = 1 (signed: -1 < 1)
addi x20,x0 ,1          # x20 = 1
bne  x3 ,x20,FAIL1

sltu x4 ,x1 ,x2         # x4 = 0 (unsigned: 0xffffffff < 1)
addi x20,x0 ,0          # x20 = 0
bne  x4 ,x20,FAIL1

slti x5 ,x1 ,1          # x5 = 1 (signed: -1 < 1)
addi x20,x0 ,1          # x20 = 1
bne  x5 ,x20,FAIL1

sltiu x6, x1, 1         # x6 = 0 (unsigned: 0xffffffff < 1)
addi  x20, x0, 0        # x20 = 0
bne   x6, x20, FAIL1

# BEQ / BNE / BLTU / BGEU #

addi x1, x0, -1
addi x2, x0, -1
addi x3, x0, 1

beq  x1, x3, FAIL1
bne  x1, x2, FAIL1

addi x1, x0, -1
addi x2, x0, 1

bltu x1, x3, FAIL1
bgeu x3, x1, FAIL9

# JAL

addi x1, x0, 0
addi x2, x0, 0
jal  x10, T10_TARGET
addi x2, x0, 99               # must be skipped
T10_TARGET:
bne  x2, x0, FAIL1           # x2 should still be 0

# SB, SH, SW, LB, LH, LW, LBU, LHU
la x10, data

# Store full word and load it back.
lui  x1, 0x12345
addi x1, x1, 0x678            # x1 = 0x12345678
sw   x1, 0(x10)
lw   x2, 0(x10)
bne  x1, x2, FAIL1

# Test sign-extending LB and zero-extending LBU.
addi x1, x0, -128             # low byte = 0x80
sb   x1, 4(x10)
lb   x2, 4(x10)
addi x20, x0, -128
bne  x2, x20, FAIL1

lbu  x2, 4(x10)
addi x20, x0, 128
bne  x2, x20, FAIL1

# Store halfword 0x8001, test sign-extending LH and zero-extending LHU.
lui  x1, 0x00008
addi x1, x1, 1                # x1 = 0x00008001
sh   x1, 8(x10)

lh   x2, 8(x10)               # expected 0xffff8001
lui  x3, 0xffff8
addi x3, x3, 1
bne  x2, x3, FAIL1

lhu  x2, 8(x10)               # expected 0x00008001
lui  x3, 0x00008
addi x3, x3, 1
bne  x2, x3, FAIL1

############################################################
# TEST 2 : EX -> EX FORWARDING
############################################################

addi x1,x0,5    # x1 = 5
addi x2,x0,7    # x2 = 7

add x3,x1,x2    # x3 = 12
add x4,x3,x1    # x4 = 17
add x5,x4,x2    # x5 = 24
add x6,x5,x3    # x6 = 36

addi x20,x0,36  # x6 = 36
bne x6,x20,FAIL2

############################################################
# TEST 3 : CHAIN FORWARDING
############################################################

addi x1,x0,1    # x1 = 1

addi x1,x1,1    # x1 = 2
addi x1,x1,1    # x1 = 3
addi x1,x1,1    # x1 = 4
addi x1,x1,1    # x1 = 5
addi x1,x1,1    # x1 = 6
addi x1,x1,1    # x1 = 7
addi x1,x1,1    # x1 = 8

addi x20,x0,8   # x20 = 8
bne x1,x20,FAIL3

############################################################
# TEST 4 : DOUBLE FORWARDING
############################################################

addi x1,x0,5    # x1 = 5
addi x2,x0,10   # x2 = 10

add x3,x1,x2    # x3 = 15
add x4,x1,x2    # x4 = 15
add x5,x3,x4    # x5 = 30

addi x20,x0,30  # x20 = 30
bne x5,x20,FAIL4

############################################################
# TEST 5 : LOAD-USE STALL
############################################################

la x10,data     # x10 = pointer to value 20

addi x1, x0, 20
sw x1, 0(x10)
lw x1,0(x10)    # x1 = 20
add x2,x1,x1    # x2 = 40

addi x20,x0,40  # x20 = 40
bne x2,x20,FAIL5

############################################################
# TEST 6 : LOAD WITH GAP
############################################################

lw x1,0(x10)    # x1 = 20

addi x0,x0,0    # x0 = 0 (ALWAYS)

add x2,x1,x1    # x2 = 40

addi x20,x0,40  # x20 = 40
bne x2,x20,FAIL6

############################################################
# TEST 7 : STORE FORWARDING
############################################################

addi x1,x0,123  # x1 = 123

sw x1,4(x10)    # x10 now holds ptr to 123 instead of 20
lw x2,4(x10)    # x2 = 123

addi x20,x0,123 # x20 = 123
bne x2,x20,FAIL7

############################################################
# TEST 8 : BRANCH NOT TAKEN
############################################################

addi x1,x0,5    # x1 = 5
addi x2,x0,6    # x2 = 6

beq x1,x2,NOT_TAKEN

addi x3,x0,55   # x3 = 55

NOT_TAKEN:

addi x20,x0,55  # x20 = 55
bne x3,x20,FAIL8

############################################################
# TEST 9 : BRANCH TAKEN + FLUSH
############################################################

addi x1,x0,7    # x1 = 7
addi x2,x0,7    # x2 = 7

beq x1,x2,BRANCH_TARGET

addi x3,x0,111  # x3 = 111
addi x4,x0,222  # x4 = 222

BRANCH_TARGET:

addi x5,x0,77   # x5 = 77

addi x20,x0,77  # x20 = 77
bne x5,x20,FAIL9

############################################################
# TEST 10 : JAL FLUSH
############################################################

jal x0,JUMP_TARGET

addi x6,x0,11   # x6 = 11
addi x7,x0,22   # x7 = 22

JUMP_TARGET:

addi x8,x0,33   # x8 = 33

addi x20,x0,33  # x20 = 33
bne x8,x20,FAIL10

############################################################
# TEST 11 : x0 SHOULD NEVER CHANGE
############################################################

addi x0,x0,100

addi x1,x0,3
add  x2,x0,x1

addi x20,x0,3
bne x2,x20,FAIL11

############################################################
# ALL TESTS PASSED
############################################################

PASS:

addi x31,x0,31  # PASS FLAG

PASS_LOOP:
j PASS_LOOP


############################################################
# FAILURE LOOPS
############################################################

FAIL1:
addi x31,x0,1
j FAIL1

FAIL2:
addi x31,x0,2
j FAIL2

FAIL3:
addi x31,x0,3
j FAIL3

FAIL4:
addi x31,x0,4
j FAIL4

FAIL5:
addi x31,x0,5
j FAIL5

FAIL6:
addi x31,x0,6
j FAIL6

FAIL7:
addi x31,x0,7
j FAIL7

FAIL8:
addi x31,x0,8
j FAIL8

FAIL9:
addi x31,x0,9
j FAIL9

FAIL10:
addi x31,x0,10
j FAIL10

FAIL11:
addi x31,x0,11
j FAIL11

############################################################
# DATA
############################################################

.data
.align 4

data:
.word 20
.word 0