module spi_master
#(
    // MODE 0
    parameter DATA_WIDTH          = 8, 
    parameter CLOCK_DIVIDER_COUNT = 125     
)
(
    input clk,
    input reset,
    input [DATA_WIDTH-1:0] din,
    input en,
    
    output reg cs,
    output reg sck,
    output reg mosi 
);

// sck generator
reg [15:0] clock_counter; 
reg sck_d;
reg sck_en;
always@(posedge clk) begin
        sck_d <= sck;
        if(reset) begin
            sck    <= 0;
            sck_d  <= 0;
            clock_counter <= 0; 
        end else if(sck_en) begin
            if(clock_counter == CLOCK_DIVIDER_COUNT-1) begin
                clock_counter <= 0;
                sck   <= ~sck;
            end else begin
                clock_counter <= clock_counter + 1'b1;
            end
        end else begin
            sck <= 0;
        end
end


// states
reg [1:0] state;
localparam [1:0]
    IDLE  = 2'b00,
    START = 2'b01,
    DATA  = 2'b10,
    STOP  = 2'b11;
    
reg [DATA_WIDTH-1:0] shift_tx;
reg [$clog2(DATA_WIDTH)-1:0] bit_counter;
    
always@(posedge clk) begin
    if(reset) begin
        cs          <= 1;
        mosi        <= 0;
        shift_tx    <= 0;
        bit_counter <= 0;
        state       <= IDLE;
        sck_en      <= 0;
    end else begin
        case(state)

            IDLE : begin
                if(en) begin
                    cs          <= 0;
                    mosi        <= din[0];
                    shift_tx    <= din >> 1;
                    bit_counter <= 0;
                    state       <= DATA;
                    sck_en      <= 1;
                end else begin
                    cs          <= 1;
                    mosi        <= 0;
                    shift_tx    <= 0;
                    bit_counter <= 0;
                    state       <= IDLE;
                    sck_en      <= 0;
                end   
            end
                            
            DATA : begin                
                if(sck_d && ~sck) begin // negative edge
                    if(bit_counter == DATA_WIDTH-1) begin
                        sck_en <= 0;
                        state  <= STOP;
                        bit_counter <= 0;
                    end else begin
                        mosi        <= shift_tx[0];
                        shift_tx    <= shift_tx >> 1;
                        bit_counter <= bit_counter + 1;
                    end
                end
            end
            
            STOP : begin
                state <= IDLE;
                cs    <= 1;
            end
                        
        endcase
    end
end

endmodule
