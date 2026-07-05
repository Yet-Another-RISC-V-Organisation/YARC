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


############################################################
# Sub Test 1: Register - Immediate
############################################################

addi  x1,x0,10  # x1 = 10
slti  x2,x0,-1  # x2 = 0    (0<-1) ?
sltiu x3,x0,-1  # x3 = 1    (0< 1) ?
ori   x4,x1,5   # x4 = 15
andi  x5,x1,5   # x5 = 0
xori  x6,x1,6   # x6 = 12


addi x20,x0,10  # x20 = 10
bne x1,x20,FAIL1

addi x20,x0,0  # x20 = 0
bne x2,x20,FAIL1

addi x20,x0,1   # x20 = 1
bne x3,x20,FAIL1

addi x20,x0,15  # x20 = 15
bne x4,x20,FAIL1

addi x20,x0,0   # x20 = 0
bne x5,x20,FAIL1

addi x20,x0,12  # x20 = 12
bne x6,x20,FAIL1

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