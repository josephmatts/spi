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
  
  output cs,
  output reg sclk,
  output reg mosi,
  input miso
     
);

// state
localparam [1:0]
    IDLE  = 2'b00,
    START = 2'b01,  // load registers
    DATA  = 2'b10, 
    STOP  = 2'b11;  // reset registers
reg [1:0] state;


reg [DATA_WIDTH-1:0] data_to_send;
reg [$clog2(DATA_WIDTH):0] bit_counter;

assign cs = state == IDLE; // cs goes high at idle only

// registers and data
always@(posedge clk) begin
    if(rst) begin
        data_to_send <= 0;
        bit_counter  <= 0;
    end else begin
        case (state)
            : 
            default: 
        endcase


    end
end



// state change logic
// !need to factor in sclk!
always@(posedge clk) begin
    if(rst) begin
        state <= IDLE;
    end else begin
        case(state)
        
            IDLE : begin
                state <= wr_en ? START : IDLE;
            end

            START : begin
                state <= DATA;
            end

            DATA : begin
                state <= (bit_counter == DATA_WIDTH-1) ? STOP : DATA;
            end

            STOP : begin
                state <= IDLE;
            end

        endcase
    end
end


// clock divider
reg [$clog2(CLOCK_DIVIDER+1):0] clk_counter;
always@(posedge clk) begin
    if(rst || state == IDLE) begin
        clk_counter <= 0;
        sclk        <= CPOL;
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
