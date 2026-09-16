
# FPGA-Accelerated Hawkes Process for Market Regime Detection

This repository contains the hardware implementation of a high-frequency financial regime detection system. It translates a statistical learning model (a Hawkes Process) into a low-latency, fixed-point RTL architecture designed for the Xilinx Artix-7 (XC7A100T) FPGA[cite: 1].

This project represents the hardware engineering half of a broader system. The pure statistical learning, maximum-likelihood estimation (MLE), and parameter extraction in Python can be found in the [Hawkes Statistical Learning repository](https://github.com/rishav-singh15/Hawkes-Statistical-Learning).

## The Problem
Modern electronic markets operate at microsecond timescales[cite: 1]. Traditional software-based classifiers suffer from unpredictable operating system interrupts, introducing latency and jitter[cite: 1]. By the time a software model evaluates a market crash, the actionable time window has closed.

## The Hardware Approach
This design implements a deterministic, self-exciting point process directly on silicon. Because the Hawkes kernel is exponential, the intensity updating possesses the Markov property, allowing for an $\mathcal{O}(1)$ recursive update[cite: 1]. 

* **Parallel Filter Bank:** Three independent processing engines (Quiet, Trending, Crash) run in parallel, orchestrated by a Master FSM that evaluates maximum-likelihood every 1,000 events[cite: 1].
* **Fixed-Point Datapath:** Utilizes custom Q-format numbers (Q16.16, Q4.28, Q8.24) to maintain numerical stability without the overhead of floating-point units[cite: 1].
* **Memory-Mapped LUTs:** Complex polynomial approximations for exponential decay and logarithmic penalties are bypassed using synthesized Block RAM (BRAM) lookup tables[cite: 1].

## Theoretical Performance Limits
Based on the synthesized single-engine datapath and architectural calculations for the expanded parallel filter bank, the theoretical limits of the design at a 100 MHz clock frequency are:
* **Latency:** 90 ns deterministic latency per event (9 clock cycles)[cite: 1].
* **Resource Efficiency:** Estimated to utilize under 9% of available BRAM and under 3% of DSP48E1 slices on the Artix-7[cite: 1].

## Repository Structure
* `rtl/`: Verilog source code for the Hawkes Processing Engines, LUT modules, and the Master FSM.
* `testbench/`: Verilog testbenches for unit testing and full 3-engine simulation.
* `python/`: Tooling to synthesize floating-point traffic into fixed-point `.mem` files, and scripts to decode/visualize the RTL simulation outputs.
* `data/`: Directory for generated memory files and simulation CSV results.

## Reproducing the Results (Open-Source Simulation)
This repository is configured to simulate the RTL and generate mathematical proofs using `iverilog`, `surfer`, and Python.

### 1. Setup Environment
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

```

### 2. Generate Memory and Compile RTL

```bash
cd python
python generate_mem_files.py
mv *.mem ../rtl/
cd ../rtl
iverilog -o sim_out dt_rom.v exp_lut.v log_lut.v hawkes_pe.v master_fsm.v top_module.v ../testbench/tb_top_module.v

```

### 3. Run Simulation and Visualize

```bash
# Run the Verilog simulation (generates dump.vcd and sim_results.csv)
vvp sim_out

# View the waveform
surfer dump.vcd

# Generate the performance plots
cd ../python
python fpga_hawkes_viz.py
python decode_ila_capture.py

```

