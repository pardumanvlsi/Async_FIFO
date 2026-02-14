#!/bin/bash

###############################################################################
# Icarus Verilog Simulation Script for Async FIFO
# Author: Auto-generated
# Date: 2026-02-14
###############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Async FIFO Icarus Verilog Simulation${NC}"
echo -e "${GREEN}========================================${NC}"

# Clean previous simulation files
echo -e "\n${YELLOW}[1/3] Cleaning previous simulation files...${NC}"
rm -f async_fifo.vvp async_fifo.vcd

# Compile with Icarus Verilog
echo -e "\n${YELLOW}[2/3] Compiling with Icarus Verilog...${NC}"
iverilog \
    -g2012 \
    -o async_fifo.vvp \
    async_fifo.v \
    async_fifo_tb.v

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Compilation failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Compilation successful!${NC}"

# Run simulation
echo -e "\n${YELLOW}[3/3] Running simulation...${NC}"
vvp async_fifo.vvp | tee simulation.log

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Simulation failed!${NC}"
    exit 1
fi

# Check results
echo -e "\n${YELLOW}Checking results...${NC}"
if grep -q "ALL TESTS PASSED" simulation.log; then
    echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}Simulation completed successfully${NC}"
else
    echo -e "${RED}❌ TEST FAILURES DETECTED${NC}"
    echo -e "${RED}Check output above for error details${NC}"
    exit 1
fi

# Display waveform info
echo -e "\n${YELLOW}Waveform generated: async_fifo.vcd${NC}"
echo -e "${YELLOW}To view waveforms, run:${NC}"
echo -e "  ${GREEN}gtkwave async_fifo.vcd &${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Simulation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"

# Summary
echo -e "\nFiles generated:"
echo -e "  - async_fifo.vvp (compiled executable)"
echo -e "  - async_fifo.vcd (waveform file)"
echo -e "  - simulation.log (simulation output)"

exit 0
