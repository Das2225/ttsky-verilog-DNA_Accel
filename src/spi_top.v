`timescale 1ns/1ps

module spi_top (
    input  wire sclk,
    input  wire rst_n,
    input  wire cs_n,
    input  wire mosi,
    output wire miso
);

    wire [7:0] rx_data;
    wire       rx_valid;
    wire [7:0] tx_data;

    wire        load_pattern;
    wire        load_dna;
    wire [15:0] pattern_in;
    wire [15:0] dna_in;

    wire [4:0]  similarity_out;
    wire        match_out;
    wire [31:0] position_out;
    wire [15:0] mismatch_vector_out;
    wire [7:0]  mismatch_mask_out;
    wire [3:0]  exact_count_out;
    wire [3:0]  transition_count_out;
    wire [3:0]  transversion_count_out;

    spi_lite u_spi (
        .sclk    (sclk),
        .rst_n   (rst_n),
        .cs_n    (cs_n),
        .mosi    (mosi),
        .miso    (miso),
        .rx_data (rx_data),
        .rx_valid(rx_valid),
        .tx_data (tx_data)
    );

    bioaccel_spi_decoder u_decoder (
        .sclk        (sclk),
        .rst_n       (rst_n),
        .cs_n        (cs_n),
        .rx_data     (rx_data),
        .rx_valid    (rx_valid),
        .tx_data     (tx_data),
        .load_pattern(load_pattern),
        .load_dna    (load_dna),
        .pattern_in  (pattern_in),
        .dna_in      (dna_in),
        .similarity  (similarity_out),
        .match       (match_out),
        .position    (position_out),
        .mismatch_vector(mismatch_vector_out),
        .mismatch_mask  (mismatch_mask_out),
        .exact_count       (exact_count_out),
        .transition_count  (transition_count_out),
        .transversion_count(transversion_count_out)
    );

    dna_accelerator_top u_accelerator (
        .clk           (sclk),
        .rst_n         (rst_n),
        .load_pattern  (load_pattern),
        .load_dna      (load_dna),
        .pattern_in    (pattern_in),
        .dna_in        (dna_in),
        .similarity_out(similarity_out),
        .match_out     (match_out),
        .position_out  (position_out),
        .mismatch_vector_out(mismatch_vector_out),
        .mismatch_mask_out  (mismatch_mask_out),
        .exact_count_out       (exact_count_out),
        .transition_count_out  (transition_count_out),
        .transversion_count_out(transversion_count_out)
    );

endmodule
