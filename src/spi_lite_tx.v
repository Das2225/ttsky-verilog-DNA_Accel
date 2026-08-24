`timescale 1ns/1ps

module spi_lite_tx (
    input  wire       sclk,
    input  wire       rst_n,
    input  wire       cs_n,
    input  wire       byte_start,
    input  wire [7:0] tx_data,
    output wire       miso
);

    reg [7:0] shift;

    always @(negedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            shift <= 8'h00;
        end
        else if (!cs_n && byte_start) begin
            shift <= tx_data;
        end
        else if (!cs_n) begin
            shift <= {shift[6:0], 1'b0};
        end
    end

    assign miso = shift[7];

endmodule
