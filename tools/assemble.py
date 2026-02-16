#!/usr/bin/env python3
"""
Completed assembler for the mini 8-bit CPU.

File to execute instructions with Icarius Verilog

Usage
-----
  python3 tools/assemble.py input.asm output.hex

Features: :)
---------------------------------
- Robust tokenization (handles extra spaces, tabs and commas).
- Clear error messages with line numbers.
- Label resolution (two-pass).
- Accepts decimal and 0x hex numbers; accepts negative immediates (converted to 8-bit two's complement).
- Range checking for immediates/addresses (0..255 after masking to 8-bit) and warnings for truncation.
- Case-insensitive mnemonics and registers (R0..R7).
- Outputs 16-bit hex words (one word per line) compatible with $readmemh used by imem.v.

Supported instructions
----------------------
NOP
ADD rd, rs1, rs2
SUB rd, rs1, rs2
AND rd, rs1, rs2
OR  rd, rs1, rs2
LDI rd, imm8
LD  rd, addr8
ST  rs, addr8
JMP addr8
JNZ rs, addr8
HALT

Labels: label:  (a label occupies the current word address; for I-type instructions the address increases accordingly)
Comments: start a comment with ";" or "#" on any line

"""
import sys
import re
from typing import List, Tuple

OPCODES = {
    'NOP': 0x0,
    'ADD': 0x1,
    'SUB': 0x2,
    'AND': 0x3,
    'OR':  0x4,
    'LDI': 0x5,
    'LD':  0x6,
    'ST':  0x7,
    'JMP': 0x8,
    'JNZ': 0x9,
    'HALT':0xF,
}

REG_RE = re.compile(r'^R([0-7])$', re.IGNORECASE)

def parse_number(tok: str, lineno: int) -> int:
    tok = tok.strip()
    if tok.lower().startswith('0x'):
        try:
            return int(tok, 16)
        except ValueError:
            raise SyntaxError(f"Line {lineno}: invalid hex number '{tok}'")
    else:
        try:
            return int(tok, 10)
        except ValueError:
            raise SyntaxError(f"Line {lineno}: invalid decimal number '{tok}'")


def tokenize_line(line: str) -> Tuple[str, List[str]]:
    # remove comments
    code = re.split(r'[;#]', line)[0]
    code = code.strip()
    if not code:
        return ('EMPTY', [])
    # label
    if code.endswith(':'):
        return ('LABEL', [code[:-1].strip()])
    # split by whitespace or commas
    parts = re.split(r'[\s,]+', code)
    parts = [p for p in parts if p!='']
    return ('INST', parts)


def assemble_lines(lines: List[str]) -> List[int]:
    # First pass: determine label addresses
    labels = {}
    pc = 0
    parsed = []  # tuples (lineno, kind, tokens)
    for i, raw in enumerate(lines, start=1):
        kind, parts = tokenize_line(raw)
        parsed.append((i, kind, parts))
        if kind == 'EMPTY':
            continue
        if kind == 'LABEL':
            lbl = parts[0]
            if lbl in labels:
                raise SyntaxError(f"Line {i}: duplicate label '{lbl}'")
            labels[lbl] = pc
        else:
            mnemonic = parts[0].upper()
            if mnemonic in ('LDI','LD','ST','JMP','JNZ'):
                pc += 2
            else:
                pc += 1

    # Second pass: emit words
    out_words = []
    pc = 0
    for lineno, kind, parts in parsed:
        if kind == 'EMPTY' or kind == 'LABEL':
            continue
        mnemonic = parts[0].upper()
        try:
            if mnemonic == 'NOP':
                instr = (OPCODES['NOP'] << 12)
                out_words.append(instr)
                pc += 1

            elif mnemonic in ('ADD','SUB','AND','OR'):
                if len(parts) != 4:
                    raise SyntaxError(f"Line {lineno}: {mnemonic} requires 3 operands (rd, rs1, rs2)")
                m = REG_RE.match(parts[1])
                if not m:
                    raise SyntaxError(f"Line {lineno}: invalid destination register '{parts[1]}'")
                rd = int(m.group(1))
                m = REG_RE.match(parts[2])
                if not m:
                    raise SyntaxError(f"Line {lineno}: invalid source register '{parts[2]}'")
                rs1 = int(m.group(1))
                m = REG_RE.match(parts[3])
                if not m:
                    raise SyntaxError(f"Line {lineno}: invalid source register '{parts[3]}'")
                rs2 = int(m.group(1))
                instr = (OPCODES[mnemonic] << 12) | (rd << 9) | (rs1 << 6) | (rs2 << 3)
                out_words.append(instr)
                pc += 1

            elif mnemonic == 'LDI':
                if len(parts) != 3:
                    raise SyntaxError(f"Line {lineno}: LDI requires 2 operands (rd, imm)")
                m = REG_RE.match(parts[1])
                if not m:
                    raise SyntaxError(f"Line {lineno}: invalid destination register '{parts[1]}'")
                rd = int(m.group(1))
                imm_tok = parts[2]
                if imm_tok in labels:
                    imm = labels[imm_tok]
                else:
                    imm = parse_number(imm_tok, lineno)
                imm8 = imm & 0xFF
                if imm != imm8:
                    print(f"Warning: line {lineno}: immediate {imm} truncated to 8 bits -> {imm8}")
                instr = (OPCODES['LDI'] << 12) | (rd << 9)
                out_words.append(instr)
                out_words.append(imm8)
                pc += 2

            elif mnemonic == 'LD':
                if len(parts) != 3:
                    raise SyntaxError(f"Line {lineno}: LD requires 2 operands (rd, addr)")
                m = REG_RE.match(parts[1])
                if not m:
                    raise SyntaxError(f"Line {lineno}: invalid destination register '{parts[1]}'")
                rd = int(m.group(1))
                addr_tok = parts[2]
                if addr_tok in labels:
                    addr = labels[addr_tok]
                else:
                    addr = parse_number(addr_tok, lineno)
                addr8 = addr & 0xFF
                if addr != addr8:
                    print(f"Warning: line {lineno}: address {addr} truncated to 8 bits -> {addr8}")
                instr = (OPCODES['LD'] << 12) | (rd << 9)
                out_words.append(instr)
                out_words.append(addr8)
                pc += 2

            elif mnemonic == 'ST':
                if len(parts) != 3:
                    raise SyntaxError(f"Line {lineno}: ST requires 2 operands (rs, addr)")
                m = REG_RE.match(parts[1])
                if not m:
                    raise SyntaxError(f"Line {lineno}: invalid source register '{parts[1]}'")
                rs = int(m.group(1))
                addr_tok = parts[2]
                if addr_tok in labels:
                    addr = labels[addr_tok]
                else:
                    addr = parse_number(addr_tok, lineno)
                addr8 = addr & 0xFF
                if addr != addr8:
                    print(f"Warning: line {lineno}: address {addr} truncated to 8 bits -> {addr8}")
                instr = (OPCODES['ST'] << 12) | (rs << 6)
                out_words.append(instr)
                out_words.append(addr8)
                pc += 2

            elif mnemonic == 'JMP':
                if len(parts) != 2:
                    raise SyntaxError(f"Line {lineno}: JMP requires 1 operand (addr)")
                addr_tok = parts[1]
                if addr_tok in labels:
                    addr = labels[addr_tok]
                else:
                    addr = parse_number(addr_tok, lineno)
                addr8 = addr & 0xFF
                if addr != addr8:
                    print(f"Warning: line {lineno}: jump address {addr} truncated to 8 bits -> {addr8}")
                instr = (OPCODES['JMP'] << 12)
                out_words.append(instr)
                out_words.append(addr8)
                pc += 2

            elif mnemonic == 'JNZ':
              if len(parts) != 3:
                raise SyntaxError(f"Line {lineno}: JNZ requires 2 operands (reg, addr)")
                  m = REG_RE.match(parts[1])
                if not m:
                    raise SyntaxError(f"Line {lineno}: invalid register '{parts[1]}'")
                reg = int(m.group(1))
                # emit instruction word: opcode + reg in rd field
                instr = (OPCODES['JNZ'] << 12) | (reg << 9)
                out_words.append(instr & 0xFFFF)
                # resolve address (label or numeric) -> one byte
                addr_tok = parts[2]
                if addr_tok in labels:
                    addr = labels[addr_tok]
                else:
                    addr = parse_number(addr_tok, lineno)
                out_words.append(addr & 0xFF)
                pc += 2  # note: we've emitted two words? depends on your "words" convention

            elif mnemonic == 'HALT':
                instr = (OPCODES['HALT'] << 12)
                out_words.append(instr)
                pc += 1

            else:
                raise SyntaxError(f"Line {lineno}: unknown mnemonic '{mnemonic}'")

        except SyntaxError:
            # re-raise with lineno info (already included)
            raise

    return out_words


def assemble_file(infile: str, outfile: str) -> None:
    with open(infile, 'r') as f:
        lines = f.readlines()
    words = assemble_lines(lines)
    with open(outfile, 'w') as outf:
        for w in words:
            outf.write(f"{w:04X}\n")
    print(f"Wrote {len(words)} words to {outfile}")


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: assemble.py input.asm output.hex")
        sys.exit(1)
    assemble_file(sys.argv[1], sys.argv[2])


