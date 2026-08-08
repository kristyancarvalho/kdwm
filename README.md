# kdwm

Kristyan's DWM session: a dark, terminal-centric X11 workstation with a runtime Pywal palette, Kitty, Rofi, Picom, and a persistent Quickshell system dashboard.

## Install

Run `sudo ./install.sh` from this checkout. It creates repository-backed user links under `/home/kristyan/.config`, builds the `dwm` Arch package as `kristyan`, and installs the `kdwm` SDDM session. Runtime state is owned by `kristyan` under `~/.cache/kdwm`:

- `wallpapers/` downloaded wallpaper files
- `theme/` normalized palette files for DWM, Kitty, and Rofi
- `state/` current wallpaper, metrics snapshot, and change markers
- `logs/` Quickshell startup output

## Wallpaper and theme

Use `scripts/wallpaper refresh`, `select`, `random`, `set PATH`, `list`, or `current`. `Alt+w` opens the wallpaper selector. Each selection applies the image, runs Pywal, normalizes its colors into one restrained accent family, updates Xresources, asks DWM to reload through `SIGUSR1`, and refreshes Kitty.

`scripts/start-session` migrates usable legacy state once, restores a valid wallpaper/theme when available, otherwise writes a safe fallback palette, starts Picom, Quickshell, and the compact bar status producer, then supervises DWM. The dashboard cannot prevent DWM from launching.

## Desktop behavior

DWM uses 10px inner and outer gaps, including one tiled client. The bar has no fallback version string. `Alt+Shift+r` or `scripts/restart-dwm` requests an intentional restart through a dedicated exit code; the session wrapper relaunches DWM without returning to SDDM and rate-limits repeated failures. Normal wallpaper changes never rebuild or restart it.

Kitty is the default terminal (`Alt+Shift+Return`) with 0.90 background opacity and the generated kdwm palette. `Alt+p` opens the compact dark Rofi launcher. Quickshell runs below normal clients and displays realtime CPU, memory, network, GPU when present, storage, sensor, process, battery, audio, Bluetooth, clock, and system information.
