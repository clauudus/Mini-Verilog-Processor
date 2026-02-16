# Design Description

- Data bandwidth: 8 bits.
- Instruction bandwidth: 16 bits.
- 8 general registers (R0..R7), each one of 8 bits.
- Program Counter (PC) indexes words of 16 bits.

## Conceptual Format of the Instructions:
### R-type: (arithmetic, logic, between two registers)
    - [15:12] opcode
    - [11:9] rd
    - [8:6] rs1
    - [5:3] rs2
    - [2:0] so far unused, usefull to expand the project at some point

### I-type: (register with inmediate value)
    The instruction ocupies 2 words: first of all the instruction withs its opcode and register, the second one the 8-bit inmediate value.

### Opcodes:
    - 0x0: NOP
    - 0x1: ADD Rdest, Rsrc1, Rsrc2
    - 0x2: SUB Rdest, Rsrc1, Rsrc2
    - 0x3: AND Rdest, Rsrc1, Rsrc2
    - 0x4: OR Rdest, Rsrc1, Rsrc2
    - 0x5: LDI Rdest, imm8 (instruction + word imm8)
    - 0x6: LD Rdest, addr8 (instruction + word addr8)
    - 0x7: ST Rsrc, addr8 (instruction + word addr8)
    - 0x8: JMP addr8 (instrucció + paraula addr8)
    - 0x9: JNZ Rsrc, addr8 (comparasion from a register to 0, if not zero, jump to address)
    - 0xF: HALT
