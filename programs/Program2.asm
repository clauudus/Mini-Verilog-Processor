; Adds 3 five times -> result = 15

        LDI R1, 3      ; value to add
        LDI R2, 0      ; acumulator
        LDI R3, 5      ; compt

loop:
        ADD R2, R2, R1 ; R2 = R2 + R1
        SUB R3, R3, R4 ; R4 = 0 (assumim R4=0 inicialment)
        LDI R4, 1
        SUB R3, R3, R4 ; decrement R3

        JMP check

check:
        ; Since we don't have a compare loop,
        ; we do manually the loop
        JMP loop

        ST R2, 0x20    ; Save result a mem[0x20]
        HALT
