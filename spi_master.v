module i_spi_master
#(
    parameter CLOCK_DIVIDER = 5, // >= 2
    parameter CPOL          = 0, // 0 - 1
    parameter CPHA          = 0, // 0 - 1
    parameter DATA_WIDTH    = 8
)
(
  input clk,
  input rst,
  input wr_en,
  input [DATA_WIDTH-1:0] din,
  
  output reg cs,
  output reg sclk,
  output reg mosi,
  input miso
     
);


// clock divider
reg [$clog2(CLOCK_DIVIDER+1):0] clk_counter;
always@(posedge clk) begin
    if(rst) begin
        clk_counter <= 0;
        sclk        <= 0;
    end else begin
        if(clk_counter == CLOCK_DIVIDER-1) begin
            sclk        <= ~sclk;
            clk_counter <= 0; 
        end else begin
            clk_counter <= clk_counter + 1'b1;
        end
    end
end

endmodule
