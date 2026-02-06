module spi_master
#(
    parameter CLK_DIV       = 2, // >= 2
    parameter DATA_WIDTH    = 8
    // mode 0
)
(
  input clk,
  input rst,
  input wr_en,
  input [DATA_WIDTH-1:0] din,
  
  output cs,
  output reg sclk,
  output mosi      
);

// SCLK Generator
reg [$clog2(CLK_DIV)-1:0] clk_cnt;
reg                       sclk_en;
always@(posedge clk) begin
    if(rst) begin
        clk_cnt <= 0;
        sclk    <= 0;
    end else if(sclk_en) begin
        if(clk_cnt == CLK_DIV-1) begin
            clk_cnt <= 0;
            sclk    <= ~sclk;
        end else begin
            clk_cnt <= clk_cnt + 1;
        end
    end else begin
        clk_cnt <= 0;
        sclk    <= 0;
    end
end

localparam [1:0]
    IDLE  = 2'b00,
    START = 2'b01,
    DATA  = 2'b10,
    STOP  = 2'b11;
reg [1:0] state;

reg [DATA_WIDTH-1:0]       shift_tx;
reg [$clog2(DATA_WIDTH):0] bit_cnt;

assign cs   = (state == IDLE || state == STOP);
assign mosi = shift_tx[DATA_WIDTH-1];
// FSM
always@(posedge clk or posedge rst) begin
    if(rst) begin
        state    <= IDLE;
        shift_tx <= 0;
        bit_cnt  <= 0;
        sclk_en  <= 0;
    end else begin
        case(state) 
        
            IDLE : begin
               if(wr_en) begin
                    state    <= START;
                    shift_tx <= din;
                    bit_cnt  <= 0;
               end else begin
                   state    <= IDLE;
                   shift_tx <= 0;
                   bit_cnt  <= 0;
                   sclk_en  <= 0;
               end
            end
        
            START : begin
                state   <= DATA;
                sclk_en <= 1;            
            end
            
            DATA : begin
               if(bit_cnt == DATA_WIDTH-1) begin
                    state   <= STOP;
                    sclk_en <= 0;
                    bit_cnt <= 0;
               end else if(sclk && clk_cnt == CLK_DIV-1) begin  // data shifted out on falling edge
                    shift_tx <= shift_tx << 1;
                    bit_cnt  <= bit_cnt + 1;
               end
            end
            
            STOP : begin
                state    <= IDLE;
                shift_tx <= 0;
                bit_cnt  <= 0;
            end
            
               
        endcase
    end
end

endmodule
