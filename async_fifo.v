module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4          // FIFO depth = 2^ADDR_WIDTH
)(
    input  wire                  wr_clk,
    input  wire                  rd_clk,
    input  wire                  wr_rst_n,
    input  wire                  rd_rst_n,
    input  wire                  wr_en,
    input  wire                  rd_en,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    output reg  [DATA_WIDTH-1:0]  rd_data,
    output wire                  full,
    output wire                  empty
);
 
    localparam DEPTH = 1 << ADDR_WIDTH;
 
    // FIFO memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
 
    // Binary pointers (extra MSB for full/empty)
    reg [ADDR_WIDTH:0] wr_ptr_bin, rd_ptr_bin;
 
    // Gray pointers
    reg [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
 
    // Synchronized Gray pointers
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
 
    // -------------------------------------------------
    // WRITE CLOCK DOMAIN
    // -------------------------------------------------
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= 0;
            wr_ptr_gray <= 0;
        end
        else if (wr_en && !full) begin
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr_bin  <= wr_ptr_bin + 1'b1;
            wr_ptr_gray <= ( (wr_ptr_bin + 1'b1) >> 1 ) ^ (wr_ptr_bin + 1'b1);
        end
    end
 
    // Sync read pointer into write clock domain
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end
        else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end
 
    // FULL condition
    assign full = (wr_ptr_gray ==
                  {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
                    rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
 
    // -------------------------------------------------
    // READ CLOCK DOMAIN
    // -------------------------------------------------
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= 0;
            rd_ptr_gray <= 0;
            rd_data     <= 0;
        end
        else if (rd_en && !empty) begin
            rd_data     <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
            rd_ptr_bin  <= rd_ptr_bin + 1'b1;
            rd_ptr_gray <= ( (rd_ptr_bin + 1'b1) >> 1 ) ^ (rd_ptr_bin + 1'b1);
        end
    end
 
    // Sync write pointer into read clock domain
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end
        else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end
 
    // EMPTY condition
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);
 
endmodule
