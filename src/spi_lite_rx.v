`timescale 1ns/1ps

module spi_lite_rx (
    input  wire       sclk,
    input  wire       rst_n,
    input  wire       cs_n,
    input  wire       mosi,
    input  wire       byte_done,

    output wire [7:0] rx_data,
    output wire       rx_valid
);

    reg [7:0] shift;

reg [7:0] rx_data_reg;
reg       rx_valid_reg;
wire [7:0] shift_next = {shift[6:0], mosi};

assign rx_data  = rx_data_reg;
assign rx_valid = rx_valid_reg;

always @(posedge sclk or negedge rst_n)
begin

    if(!rst_n)
    begin

        shift        <= 8'h00;
        rx_data_reg  <= 8'h00;
        rx_valid_reg <= 1'b0;

    end

    else if(cs_n)
    begin

        rx_valid_reg <= 1'b0;

    end

    else
    begin

        shift <= {shift[6:0], mosi};

        rx_valid_reg <= 1'b0;

        if(byte_done)
        begin

            rx_data_reg  <= {shift[6:0], mosi};
            rx_valid_reg <= 1'b1;

        end

    end

end

endmodule
