# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer

# ---------------------------------------------------------------------------
# NOTE on clocking: for this project dut.clk IS sclk, the external SPI clock
# (see the note in tt_um_dna_accel_new.v -- sclk lives on the dedicated clk
# pin, not on a ui_in bit, because of Tiny Tapeout's check_clock_ports.py
# limitation). So unlike a normal free-running system-clock design, every
# byte we send has to be hand-shifted onto ui_in[1] (mosi) relative to this
# same clock, exactly the way tb/tb_with_spi.v's spi_send_byte task does it.
#
# TT pin mapping (tt_um_dna_accel_new.v):
#   ui_in[0]  = cs_n   (active-low chip select)
#   ui_in[1]  = mosi
#   uo_out[0] = miso
# ---------------------------------------------------------------------------

CMD_WRITE = 0x01
CMD_READ = 0x02

ADDR_PATTERN_LO = 0x00
ADDR_PATTERN_HI = 0x01
ADDR_DNA_LO = 0x02
ADDR_DNA_HI = 0x03
ADDR_SIMILARITY = 0x04
ADDR_MATCH = 0x05
ADDR_POSITION_LO = 0x06
ADDR_POSITION_HI = 0x07
ADDR_MISMATCH_VEC_LO = 0x08
ADDR_MISMATCH_VEC_HI = 0x09
ADDR_MISMATCH_MASK = 0x0A
ADDR_EXACT_COUNT = 0x0B
ADDR_TRANSITION_COUNT = 0x0C
ADDR_TRANSVERSION_COUNT = 0x0D


class SpiDriver:
    """Bit-bangs the BioAccel SPI protocol onto ui_in/uo_out, mirroring
    tb/tb_with_spi.v's spi_send_byte/spi_write/spi_read tasks exactly
    (mosi set on falling edge, miso sampled on rising edge, MSB first)."""

    def __init__(self, dut):
        self.dut = dut
        self.cs_n = 1
        self.mosi = 0
        self._push()

    def _push(self):
        # Only bits [1:0] of ui_in are used by this design; the rest stay 0.
        self.dut.ui_in.value = (self.mosi << 1) | (self.cs_n << 0)

    def _miso(self):
        return int(self.dut.uo_out.value) & 0x1

    async def send_byte(self, tx):
        rx = 0
        await FallingEdge(self.dut.clk)
        self.mosi = (tx >> 7) & 1
        self._push()
        for i in range(7, -1, -1):
            await RisingEdge(self.dut.clk)
            rx = (rx << 1) | self._miso()
            if i > 0:
                await FallingEdge(self.dut.clk)
                self.mosi = (tx >> (i - 1)) & 1
                self._push()
        return rx

    async def write(self, addr, data):
        self.cs_n = 0
        self._push()
        await Timer(1, units="ns")

        await self.send_byte(CMD_WRITE)
        await self.send_byte(addr)
        await self.send_byte(data)

        await ClockCycles(self.dut.clk, 2)
        self.cs_n = 1
        self._push()
        await ClockCycles(self.dut.clk, 2)

    async def read(self, addr):
        self.cs_n = 0
        self._push()
        await Timer(1, units="ns")

        await self.send_byte(CMD_READ)
        await self.send_byte(addr)
        await self.send_byte(0x00)  # spacer, lets tx_data settle
        data = await self.send_byte(0x00)  # actual readback byte

        await ClockCycles(self.dut.clk, 2)
        self.cs_n = 1
        self._push()
        await ClockCycles(self.dut.clk, 2)
        return data

    async def load_pattern_dna(self, pattern, dna):
        await self.write(ADDR_PATTERN_LO, pattern & 0xFF)
        await self.write(ADDR_PATTERN_HI, (pattern >> 8) & 0xFF)
        await self.write(ADDR_DNA_LO, dna & 0xFF)
        await self.write(ADDR_DNA_HI, (dna >> 8) & 0xFF)  # latches load_dna
        await ClockCycles(self.dut.clk, 3)

    async def read_mutation_info(self):
        similarity = (await self.read(ADDR_SIMILARITY)) & 0x1F
        match = (await self.read(ADDR_MATCH)) & 0x1
        vec_lo = await self.read(ADDR_MISMATCH_VEC_LO)
        vec_hi = await self.read(ADDR_MISMATCH_VEC_HI)
        mask = await self.read(ADDR_MISMATCH_MASK)
        exact_c = (await self.read(ADDR_EXACT_COUNT)) & 0xF
        trans_c = (await self.read(ADDR_TRANSITION_COUNT)) & 0xF
        tv_c = (await self.read(ADDR_TRANSVERSION_COUNT)) & 0xF
        return {
            "similarity": similarity,
            "match": match,
            "mismatch_vector": (vec_hi << 8) | vec_lo,
            "mismatch_mask": mask,
            "exact_count": exact_c,
            "transition_count": trans_c,
            "transversion_count": tv_c,
        }


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")
    # sclk here is the external SPI clock, not a free-running system clock --
    # pick a period comfortably within timing (100ns == 10MHz).
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())

    spi = SpiDriver(dut)

    # Reset (mirrors tb_with_spi.v: cs_n=1, mosi=0 held through reset)
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.uio_in.value = 0
    dut.ui_in.value = 0b01  # cs_n=1, mosi=0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    dut._log.info("Test exact match (pattern == dna, both all-A)")
    await spi.load_pattern_dna(0x0000, 0x0000)
    info = await spi.read_mutation_info()
    assert info["similarity"] == 16
    assert info["match"] == 1
    assert info["mismatch_mask"] == 0b00000000
    assert info["exact_count"] == 8
    assert info["transition_count"] == 0
    assert info["transversion_count"] == 0

    dut._log.info("Test single transition (base7: A->G)")
    await spi.load_pattern_dna(0x0000, 0x8000)
    info = await spi.read_mutation_info()
    assert info["similarity"] == 15
    assert info["match"] == 0
    assert info["mismatch_mask"] == 0b10000000
    assert info["exact_count"] == 7
    assert info["transition_count"] == 1
    assert info["transversion_count"] == 0

    dut._log.info("Test single transversion (base0: A->C)")
    await spi.load_pattern_dna(0x0000, 0x0001)
    info = await spi.read_mutation_info()
    assert info["similarity"] == 14
    assert info["match"] == 0
    assert info["mismatch_mask"] == 0b00000001
    assert info["exact_count"] == 7
    assert info["transition_count"] == 0
    assert info["transversion_count"] == 1

    dut._log.info("All checks passed")
