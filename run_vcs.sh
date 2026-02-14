#!/bin/bash

###############################################################################
# VCS Simulation Script for Async FIFO
# Author: Auto-generated
# Date: 2026-02-14
###############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Async FIFO VCS Simulation Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Clean previous simulation files
echo -e "\n${YELLOW}[1/4] Cleaning previous simulation files...${NC}"
rm -rf simv* csrc *.daidir *.vpd *.vcd DVEfiles *.log

# Compile with VCS
echo -e "\n${YELLOW}[2/4] Compiling with VCS...${NC}"
vcs -full64 \
    -sverilog \
    +v2k \
    -timescale=1ns/1ps \
    -debug_access+all \
    -kdb \
    -lca \
    -P pli.tab \
    async_fifo.v \
    async_fifo_tb.v \
    -o simv \
    -l compile.log

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Compilation failed!${NC}"
    echo -e "${RED}Check compile.log for details${NC}"
    exit 1
fi

echo -e "${GREEN}Compilation successful!${NC}"

# Run simulation
echo -e "\n${YELLOW}[3/4] Running simulation...${NC}"
./simv \
    +vcs+dumpvars+async_fifo.vpd \
    -l simulation.log

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Simulation failed!${NC}"
    echo -e "${RED}Check simulation.log for details${NC}"
    exit 1
fi

# Check results
echo -e "\n${YELLOW}[4/4] Checking results...${NC}"
if grep -q "ALL TESTS PASSED" simulation.log; then
    echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}Simulation completed successfully${NC}"
else
    echo -e "${RED}❌ TEST FAILURES DETECTED${NC}"
    echo -e "${RED}Check simulation.log for error details${NC}"
    grep "ERROR" simulation.log
    exit 1
fi

# Display waveform info
echo -e "\n${YELLOW}Waveform generated: async_fifo.vpd${NC}"
echo -e "${YELLOW}To view waveforms, run:${NC}"
echo -e "  ${GREEN}dve -vpd async_fifo.vpd &${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Simulation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"

# Summary
echo -e "\nFiles generated:"
echo -e "  - simv           (executable)"
echo -e "  - async_fifo.vpd (waveform database)"
echo -e "  - compile.log    (compilation log)"
echo -e "  - simulation.log (simulation log)"

exit 0
