# Contributing to kdwm

Contributions should preserve the focused Arch Linux/X11 scope, the Matugen-authoritative semantic pipeline, and the dark mostly monochromatic visual language.

## Workflow

Create work from `dev` on a focused branch:

```text
stage/<issue-number>-<short-english-slug>
```

Use commit subjects in this form:

```text
<type>/<scope>: <summary>
```

Open integration changes against `dev`. `main` is the stable branch.

## Expectations

- preserve unrelated user changes and existing configuration backups
- keep custom C, QML, JavaScript, shell, and configuration code free of explanatory source comments
- avoid hardcoded users, homes, devices, monitors, interfaces, and checkout locations
- keep Matugen as the single palette authority
- keep user-visible Quickshell text in natural Brazilian Portuguese
- do not perform Xlib work directly from asynchronous signal handlers
- document limitations instead of claiming unsupported compatibility

## Validation

Run the checks relevant to the change:

```bash
bash -n install.sh scripts/apply-theme scripts/build-package scripts/launcher scripts/restart-dwm scripts/start-session scripts/status-daemon scripts/wallpaper
python -m py_compile scripts/generate-theme scripts/system-stats-daemon
git diff --check
./install.sh --user "$USER" --dry-run
```

DWM changes must build through `scripts/build-package`. Theme changes must be tested on multiple wallpapers while DWM and existing clients remain running. Launcher changes must cover search, keyboard navigation, Enter, Escape, and generated-theme parsing.
