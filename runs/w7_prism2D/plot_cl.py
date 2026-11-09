#!/usr/bin/env python3
"""Plot the power spectral density of the lift coefficient (Cl) vs. Strouhal number
(fD/U_inf) for the w7_prism2D case, on log-log axes.

Cl is read from the pimpleFoam log ("Time = ..." lines followed by
"Cl : ..." lines written by forceCoeffs when `log true;` is set).
If the log contains no Cl values, the script falls back to the
forceCoeffs output file postProcessing/forceCoeffs/0/coefficient.dat.

Usage:
    python3 plot_cl.py                      # uses log.pimple, t >= 150 s
    python3 plot_cl.py --tmin 150           # change where the transient cut-off is
    python3 plot_cl.py --fmax 2             # change the frequency axis limit [Hz]
    python3 plot_cl.py --log pimple.log     # a different log file
"""

import argparse
import re
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

CASE_DIR = Path(__file__).resolve().parent

TIME_RE = re.compile(r"^Time = ([-+0-9.eE]+)")
# Matches "Cl : 1.2e-3" or "Cl = 1.2e-3" but not "Cl(f)" / "Cl(r)" or header text
CL_RE = re.compile(r"^\s*Cl\s*[:=]\s*([-+0-9.eE]+)")


def read_cl_from_log(log_path):
    """Return (time, Cl) arrays parsed from an OpenFOAM solver log."""
    times, cls = [], []
    current_time = None
    with open(log_path) as f:
        for line in f:
            m = TIME_RE.match(line)
            if m:
                current_time = float(m.group(1))
                continue
            m = CL_RE.match(line)
            if m and current_time is not None:
                times.append(current_time)
                cls.append(float(m.group(1)))
    return np.array(times), np.array(cls)


def read_cl_from_coeff_file(dat_path):
    """Return (time, Cl) arrays from a forceCoeffs coefficient.dat file."""
    header = None
    with open(dat_path) as f:
        for line in f:
            if line.startswith("#") and "Time" in line:
                header = line.lstrip("#").split()
            elif not line.startswith("#"):
                break
    cl_col = header.index("Cl") if header else 4
    data = np.loadtxt(dat_path, comments="#", usecols=(0, cl_col))
    return data[:, 0], data[:, 1]


def cl_spectrum(t, cl):
    """Single-sided power spectral density of Cl (positive frequencies only).

    pimpleFoam uses an adaptive time step, so the signal is first
    interpolated onto a uniform time grid. The mean is removed and a
    Hann window applied before the FFT to limit spectral leakage.
    """
    dt = np.median(np.diff(t))
    t_uni = np.arange(t[0], t[-1], dt)
    cl_uni = np.interp(t_uni, t, cl)
    cl_uni -= cl_uni.mean()

    window = np.hanning(cl_uni.size)
    spec = np.fft.rfft(cl_uni * window)
    freq = np.fft.rfftfreq(cl_uni.size, d=dt)
    fs = 1.0 / dt
    psd = 2.0 * np.abs(spec) ** 2 / (fs * np.sum(window ** 2))  # one-sided PSD [Cl^2/Hz]
    return freq[1:], psd[1:], dt             # drop the zero-frequency (mean) bin


def main():
    parser = argparse.ArgumentParser(description="Plot the FFT spectrum of Cl")
    parser.add_argument("--log", default=CASE_DIR / "log.pimple", type=Path,
                        help="solver log file (default: log.pimple)")
    parser.add_argument("--coeffs", type=Path,
                        default=CASE_DIR / "postProcessing/forceCoeffs/0/coefficient.dat",
                        help="fallback forceCoeffs data file")
    parser.add_argument("--tmin", type=float, default=150.0,
                        help="only use times >= tmin, to skip the start-up "
                             "transient (default: 150)")
    parser.add_argument("--fmax", type=float, default=None,
                        help="upper frequency limit of the plot "
                             "(default: 10x the peak frequency)")
    parser.add_argument("--stmin", type=float, default=1e-2,
                        help="discard spectrum below this Strouhal number (default: 1e-2)")
    parser.add_argument("--U", type=float, default=0.01,
                        help="freestream velocity for the Strouhal number (default: 0.01)")
    parser.add_argument("--D", type=float, default=0.01,
                        help="reference length for the Strouhal number (default: 0.01)")
    args = parser.parse_args()

    t, cl = np.array([]), np.array([])
    if args.log.exists():
        t, cl = read_cl_from_log(args.log)
        source = args.log.name
    if t.size == 0:
        print(f"No Cl values found in {args.log.name} "
              f"(forceCoeffs 'log' is probably off); reading {args.coeffs} instead.")
        t, cl = read_cl_from_coeff_file(args.coeffs)
        source = args.coeffs.name

    keep = t >= args.tmin
    t, cl = t[keep], cl[keep]

    freq, psd, dt = cl_spectrum(t, cl)
    df = freq[1] - freq[0]
    st = freq * args.D / args.U              # Strouhal number fD/U_inf
    keep = st >= args.stmin                  # discard the lowest-frequency bins
    freq, psd, st = freq[keep], psd[keep], st[keep]
    i_peak = np.argmax(psd)                  # dominant frequency = largest PSD bin
    f_peak = freq[i_peak]

    print(f"Read {t.size} points from {source}: t = {t[0]:g} to {t[-1]:g} s")
    print(f"Resampled at dt = {dt:.4g} s -> Nyquist = {0.5 / dt:.4g} Hz, "
          f"resolution = {df:.4g} Hz")
    print(f"Peak: f = {f_peak:.4f} Hz (+/- {df / 2:.4f}), "
          f"PSD = {psd[i_peak]:.4g}, "
          f"St = f*D/U = {f_peak * args.D / args.U:.4f}")

    fmax = args.fmax if args.fmax is not None else 10.0 * f_peak

    fig, ax = plt.subplots(figsize=(10, 4.5), layout="constrained")
    ax.loglog(st, psd, color="#eb25d4", linewidth=1.2)
    ax.axvline(st[i_peak], color="k", linestyle=":", linewidth=1.2)
    ax.annotate(f"f = {f_peak:.4f} Hz\nSt = {st[i_peak]:.4f}",
                xy=(st[i_peak], 0.97), xycoords=ax.get_xaxis_transform(),
                xytext=(6, 0), textcoords="offset points", va="top")

    ax.set_xlabel(r"$fD/U_{\infty}$", fontsize=16)
    ax.set_ylabel("Power spectral density", fontsize=16)
    ax.set_title(f"Lift Coefficient Power Spectrum", fontsize=18)
    ax.set_xlim(args.stmin, fmax * args.D / args.U)
    ax.grid(True, which="major", color="0.88", linewidth=0.6)
    ax.set_axisbelow(True)
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)

    plt.show()


if __name__ == "__main__":
    main()
