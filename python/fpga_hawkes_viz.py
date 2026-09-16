import pandas as pd
import matplotlib.pyplot as plt
import os

def decode_signed_q(val, frac_bits=24, total_bits=40):
    """Decodes a two's complement integer from the Verilog CSV."""
    val = int(val)
    if val & (1 << (total_bits - 1)):
        val -= 1 << total_bits
    return val / (2 ** frac_bits)

def plot_ll_scores(csv_file):
    if not os.path.exists(csv_file):
        print(f"Error: {csv_file} not found. Run the iverilog simulation first.")
        return
        
    df = pd.read_csv(csv_file)
    
    # Decode the Verilog integers back into real numbers
    ll_q = [decode_signed_q(x) for x in df['LL_Q']]
    ll_t = [decode_signed_q(x) for x in df['LL_T']]
    ll_c = [decode_signed_q(x) for x in df['LL_C']]
    
    plt.figure(figsize=(10, 6))
    plt.plot(df['Time'], ll_q, label='Quiet LL', color='green', marker='o')
    plt.plot(df['Time'], ll_t, label='Trending LL', color='orange', marker='o')
    plt.plot(df['Time'], ll_c, label='Crash LL', color='red', marker='o')
    
    plt.title("RTL Simulation Log-Likelihood Scores")
    plt.xlabel("Simulation Time (ns)")
    plt.ylabel("Log-Likelihood Score")
    plt.legend()
    plt.grid(True)
    plt.savefig("rtl_ll_scores_plot.png")
    print("Saved true RTL visualization to rtl_ll_scores_plot.png")

if __name__ == "__main__":
    plot_ll_scores("../data/sim_results.csv")