# SPI Master Controller (SystemVerilog)

## Overview

This repository contains a high-speed, synchronous **SPI Master Controller** implemented in SystemVerilog. The design is optimized for single-clock domain reliability and follows the **Mode 0 (CPOL=0, CPHA=0)** protocol.

## Technical Highlights

* **Single Clock Domain Architecture:** Utilizes a clock-enable pulse to generate a 1MHz SCLK from a 50MHz source, simplifying timing analysis and preventing metastability.
* **Full-Duplex Communication:** Employs an 8-bit circular shift register to simultaneously transmit `mosi` data and sample incoming `miso` bits.
* **Hardware Ready:** Features synchronous reset logic to ensure deterministic initialization and eliminate unknown (`NaN`) states in simulation.

## Verification

The design was verified using a Master-Slave loopback testbench.

* **Result:** Verified bit-perfect data exchange with precise control of the active-low Chip Select (`cs_n`) signal.
