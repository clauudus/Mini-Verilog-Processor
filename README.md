# Mini-Verilog-Processor

## Description of the Repository:
Minimal 8-bit CPU designed and implemented in Verilog, featuring a custom ISA, register file, ALU, instruction/data memory and testbench simulation. Educational project focused to understand more deeply computer architecture and digital design.

## Directories Description:
  - _src:_ <br/>
Contains all description of the processor written in Verilog.

  - _tb:_ <br/>
Contains some testbench to make sure the mini-cpu is working.

  - _tools:_ <br/>
Contains a Python assembler file to make possible to write programs for the mini 8-bit CPU.

  - _programs_ <br/>
Contains programs that can be run with the processor

## Important Notes:
The current version of the processor is not working properly since I'm adding a new instruction (Jump if Not Zero). The main goal to implement this instruction is to be able to make problems with very simple loops such as a for or a while.
The CPU file doesn't work as well as the assembler.
