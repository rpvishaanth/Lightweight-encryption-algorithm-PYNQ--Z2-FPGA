"""
=============================================================================
Logistic Map S-Box Generator for PRESENT Cipher
=============================================================================
Generates a 4-bit S-Box from the logistic chaotic map:
    X(n+1) = r * X(n) * (1 - X(n))

Parameters used in paper:
    r   = 3.99
    x0  = 0.5

Cryptographic analysis computed:
    - Nonlinearity (Walsh-Hadamard Transform)
    - Differential Uniformity
    - Avalanche Effect
    - Strict Avalanche Criterion (SAC) Deviation
    - Bijection check

Author:      Vishaanth R P (24MES1016), VIT Chennai
Supervisor:  Dr. Balakrishnan R, SENSE, VIT Chennai
Date:        2024
Platform:    PYNQ-Z2 (XC7Z020CLG400-1)
=============================================================================
"""

import numpy as np
import itertools

# ============================================================
# 1. Logistic Map S-Box Generation
# ============================================================
def generate_logistic_sbox(r=3.99, x0=0.5):
    """
    Generate a bijective 4-bit S-Box from the logistic map.
    Iterates the map until 16 unique values in [0,15] are collected.

    Args:
        r  : logistic map control parameter (3.57 < r <= 4 for chaos)
        x0 : initial condition (0 < x0 < 1)

    Returns:
        sbox : list of 16 integers, each in [0,15], all unique (bijective)
    """
    x = x0
    sbox = []
    seen = set()
    max_iter = 100000

    for _ in range(max_iter):
        x = r * x * (1.0 - x)
        val = int(x * 256) % 16
        if val not in seen:
            seen.add(val)
            sbox.append(val)
        if len(sbox) == 16:
            break

    if len(sbox) < 16:
        raise ValueError(f"Could not generate bijective S-Box with r={r}, x0={x0}")

    return sbox


# ============================================================
# 2. Cryptographic Analysis
# ============================================================
def check_bijection(sbox):
    """Check that S-Box is a bijection (all outputs unique)."""
    return len(set(sbox)) == 16


def compute_nonlinearity(sbox):
    """
    Compute nonlinearity using Walsh-Hadamard Transform.
    For a 4-bit S-Box: NL = 2^(n-1) - (1/2)*max|WHT|
    Ideal nonlinearity for 4-bit S-Box = 4.
    """
    n = 4
    nl_vals = []
    for bit in range(n):
        # Extract single output bit as Boolean function
        f = np.array([(sbox[x] >> bit) & 1 for x in range(16)], dtype=int)
        f_pm = 1 - 2 * f  # map {0,1} -> {1,-1}

        # WHT
        wht = np.zeros(16, dtype=float)
        for w in range(16):
            total = 0
            for x in range(16):
                # Inner product of w and x over GF(2)
                ip = bin(w & x).count('1') % 2
                total += ((-1) ** ip) * f_pm[x]
            wht[w] = total

        nl = (2 ** (n - 1)) - (0.5 * np.max(np.abs(wht)))
        nl_vals.append(int(nl))

    return min(nl_vals)


def compute_differential_uniformity(sbox):
    """
    Compute differential uniformity.
    du = max over all (a≠0, b) of |{x : sbox[x^a] ^ sbox[x] = b}|
    Lower is better. Ideal for 4-bit = 4.
    """
    n = 16
    max_du = 0
    for a in range(1, n):
        diff_table = [0] * n
        for x in range(n):
            diff = sbox[x ^ a] ^ sbox[x]
            diff_table[diff] += 1
        max_du = max(max_du, max(diff_table))
    return max_du


def compute_avalanche_effect(sbox):
    """
    Compute avalanche effect:
    Average fraction of output bits that change when one input bit is flipped.
    Target: ~50% (0.5)
    """
    n = 4
    total_flips = 0
    total_pairs = 0

    for x in range(16):
        for bit in range(n):
            x_flipped = x ^ (1 << bit)
            diff = sbox[x] ^ sbox[x_flipped]
            total_flips += bin(diff).count('1')
            total_pairs += 1

    return (total_flips / (total_pairs * n)) * 100.0


def compute_sac(sbox):
    """
    Compute Strict Avalanche Criterion (SAC) deviation.
    For each output bit j and input bit flip i:
        P(output_bit_j changes) should be 0.5
    SAC deviation = average |P - 0.5| across all (i,j) pairs.
    Ideal deviation = 0.
    """
    n = 4
    deviations = []
    for i in range(n):             # input bit to flip
        for j in range(n):         # output bit to observe
            count = 0
            for x in range(16):
                x_flip = x ^ (1 << i)
                if ((sbox[x] >> j) & 1) != ((sbox[x_flip] >> j) & 1):
                    count += 1
            prob = count / 16.0
            deviations.append(abs(prob - 0.5))

    return sum(deviations) / len(deviations)


def compute_bic_nonlinearity(sbox):
    """
    Bit Independence Criterion — Nonlinearity.
    Average nonlinearity of (output_i XOR output_j) for all i≠j pairs.
    """
    n = 4
    nl_list = []
    for i, j in itertools.combinations(range(n), 2):
        # Combine two output bits into a Boolean function
        f = np.array([((sbox[x] >> i) & 1) ^ ((sbox[x] >> j) & 1)
                      for x in range(16)], dtype=int)
        f_pm = 1 - 2 * f

        wht = np.zeros(16, dtype=float)
        for w in range(16):
            total = 0
            for x in range(16):
                ip = bin(w & x).count('1') % 2
                total += ((-1) ** ip) * f_pm[x]
            wht[w] = total

        nl = (2 ** (n - 1)) - (0.5 * np.max(np.abs(wht)))
        nl_list.append(int(nl))

    return sum(nl_list) / len(nl_list)


# ============================================================
# 3. Verilog ROM Generator
# ============================================================
def print_verilog_sbox(sbox):
    """Print Verilog case statement for the S-Box."""
    print("\n// Logistic-map S-Box — paste into present_encrypt_sbox_chaotic.v")
    print("always @(idat)")
    print("    case (idat)")
    for i, v in enumerate(sbox):
        print(f"        4'h{i:X} : odat = 4'h{v:X};")
    print("        default: odat = 4'h0;")
    print("    endcase")


def save_sbox_values(sbox, path="sbox_values.txt"):
    """Save S-Box table to text file."""
    with open(path, 'w') as f:
        f.write("Logistic Map S-Box (r=3.99, x0=0.5)\n")
        f.write("=" * 40 + "\n")
        f.write("Input  | Output\n")
        f.write("-" * 20 + "\n")
        for i, v in enumerate(sbox):
            f.write(f"  0x{i:X}  |  0x{v:X}\n")
    print(f"S-Box values saved to {path}")


# ============================================================
# 4. Main
# ============================================================
if __name__ == "__main__":
    print("=" * 60)
    print("  Logistic Map S-Box Generator")
    print("  r=3.99, x0=0.5")
    print("=" * 60)

    # Generate
    sbox = generate_logistic_sbox(r=3.99, x0=0.5)

    print(f"\nGenerated S-Box:")
    print("In  :", [f"0x{i:X}" for i in range(16)])
    print("Out :", [f"0x{v:X}" for v in sbox])

    # Verify bijection
    print(f"\nBijection check : {'PASS' if check_bijection(sbox) else 'FAIL'}")

    # Cryptographic analysis
    nl  = compute_nonlinearity(sbox)
    du  = compute_differential_uniformity(sbox)
    ae  = compute_avalanche_effect(sbox)
    sac = compute_sac(sbox)
    bic = compute_bic_nonlinearity(sbox)

    print("\n" + "=" * 60)
    print("  Cryptographic Properties")
    print("=" * 60)
    print(f"{'Metric':<30} {'Proposed':>10} {'PRESENT':>10} {'Ideal':>10}")
    print("-" * 60)
    print(f"{'Nonlinearity':<30} {nl:>10} {'4':>10} {'4':>10}")
    print(f"{'Differential Uniformity':<30} {du:>10} {'4':>10} {'4':>10}")
    print(f"{'Avalanche Effect (%)':<30} {ae:>10.2f} {'62.50':>10} {'~50.00':>10}")
    print(f"{'SAC Deviation':<30} {sac:>10.4f} {'0.1250':>10} {'0.0000':>10}")
    print(f"{'BIC Nonlinearity (avg)':<30} {bic:>10.2f} {'4.00':>10} {'4.00':>10}")
    print("=" * 60)

    # SAC improvement
    sac_original = 0.1250
    improvement = ((sac_original - sac) / sac_original) * 100
    print(f"\nSAC improvement over static PRESENT S-Box: {improvement:.1f}%")
    print(f"Avalanche effect closer to ideal (50%): "
          f"{'YES' if abs(ae - 50) < abs(62.5 - 50) else 'NO'}")

    # Save files
    save_sbox_values(sbox, "sbox_values.txt")
    print_verilog_sbox(sbox)
