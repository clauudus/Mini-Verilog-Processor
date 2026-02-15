SHELL := /bin/bash
.PHONY: help all asm asm-all load sim sim-vcd compile lint clean

# --- Tools (in case we have to rewrite the command line) ---
PY ?= python3
IVERILOG ?= iverilog
VVP ?= vvp
VERILATOR ?= verilator
BUILD_DIR ?= build
WAVE_DIR ?= waves

# --- rutes / files ---
SRC_DIR := src
TB_DIR := tb
PROG_DIR := programs
ASSEMBLER := tools/assemble.py

SRC_FILES := $(wildcard $(SRC_DIR)/*.v) $(wildcard $(SRC_DIR)/*.sv)
TB_FILES := $(wildcard $(TB_DIR)/*.v) $(wildcard $(TB_DIR)/*.sv)
ASM_FILES := $(wildcard $(PROG_DIR)/*.asm)
BUILD_PROG_DIR := $(BUILD_DIR)/programs

# Default: build + simulate
all: sim

help:
	@echo "Makefile for Mini-Verilog-Processor"
	@echo ""
	@echo "Targets:"
	@echo "  make all         - assemble (si cal), compile and simulate (default)"
	@echo "  make asm         - assemble all .asm -> $(BUILD_PROG_DIR)/*.hex"
	@echo "  make asm FILE=programs/foo.asm"
	@echo "  make load FILE=programs/foo.asm   - assemble FILE -> $(PROG_DIR)/program.hex (imatge usada per imem.v)"
	@echo "  make compile     - compile src + tb with iverilog -> $(BUILD_DIR)/sim.vvp"
	@echo "  make sim         - compile (si cal) and execute the simulation (vvp)"
	@echo "  make sim-vcd     - execute simulation and move cpu.vcd to $(WAVE_DIR)/"
	@echo "  make lint        - run verilator --lint-only (if instaled)"
	@echo "  make clean       - clean, the one that is used normally on Makefiles
	@echo ""
	@echo "Variables which can be rewritten: PY, IVERILOG, VVP, VERILATOR, ASSEMBLER"

# -----------------------
# Assembler
# -----------------------
# assembles all .asm in programs -> build/programs/<name>.hex
asm: asm-all

asm-all: $(ASM_FILES:%=$(BUILD_PROG_DIR)/%.hex)
	@echo "Assembled all programs into $(BUILD_PROG_DIR)/"

# rule: build/programs/xxx.asm -> build/programs/xxx.asm.hex (we use .hex)
$(BUILD_PROG_DIR)/%.asm.hex: $(PROG_DIR)/%.asm
	@mkdir -p $(BUILD_PROG_DIR)
	@echo "Assembling $< -> $@"
	@$(PY) $(ASSEMBLER) $< $@ || (echo "ERROR: assembler failed"; exit 1)

# convenience: if FILE is provided, assemble it into the repo's programs/program.hex
# Usage: make load FILE=programs/foo.asm
load:
ifeq ($(strip $(FILE)),)
	@echo "Specify FILE=programs/foo.asm to load (example: make load FILE=programs/program.asm)"
	@if [ -z "$(ASM_FILES)" ]; then echo "No .asm files found in $(PROG_DIR)"; else echo "Available: $(ASM_FILES)"; fi
else
	@echo "Assembling $(FILE) -> $(PROG_DIR)/program.hex"
	@$(PY) $(ASSEMBLER) $(FILE) $(PROG_DIR)/program.hex || (echo "ERROR: assembler failed"; exit 1)
	@echo "Wrote $(PROG_DIR)/program.hex"
endif

# If there is no programs/program.hex, 'sim' will try to automatically create it
# from the first .asm found (if any).
ensure_program_hex:
	@if [ ! -f $(PROG_DIR)/program.hex ]; then \
	  if [ -n "$(ASM_FILES)" ]; then \
	    FIRST=$$(echo $(ASM_FILES) | awk '{print $$1}'); \
	    echo "No $(PROG_DIR)/program.hex found — assembling $$FIRST -> $(PROG_DIR)/program.hex"; \
	    $(PY) $(ASSEMBLER) $$FIRST $(PROG_DIR)/program.hex || (echo "ERROR: assembler failed"; exit 1); \
	  else \
	    echo "Warning: no $(PROG_DIR)/program.hex and no .asm sources found"; \
	  fi \
	else echo "$(PROG_DIR)/program.hex exists; using it."; fi

# -----------------------
# Compile + simulate
# -----------------------
$(BUILD_DIR)/sim.vvp: $(SRC_FILES) $(TB_FILES)
	@mkdir -p $(BUILD_DIR) $(WAVE_DIR)
	@echo "Compiling RTL + TB with $(IVERILOG)..."
	@$(IVERILOG) -o $@ -g2005-sv $(SRC_FILES) $(TB_FILES) || (echo "ERROR: iverilog failed"; exit 1)
	@echo "-> $@"

compile: $(BUILD_DIR)/sim.vvp

sim: ensure_program_hex $(BUILD_DIR)/sim.vvp
	@echo "Running simulation (vvp) ..."
	@$(VVP) $(BUILD_DIR)/sim.vvp

# run sim and move VCD into waves/ (tb already does $dumpfile(\"cpu.vcd\"))
sim-vcd: sim
	@if [ -f cpu.vcd ]; then mkdir -p $(WAVE_DIR); mv cpu.vcd $(WAVE_DIR)/cpu.vcd; echo "Moved cpu.vcd -> $(WAVE_DIR)/cpu.vcd"; else echo "No cpu.vcd produced by TB."; fi

# -----------------------
# Lint (verilator --lint-only)
# -----------------------
lint:
	@echo "Running verilator --lint-only (if installed)"
	@which $(VERILATOR) >/dev/null 2>&1 || (echo "verilator not found; skipping"; exit 0)
	@$(VERILATOR) --lint-only $(SRC_FILES) || true

# -----------------------
# Clean
# -----------------------
clean:
	@echo "Cleaning build artefacts..."
	@rm -rf $(BUILD_DIR) $(WAVE_DIR) *.vvp *.vcd
	@echo "Done."
