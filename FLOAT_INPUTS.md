# Processed input hook

Base: vladfi1/slippi-ssbm-asm `ai-inputs-rebase`, 0ca638e6a2ca5d97fe3d62d15be86f5f8b402550.
The implementation contract and test results live in ExPhil's
`docs/planning/FLOAT_INPUT_INJECTION_REVIEW.md`.

Build `gecko` (JLaferri/gecko) and put it and PowerPC binutils on PATH,
then run `elixir build-float-inputs.exs` (Elixir 1.18+). The shell wrapper
delegates to the same script. You may override `GECKO`, `PPC_AS`,
and `PPC_READELF`. With Nix, use the unwrapped PowerPC binutils package;
the wrapped ppc-embedded toolchain unnecessarily builds newlib, which
fails with current GCC on this host.

The v2 code uses EXI command DA, requires the matching custom Dolphin,
and is enabled explicitly alongside the existing raw Bot Input Overrides.
Do not replace the full shipped netplay INI with this branch's older output.
Install the one assembled optional code using ExPhil's
`scripts/install_float_dolphin.exs` after building Dolphin's `dolphin-nogui`
target. The installer creates a new directory and a hash manifest.

The builder checks ELF relocations and generates into a fresh temporary
location before replacing the output, so a failed Gecko invocation cannot
silently reuse an old hook. The hook restores processed/physical inputs
and the recorded RNG seed, using an aligned 192-byte DMA buffer. It does
not restore positions, damage, or action state.
