`timescale 1ns/1ps

module spi_lite (
    input  wire       sclk,
    input  wire       rst_n,
    input  wire       cs_n,
    input  wire       mosi,
    output wire       miso,

    output wire [7:0] rx_data,
    output wire       rx_valid,

    input  wire [7:0] tx_data
);

    wire byte_done;
    wire byte_start;

    spi_lite_bit_counter u_cnt (
        .sclk       (sclk),
        .rst_n      (rst_n),
        .cs_n       (cs_n),
        .byte_done  (byte_done),
        .byte_start (byte_start)
    );

    spi_lite_rx u_rx (
        .sclk      (sclk),
        .rst_n     (rst_n),
        .cs_n      (cs_n),
        .mosi      (mosi),
        .byte_done (byte_done),
        .rx_data   (rx_data),
        .rx_valid  (rx_valid)
    );

    spi_lite_tx u_tx (
        .sclk       (sclk),
        .rst_n      (rst_n),
        .cs_n       (cs_n),
        .byte_start (byte_start),
        .tx_data    (tx_data),
        .miso       (miso)
    );

endmodule
