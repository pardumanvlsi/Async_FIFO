`timescale 1ns/1ps

module async_fifo_tb;

parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 4;
parameter DEPTH = 1 << ADDR_WIDTH;

reg wr_clk;
reg rd_clk;
reg wr_rst_n;
reg rd_rst_n;
reg wr_en;
reg rd_en;
reg [DATA_WIDTH-1:0] wr_data;

wire [DATA_WIDTH-1:0] rd_data;
wire full;
wire empty;

integer i;
integer error_count = 0;

// reference memory
reg [DATA_WIDTH-1:0] ref_mem [0:1023];
integer wptr = 0;
integer rptr = 0;
integer count = 0;

// DUT
async_fifo #(DATA_WIDTH, ADDR_WIDTH) dut (
    .wr_clk(wr_clk),
    .rd_clk(rd_clk),
    .wr_rst_n(wr_rst_n),
    .rd_rst_n(rd_rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .wr_data(wr_data),
    .rd_data(rd_data),
    .full(full),
    .empty(empty)
);

//////////////////////////////////////////////////////
// CLOCKS (different freq)
//////////////////////////////////////////////////////
initial wr_clk = 0;
always #5 wr_clk = ~wr_clk;   // 100 MHz

initial rd_clk = 0;
always #7 rd_clk = ~rd_clk;   // ~71 MHz

//////////////////////////////////////////////////////
// RESET TEST
//////////////////////////////////////////////////////
initial begin
    wr_rst_n = 0;
    rd_rst_n = 0;
    wr_en = 0;
    rd_en = 0;
    wr_data = 0;

    #40;
    wr_rst_n = 1;
    rd_rst_n = 1;

    #20;
    if (!empty) begin
        $display("ERROR: FIFO not empty after reset");
        error_count = error_count + 1;
    end
end

//////////////////////////////////////////////////////
// WRITE TASK
//////////////////////////////////////////////////////
task write_fifo;
input [DATA_WIDTH-1:0] data;
begin
    @(posedge wr_clk);
    if (!full) begin
        wr_en = 1;
        wr_data = data;

        ref_mem[wptr] = data;
        wptr = wptr + 1;
        count = count + 1;
    end
    else begin
        wr_en = 1; // attempt overflow
    end
    @(posedge wr_clk);
    wr_en = 0;
end
endtask

//////////////////////////////////////////////////////
// READ TASK
//////////////////////////////////////////////////////
task read_fifo;
reg [DATA_WIDTH-1:0] exp;
begin
    @(posedge rd_clk);
    if (!empty) begin
        rd_en = 1;
        exp = ref_mem[rptr];
    end
    else begin
        rd_en = 1; // attempt underflow
    end

    @(posedge rd_clk);
    rd_en = 0;

    if (!empty) begin
        if (rd_data !== exp) begin
            $display("ERROR: Data mismatch exp=%h got=%h time=%0t",
                      exp, rd_data, $time);
            error_count = error_count + 1;
        end
        rptr = rptr + 1;
        count = count - 1;
    end
end
endtask

//////////////////////////////////////////////////////
// TEST SEQUENCE
//////////////////////////////////////////////////////
initial begin
    // VCD dump for waveform viewing
    $dumpfile("async_fifo.vcd");
    $dumpvars(0, async_fifo_tb);
    
    wait(wr_rst_n && rd_rst_n);

    //////////////////////////////////////////////////
    // 1. WRITE UNTIL FULL
    //////////////////////////////////////////////////
    $display("TEST: Fill FIFO");
    for (i = 0; i < DEPTH+2; i = i + 1)
        write_fifo(i);

    if (!full) begin
        $display("ERROR: FULL not asserted");
        error_count = error_count + 1;
    end

    //////////////////////////////////////////////////
    // 2. READ UNTIL EMPTY
    //////////////////////////////////////////////////
    $display("TEST: Empty FIFO");
    for (i = 0; i < DEPTH+2; i = i + 1)
        read_fifo();

    if (!empty) begin
        $display("ERROR: EMPTY not asserted");
        error_count = error_count + 1;
    end

    //////////////////////////////////////////////////
    // 3. SIMULTANEOUS READ/WRITE
    //////////////////////////////////////////////////
    $display("TEST: Simultaneous R/W");
    fork
        begin
            for (i=0;i<50;i=i+1)
                write_fifo($random);
        end
        begin
            for (i=0;i<50;i=i+1)
                read_fifo();
        end
    join

    //////////////////////////////////////////////////
    // 4. RANDOM TRAFFIC
    //////////////////////////////////////////////////
    $display("TEST: Random traffic");
    for (i=0;i<200;i=i+1) begin
        if ($random%2)
            write_fifo($random);
        else
            read_fifo();
    end

    //////////////////////////////////////////////////
    // 5. WRAPAROUND TEST
    //////////////////////////////////////////////////
    $display("TEST: Pointer wrap");
    for (i=0;i<DEPTH*3;i=i+1)
        write_fifo(i);

    for (i=0;i<DEPTH*3;i=i+1)
        read_fifo();

    //////////////////////////////////////////////////
    // RESULT
    //////////////////////////////////////////////////
    #100;
    if (error_count == 0)
        $display("ALL TESTS PASSED ✅");
    else
        $display("TEST FAILED ❌ errors=%0d", error_count);

    $finish;
end

endmodule
