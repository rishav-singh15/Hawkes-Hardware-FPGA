# Hardware Architecture

The regime detection system is implemented on a Digilent Arty A7-100T FPGA operating at a 100 MHz clock frequency.

## Parallel Filter Bank
The architecture consists of three identical processing engines running in parallel, orchestrated by a Master Finite State Machine (FSM). Each engine independently evaluates the Hawkes process log-likelihood using a specific, frozen parameter set corresponding to a market regime (Quiet, Trending, Crash).

### The Processing Pipeline
Each engine executes a 9-cycle fixed-point datapath:
1. **Delta T Fetch:** Retrieves the inter-arrival time from BRAM.
2. **Decay Argument:** Computes `beta * dt`.
3. **Exponential LUT Read:** Addresses a BRAM-based lookup table to fetch the exponential decay factor.
4. **Recursive Update:** Computes the new intensity (`lambda`).
5. **Logarithmic LUT Read:** Addresses a separate BRAM table for the log penalty.
6. **Accumulation:** Updates the signed 40-bit log-likelihood register.

### Fixed-Point Formats
To ensure deterministic microsecond latency without the overhead of floating-point units, the datapath relies entirely on bespoke fixed-point arithmetic:

| Signal | Format | Bits |
| :--- | :--- | :--- |
| Delta t (`dt`) | Q16.16 | 32 |
| Parameters (`mu`, `alpha`) | Q8.24 | 32 |
| Parameter (`beta`) | Q4.28 | 32 |
| EXP LUT output | Q1.31 | 32 |
| EXP LUT address | Q3.9 | 12 |
| LOG LUT address | Q8.4 | 12 |
| Log-likelihood accumulator | Q16.24 | 40 (signed) |
| Alpha/Beta constant | Q8.24 | 32 |

### Performance
By converting standard exact integrals into an asymptotic formulation, the design achieved a 2.5x reduction in DSP utilization. The estimated requirements per the theoretical layout are under 9% of BRAM and under 3% of DSP48E1 slices, achieving a deterministic latency of 90 ns per event.