/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */
`default_nettype none
`timescale 1ns/1ps

// =============================================================================
// tt_um_dna_accel.v -- Tiny Tapeout top-level wrapper for the BioAccel/DNA_Accel
// design (spi_top.v: spi_lite -> bioaccel_spi_decoder -> dna_accelerator_top).
//
// PIN MAPPING (revised -- see note 1 for why this changed from an earlier draft):
//   clk (dedicated pin) = sclk  (external SPI clock from host -- our only clock)
//   ui_in[0]  = cs_n   (active-low chip select from host)
//   ui_in[1]  = mosi   (data in from host)
//   ui_in[2..7] = unused
//   uo_out[0] = miso   (data out to host)
//   uo_out[1..7] = 0 (unused)
//   uio_*     = all unused: uio_out = 0, uio_oe = 0 (tri-stated as inputs)
//   rst_n (dedicated pin) = used directly as our async active-low reset
//   ena = unused (per TT convention, ignored)
//
// NOTE 1 -- why sclk now lives on the DEDICATED clk pin, not ui_in[0]:
//   An earlier draft of this wrapper put sclk on ui_in[0], reasoning that the
//   dedicated `clk` pin is normally driven by the board's own on-board clock
//   generator, and we specifically want the host's SCK line instead. That
//   reasoning was correct in principle, but Tiny Tapeout's own FAQ documents
//   a hard practical limitation: their automated build pipeline's
//   check_clock_ports.py script cannot detect a clock declared on a sliced
//   port such as ui_in[0], and the officially-documented workaround for this
//   (custom multi-clock-tree config.tcl) is explicitly noted as broken on
//   current OpenLane versions. Separately, current Tiny Tapeout project
//   templates (yaml_version 6+) don't accept a per-project OpenLane config
//   at all -- clocking is centrally managed via a single `clock_hz` field in
//   info.yaml, always applied to the dedicated `clk` port. Putting sclk on
//   the dedicated `clk` pin is therefore the only choice compatible with
//   Tiny Tapeout's actual automated submission pipeline. The practical
//   consequence: on the physical board/harness, the host's SPI clock (SCK)
//   must be wired to the chip's dedicated clock input, bypassing the demo
//   board's own on-board RP2040 clock generator for this project.
// =============================================================================

module tt_um_dna_accel (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock -- THIS is sclk, the external SPI clock (see note 1)
    input  wire       rst_n     // reset_n - low to reset
);

    wire cs_n = ui_in[0];
    wire mosi = ui_in[1];
    wire miso;

    spi_top u_spi_top (
        .sclk  (clk),
        .rst_n (rst_n),
        .cs_n  (cs_n),
        .mosi  (mosi),
        .miso  (miso)
    );

    // All output pins must be assigned. Unused bits go to 0.
    assign uo_out  = {7'b0000000, miso};
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;   // all uio pins tri-stated as inputs -- unused

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, uio_in, ui_in[7:2], 1'b0};

endmodule
