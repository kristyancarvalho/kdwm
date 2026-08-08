#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target_user="${SUDO_USER:-${USER}}"
[[ "$target_user" == root ]] && target_user=kristyan
target_home="$(getent passwd "$target_user" | cut -d: -f6)"

if [[ ! -d "$target_home" || "$target_user" != kristyan ]]; then
  printf 'This rice is intentionally scoped to user kristyan.\n' >&2
  exit 1
fi

backup_link() {
  local source=$1 destination=$2
  mkdir -p "$(dirname "$destination")"
  if [[ -e "$destination" && ! -L "$destination" ]]; then
    local backup="${destination}.dwm-rice-backup.$(date +%Y%m%d%H%M%S)"
    mv "$destination" "$backup"
    printf 'backed up %s to %s\n' "$destination" "$backup"
  fi
  ln -sfn "$source" "$destination"
}

install -d -o "$target_user" -g "$target_user" "$target_home/.config" "$target_home/.cache/dwm-rice"
backup_link "$repo_dir/quickshell" "$target_home/.config/quickshell/dwm-rice"
backup_link "$repo_dir/picom/picom.conf" "$target_home/.config/picom/picom.conf"
backup_link "$repo_dir/config/gtk-3.0/settings.ini" "$target_home/.config/gtk-3.0/settings.ini"
backup_link "$repo_dir/config/gtk-4.0/settings.ini" "$target_home/.config/gtk-4.0/settings.ini"
backup_link "$repo_dir/config/environment.d/90-dwm-rice.conf" "$target_home/.config/environment.d/90-dwm-rice.conf"
chown -h "$target_user:$target_user" "$target_home/.config/quickshell/dwm-rice" "$target_home/.config/picom/picom.conf" "$target_home/.config/gtk-3.0/settings.ini" "$target_home/.config/gtk-4.0/settings.ini" "$target_home/.config/environment.d/90-dwm-rice.conf"

printf 'Deployment links are ready for %s. Run scripts/build-package as %s, then install the package as root.\n' "$target_user" "$target_user"

