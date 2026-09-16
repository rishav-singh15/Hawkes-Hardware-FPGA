import numpy as np

def float_to_q_hex(val, fractional_bits, total_bits):
    """Converts a float to a two's complement hex string for Verilog."""
    q_val = int(round(val * (2 ** fractional_bits)))
    if q_val < 0:
        q_val = (1 << total_bits) + q_val
    return f"{q_val:0{total_bits//4}X}"

def generate_exp_lut(filename="exp_lut.mem"):
    # 12-bit address (Q3.9), 32-bit output (Q1.31)
    with open(filename, 'w') as f:
        for i in range(4096):
            val_float = i / (2 ** 9)
            exp_val = np.exp(-val_float)
            f.write(float_to_q_hex(exp_val, 31, 32) + '\n')
    print(f"Generated {filename}")

def generate_log_lut(filename="log_lut.mem"):
    # 12-bit address (Q8.4), 32-bit output (Q8.24 to match accumulator)
    with open(filename, 'w') as f:
        for i in range(4096):
            val_float = max(i / (2 ** 4), 0.0001) # Avoid log(0)
            log_val = np.log(val_float)
            # Changed 31 fractional bits to 24 to prevent overflow!
            f.write(float_to_q_hex(log_val, 24, 32) + '\n')
    print(f"Generated {filename}")

def generate_dt_rom(filename="dt.mem"):
    # Synthesize bursty Hawkes-like traffic
    with open(filename, 'w') as f:
        # Hand-craft the first few events to perfectly match the textbook shape:
        # 1 initial event, a couple quick follow-ups, a long pause, then another burst.
        curated_dts = [2.0, 0.2, 0.1, 20.0, 0.1, 0.1, 0.1, 25.0, 0.2, 0.1]
        
        for i in range(1024):
            if i < len(curated_dts):
                dt_val = curated_dts[i]
            else:
                # For the rest of the memory:
                # 15% chance of a long pause (5 to 20 seconds) to let it decay
                # 85% chance of a rapid burst (0.01 to 0.4 seconds)
                if np.random.rand() < 0.15:
                    dt_val = np.random.uniform(5.0, 20.0)
                else:
                    dt_val = np.random.uniform(0.01, 0.4)
                    
            f.write(float_to_q_hex(dt_val, 16, 32) + '\n')
    print(f"Generated bursty Hawkes {filename}")

def print_regime_constants():
    # 2020 SPY parameters extracted from the paper
    regimes = {
        "Quiet":    {"mu": 1.36299, "alpha": 0.11522, "beta": 0.14675},
        "Trending": {"mu": 4.20542, "alpha": 0.05069, "beta": 0.09725},
        "Crash":    {"mu": 3.93814, "alpha": 0.07170, "beta": 0.11521}
    }
    
    print("\n--- Verilog Constants ---")
    for name, params in regimes.items():
        mu_q = float_to_q_hex(params["mu"], 24, 32)
        alpha_q = float_to_q_hex(params["alpha"], 24, 32)
        beta_q = float_to_q_hex(params["beta"], 28, 32)
        a_over_b_q = float_to_q_hex(params["alpha"]/params["beta"], 24, 32)
        print(f"// {name} Constants")
        print(f".mu(32'h{mu_q}), .alpha(32'h{alpha_q}), .beta(32'h{beta_q}), .a_over_b(32'h{a_over_b_q})")

if __name__ == "__main__":
    generate_exp_lut()
    generate_log_lut()
    generate_dt_rom()
    print_regime_constants()