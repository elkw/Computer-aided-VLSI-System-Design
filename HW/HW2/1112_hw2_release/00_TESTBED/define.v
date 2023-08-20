// opcode definition
`define OP_ADD  0
`define OP_SUB  1
`define OP_ADDU 2
`define OP_SUBU 3
`define OP_ADDI 4
`define OP_LW   5
`define OP_SW   6
`define OP_AND  7
`define OP_OR   8
`define OP_XOR  9
`define OP_BEQ  10
`define OP_BNE  11
`define OP_SLT  12
`define OP_SLL  13
`define OP_SRL  14
`define OP_BLT  15
`define OP_BGE  16
`define OP_BLTU 17
`define OP_BGEU 18
`define OP_EOF  19

// MIPS status definition
`define R_TYPE_SUCCESS 0
`define I_TYPE_SUCCESS 1
`define MIPS_OVERFLOW 2
`define MIPS_END 3
