`timescale 1ns/1ps

module spi_lite_bit_counter (
    input  wire sclk,
    input  wire rst_n,
    input  wire cs_n,
    output wire byte_done,
    output wire byte_start
);

    reg [2:0] cnt;

    always @(posedge sclk or negedge rst_n or posedge cs_n) begin
        if (!rst_n)      cnt <= 3'd0;
        else if (cs_n)   cnt <= 3'd0;
        else             cnt <= cnt + 3'd1;
    end

    assign byte_done  = (cnt == 3'd7);
    assign byte_start = (cnt == 3'd0);

endmodule
