start:
LDI R7, 0x00

; T1: zero should NOT jump
LDI R1, 0x00
JNZ R1, t1_fail_jump

; T2: one should jump
LDI R2, 0x01
JNZ R2, t2_taken
LDI R7, 0x22
JMP fail

t1_fail_jump:
LDI R7, 0x11
JMP fail

t2_taken:
; T3: 0xFF should jump
LDI R3, 0xFF
JNZ R3, t3_taken
LDI R7, 0x33
JMP fail

t3_taken:
; T4: R0 starts at 0, so should NOT jump
JNZ R0, t4_fail_jump

; T5: highest register index (R7) non-zero should jump
LDI R7, 0x7F
JNZ R7, pass
LDI R7, 0x55
JMP fail

t4_fail_jump:
LDI R7, 0x44
JMP fail

pass:
LDI R6, 0xA5
ST R6, 0xF0
LDI R6, 0x00
ST R6, 0xF1
HALT

fail:
LDI R6, 0xEE
ST R6, 0xF0
ST R7, 0xF1
HALT
