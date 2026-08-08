#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target_user=""
install_packages=1
install_wallpaper=1
install_quickshell=1
install_kitty=1
dry_run=0
timestamp=$(date +%Y%m%d%H%M%S)

usage() {
  printf 'Usage: %s [--user USER] [--no-packages] [--no-wallpaper] [--no-quickshell] [--no-kitty] [--dry-run]\n' "$0"
}

while (($#)); do
  case "$1" in
    --user) target_user=${2:?--user requires a value}; shift 2 ;;
    --no-packages) install_packages=0; shift ;;
    --no-wallpaper) install_wallpaper=0; shift ;;
    --no-quickshell) install_quickshell=0; shift ;;
    --no-kitty) install_kitty=0; shift ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

detect_user() {
  if [[ -n "$target_user" ]]; then
    return
  fi
  if [[ -n ${SUDO_USER:-} && ${SUDO_USER} != root ]]; then
    target_user=$SUDO_USER
    return
  fi
  if [[ $(id -u) -ne 0 ]]; then
    target_user=$(id -un)
    return
  fi
  mapfile -t candidates < <(who | awk '$2 ~ /^:/ {print $1}' | sort -u)
  if [[ ${#candidates[@]} -eq 1 ]]; then
    target_user=${candidates[0]}
    return
  fi
  printf 'Unable to determine the desktop user; pass --user USER.\n' >&2
  exit 1
}

run() {
  if ((dry_run)); then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

detect_user
passwd_entry=$(getent passwd "$target_user" || true)
[[ -n "$passwd_entry" ]] || { printf 'Unknown user: %s\n' "$target_user" >&2; exit 1; }
target_home=$(cut -d: -f6 <<<"$passwd_entry")
target_group=$(id -gn "$target_user")
[[ -d "$target_home" ]] || { printf 'Home directory does not exist: %s\n' "$target_home" >&2; exit 1; }
[[ $(id -u) -eq 0 || $target_user == "$(id -un)" ]] || { printf 'Run as root or as %s.\n' "$target_user" >&2; exit 1; }

backup_dir="$target_home/.local/state/kdwm/backups/$timestamp"
system_backup_dir="/var/lib/kdwm/backups/$timestamp"

backup_user_path() {
  local destination=$1 relative backup
  [[ -e "$destination" || -L "$destination" ]] || return 0
  relative=${destination#"$target_home"/}
  backup="$backup_dir/$relative"
  run install -d -o "$target_user" -g "$target_group" "$(dirname "$backup")"
  run mv "$destination" "$backup"
  printf 'Backed up %s to %s\n' "$destination" "$backup"
}

link_user_path() {
  local source=$1 destination=$2
  if [[ -L "$destination" && $(readlink -f "$destination") == "$(readlink -f "$source")" ]]; then
    return
  fi
  backup_user_path "$destination"
  run install -d -o "$target_user" -g "$target_group" "$(dirname "$destination")"
  run ln -s "$source" "$destination"
  ((dry_run)) || chown -h "$target_user:$target_group" "$destination"
}

link_system_path() {
  local source=$1 destination=$2 backup
  if [[ -L "$destination" && $(readlink -f "$destination") == "$(readlink -f "$source")" ]]; then
    return
  fi
  if [[ -e "$destination" || -L "$destination" ]]; then
    backup="$system_backup_dir${destination}"
    run install -d "$(dirname "$backup")"
    run mv "$destination" "$backup"
    printf 'Backed up %s to %s\n' "$destination" "$backup"
  fi
  run install -d "$(dirname "$destination")"
  run ln -s "$source" "$destination"
}

report_detection() {
  local item
  if pacman -Q dwm >/dev/null 2>&1; then
    printf 'Detected installed DWM package: %s\n' "$(pacman -Q dwm)"
  fi
  for item in "$target_home/.config/dwm" "$target_home/.dwm" "/usr/local/src/dwm" "/usr/share/xsessions/dwm.desktop" "$target_home/.config/quickshell" "$target_home/.config/kitty/kitty.conf" "$target_home/.config/picom/picom.conf" "$target_home/.config/rofi"; do
    [[ -e "$item" || -L "$item" ]] && printf 'Detected existing configuration: %s\n' "$item"
  done
  printf 'kdwm ships DWM 6.8 with its own patchset; unrelated DWM source trees are not modified.\n'
}

install_dependencies() {
  local packages=(base-devel libx11 libxinerama libxft freetype2 rofi picom feh jq curl python matugen ttf-jetbrains-mono)
  ((install_quickshell)) && packages+=(quickshell)
  ((install_kitty)) && packages+=(kitty)
  mapfile -t missing < <(pacman -T "${packages[@]}" 2>/dev/null || true)
  if ((${#missing[@]})); then
    run pacman -S --needed --noconfirm "${missing[@]}"
  else
    printf 'All requested packages are already installed.\n'
  fi
}

build_dwm() {
  local desired_version installed_version
  desired_version=$(awk '/^[[:space:]]*pkgver =/ {version=$3} /^[[:space:]]*pkgrel =/ {release=$3} END {print version "-" release}' "$repo_dir/.SRCINFO")
  installed_version=$(pacman -Q dwm 2>/dev/null | awk '{print $2}' || true)
  if [[ -n "$desired_version" && $installed_version == "$desired_version" ]] && cmp -s "$repo_dir/system/dwm.desktop" /usr/share/xsessions/kdwm.desktop; then
    printf 'DWM %s is already installed.\n' "$installed_version"
    return 0
  fi
  protect_system_file "$repo_dir/system/dwm.desktop" /usr/share/xsessions/kdwm.desktop
  if [[ -e /usr/share/xsessions/dwm.desktop ]] && pacman -Qo /usr/share/xsessions/dwm.desktop 2>/dev/null | grep -q ' is owned by dwm '; then
    local legacy_backup="$system_backup_dir/usr/share/xsessions/dwm.desktop"
    run install -d "$(dirname "$legacy_backup")"
    run mv /usr/share/xsessions/dwm.desktop "$legacy_backup"
    printf 'Backed up %s to %s\n' /usr/share/xsessions/dwm.desktop "$legacy_backup"
  fi
  if ((!dry_run)) && ! runuser -u "$target_user" -- test -w "$repo_dir"; then
    printf '%s must be writable by %s for makepkg.\n' "$repo_dir" "$target_user" >&2
    exit 1
  fi
  if ((dry_run)); then
    printf '[dry-run] runuser -u %q -- %q\n' "$target_user" "$repo_dir/scripts/build-package"
    printf '[dry-run] pacman -U --noconfirm <new kdwm package>\n'
    return
  fi
  runuser -u "$target_user" -- "$repo_dir/scripts/build-package"
  package=$(find "$repo_dir" -maxdepth 1 -type f -name 'dwm-[0-9]*-x86_64.pkg.tar.zst' -printf '%T@ %p\n' | sort -nr | head -n1 | cut -d' ' -f2-)
  [[ -n "$package" ]] || { printf 'DWM package was not created.\n' >&2; exit 1; }
  pacman -U --noconfirm "$package"
}

protect_system_file() {
  local source=$1 destination=$2 backup
  [[ -e "$destination" || -L "$destination" ]] || return 0
  cmp -s "$source" "$destination" && return
  backup="$system_backup_dir${destination}"
  run install -d "$(dirname "$backup")"
  run mv "$destination" "$backup"
  printf 'Backed up %s to %s\n' "$destination" "$backup"
}

report_detection
if ((install_packages)); then
  [[ $(id -u) -eq 0 ]] || { printf 'Package installation requires root; use sudo or --no-packages.\n' >&2; exit 1; }
  install_dependencies
fi

run install -d -o "$target_user" -g "$target_group" "$target_home/.config" "$target_home/.local/bin" "$target_home/.local/share"
link_user_path "$repo_dir" "$target_home/.local/share/kdwm"
((install_quickshell)) && link_user_path "$repo_dir/quickshell" "$target_home/.config/quickshell/kdwm"
link_user_path "$repo_dir/picom/picom.conf" "$target_home/.config/picom/picom.conf"
((install_kitty)) && link_user_path "$repo_dir/kitty/kitty.conf" "$target_home/.config/kitty/kitty.conf"
link_user_path "$repo_dir/config/gtk-3.0/settings.ini" "$target_home/.config/gtk-3.0/settings.ini"
link_user_path "$repo_dir/config/gtk-4.0/settings.ini" "$target_home/.config/gtk-4.0/settings.ini"
link_user_path "$repo_dir/config/environment.d/90-kdwm.conf" "$target_home/.config/environment.d/90-kdwm.conf"
link_user_path "$repo_dir/rofi/kdwm.rasi" "$target_home/.config/rofi/kdwm.rasi"
link_user_path "$repo_dir/config/qt6ct/qt6ct.conf" "$target_home/.config/qt6ct/qt6ct.conf"

if [[ $(id -u) -eq 0 ]]; then
  link_system_path "$repo_dir/scripts/start-session" /usr/local/bin/kdwm-session
  link_system_path "$repo_dir/scripts/wallpaper" /usr/local/bin/kdwm-wallpaper
  link_system_path "$repo_dir/scripts/restart-dwm" /usr/local/bin/kdwm-restart
  link_system_path "$repo_dir/scripts/launcher" /usr/local/bin/kdwm-launcher
  link_system_path "$repo_dir/scripts/weather-status" /usr/local/bin/kdwm-weather
fi

if ((install_packages)); then
  build_dwm
fi

if ((install_wallpaper && !dry_run)); then
  runuser -u "$target_user" -- env HOME="$target_home" "$repo_dir/scripts/wallpaper" default || printf 'Lain wallpaper setup failed; run kdwm-wallpaper default later.\n' >&2
fi

printf 'kdwm deployment is ready for %s from %s.\n' "$target_user" "$repo_dir"
