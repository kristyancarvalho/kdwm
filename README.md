# DWM Pywal desktop shell

This repository is the source of truth for Kristyan's X11 DWM session. It keeps DWM as the window manager, adds 10px smart gaps, and uses a small Quickshell X11 desktop dashboard below normal windows.

## Install

Run `sudo ./install.sh` from this checkout. It safely creates repository-backed links under `/home/kristyan/.config`, builds DWM as `kristyan`, installs the resulting Arch package, and installs the `DWM Rice` SDDM entry. Runtime files live only in `~/.cache/dwm-rice` and `~/.cache/wal`.

Dependencies: `dwm`, `quickshell`, `python-pywal`, `picom`, `feh`, `rofi`, `jq`, `curl`, `lm_sensors`, and standard X11 utilities.

## Wallpaper and theme

`scripts/wallpaper refresh` fetches safe-for-work Wallhaven metadata configured in `wallpaper/sources.json`; downloaded images stay in `~/.cache/dwm-rice/wallpapers`.

Use `scripts/wallpaper select`, `random`, `set PATH`, `list`, or `current`. `Alt+w` opens the Rofi selector. Each selection sets the root image, runs Pywal, writes one normalized `theme.json`, merges Xresources, and sends DWM `SIGUSR1`. DWM reloads color objects from its normal event loop—no compilation, restart, or logout.

## Shell

`scripts/start-session` restores the wallpaper/theme, starts Picom, a single metrics producer, Quickshell, and then DWM. The Quickshell `XPanelWindow` is `aboveWindows: false`, non-focusable, and ignores exclusive space, so normal clients cover it. Dashboard cards refresh from one JSON snapshot per second and gracefully omit unavailable sensors.

Keybindings: `Alt+p` application launcher, `Alt+Shift+Return` terminal, `Alt+w` wallpaper chooser, `Alt+Shift+h/l` reduce/increase gaps.

If Quickshell fails, DWM remains usable; run `quickshell -p /home/kristyan/src/dwm/quickshell` from a terminal to inspect it. Rebuild manually with `sudo -u kristyan scripts/build-package` then `sudo pacman -U dwm-*-x86_64.pkg.tar.zst`.
