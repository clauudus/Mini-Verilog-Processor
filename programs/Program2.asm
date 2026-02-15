; Adds 3 five times -> result = 15

LDI R1, 3
LDI R2, 0

ADD R2, R2, R1
ADD R2, R2, R1
ADD R2, R2, R1
ADD R2, R2, R1
ADD R2, R2, R1

ST R2, 0x20
HALT

