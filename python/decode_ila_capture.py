import matplotlib.pyplot as plt
import numpy as np
import os

def decode_q_format(hex_str, fractional_bits):
    """Decodes a two's complement hex string to float."""
    val = int(hex_str, 16)
    # 32-bit two's complement check
    if val & (1 << 31):
        val -= 1 << 32
    return val / (2 ** fractional_bits)

def plot_continuous_hawkes():
    # 1. 2020 Crash parameters to match the hardware engine
    mu = 3.93814
    alpha = 0.07170
    beta = 0.11521

    # 2. Read the exact hardware time deltas from dt.mem
    dt_mem_path = "../rtl/dt.mem"
    if not os.path.exists(dt_mem_path):
        print(f"Error: Could not find {dt_mem_path}. Run generate_mem_files.py first.")
        return

    dt_values = []
    with open(dt_mem_path, "r") as f:
        for line in f:
            line = line.strip()
            if line:
                dt_values.append(decode_q_format(line, 16)) # Q16.16 format

    # Take the first 50 events so the graph isn't too crowded
    dt_subset = dt_values[:50]

    plt.figure(figsize=(12, 5))
    
    current_t = 0
    current_lambda_plus = mu # Process starts at baseline intensity

    # 3. Mathematically reconstruct the curve between hardware points
    for dt in dt_subset:
        next_t = current_t + dt
        
        # Generate 50 high-res points between events to draw the curve smoothly
        t_hires = np.linspace(current_t, next_t, 50)
        
        # The exponential decay formula the FPGA is approximating
        decay_curve = mu + (current_lambda_plus - mu) * np.exp(-beta * (t_hires - current_t))
        
        # Plot the decay slope (green line like your screenshot)
        plt.plot(t_hires, decay_curve, color='green', linewidth=1.5)
        
        # Pre-event intensity (at the very bottom of the slope)
        lambda_pre = decay_curve[-1]
        
        # Post-event intensity (jumps up by alpha)
        current_lambda_plus = lambda_pre + alpha
        
        # Plot the vertical impulse jump
        plt.vlines(x=next_t, ymin=lambda_pre, ymax=current_lambda_plus, color='green', linewidth=1.5)
        
        # Draw an event marker on the x-axis (like the arrows in the screenshot)
        plt.plot(next_t, mu - 0.05, marker='^', color='black', markersize=7)
        
        current_t = next_t

    # Add the constant Base Rate (mu) line
    plt.axhline(y=mu, color='purple', linestyle='--', alpha=0.5, label='Base Rate (μ)')

    plt.title("Reconstructed Continuous-Time Hawkes Process (Crash Regime)")
    plt.xlabel("Simulation Time (Seconds)")
    plt.ylabel("Intensity (λ)")
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    
    save_path = "hawkes_continuous_curve.png"
    plt.savefig(save_path)
    print(f"Saved beautiful continuous curve to {save_path}")

if __name__ == "__main__":
    plot_continuous_hawkes()