#!/usr/bin/env zsh
# =============================================================================
# modules/06_storage.zsh — Disk space cleaner
# Scans for big files & junk, lets user delete selected items.
# Can be run standalone (outside the wizard) — has its own menu.
# Dependencies: config.zsh, lib/ui.zsh
# =============================================================================

# ------------------------------------------------------------------------------
# module_storage
# Sub-menu for storage operations.
# ------------------------------------------------------------------------------
module_storage() {
  _ui_step "6" "Storage Cleaner"

  while true; do
    print ""
    print -P "  ${UI_BOLD}1)${UI_RESET} Scan for large files (>100MB)"
    print -P "  ${UI_BOLD}2)${UI_RESET} Scan for junk files (caches, .DS_Store, node_modules)"
    print -P "  ${UI_BOLD}3)${UI_RESET} Clean known temp/cache locations"
    print -P "  ${UI_BOLD}q)${UI_RESET} Back to wizard"
    print ""
    print -n -P "  ${UI_BOLD}>${UI_RESET} "

    local choice
    read -r choice
    case "$choice" in
      1) _storage_scan_large ;;
      2) _storage_scan_junk  ;;
      3) _storage_clean      ;;
      q|Q|"") break ;;
      *) _ui_warn "Unknown" ; sleep 1 ;;
    esac
  done
}

# ------------------------------------------------------------------------------
# _storage_scan_large
# Find files larger than 100MB in user dirs.
# ------------------------------------------------------------------------------
_storage_scan_large() {
  _ui_info "Scanning for files >100MB in $HOME and /goinfree/$USER..."
  print ""

  local list="/tmp/mac-setup-bigfiles.txt"
  find "$HOME" "/goinfree/$USER" -type f -size +100M 2>/dev/null \
    | xargs -I {} du -h "{}" 2>/dev/null \
    | sort -rh \
    | head -30 \
    > "$list"

  if [[ ! -s "$list" ]]; then
    _ui_success "No large files found"
    _ui_pause
    return
  fi

  local i=1
  while IFS=$'\t' read -r size path; do
    printf "  ${UI_BOLD}%2d)${UI_RESET}  %-8s  %s\n" $i "$size" "$path"
    ((i++))
  done < "$list"

  print ""
  print -P "  ${UI_DIM}Enter numbers to delete (space-separated), or just ENTER to skip${UI_RESET}"
  print -n -P "  ${UI_BOLD}>${UI_RESET} "
  local nums
  read -r nums
  [[ -z "$nums" ]] && return

  for n in ${(z)nums}; do
    local path
    path=$(sed -n "${n}p" "$list" | cut -f2-)
    if [[ -n "$path" ]] && _ui_confirm "Delete $path?"; then
      rm -rf "$path" && _ui_success "Deleted $path"
    fi
  done

  _ui_pause
}

# ------------------------------------------------------------------------------
# _storage_scan_junk
# Find common junk: .DS_Store, node_modules, __pycache__, .Trash items.
# ------------------------------------------------------------------------------
_storage_scan_junk() {
  _ui_info "Scanning for junk in $HOME..."
  print ""

  local total=0

  for pattern in ".DS_Store" "node_modules" "__pycache__" ".pytest_cache" ".cache"; do
    local count size_kb
    count=$(find "$HOME" -name "$pattern" 2>/dev/null | wc -l | tr -d ' ')
    size_kb=$(find "$HOME" -name "$pattern" -exec du -sk {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')
    local size_mb=$((size_kb / 1024))

    printf "  %-18s  ${UI_DIM}%5d items, ~%5d MB${UI_RESET}\n" "$pattern" "$count" "$size_mb"
    ((total += size_mb))
  done

  print ""
  _ui_info "Total reclaimable: ~${total} MB"
  print ""

  if _ui_confirm "Delete ALL of the above?"; then
    for pattern in ".DS_Store" "node_modules" "__pycache__" ".pytest_cache" ".cache"; do
      find "$HOME" -name "$pattern" -exec rm -rf {} + 2>/dev/null
    done
    _ui_success "Junk cleaned"
  fi

  _ui_pause
}

# ------------------------------------------------------------------------------
# _storage_clean
# Clean well-known temp/cache locations.
# ------------------------------------------------------------------------------
_storage_clean() {
  print ""
  _ui_info "Locations that will be emptied:"
  print ""
  print "    ~/Library/Caches/*"
  print "    ~/Library/Logs/*"
  print "    /tmp/mac-setup-*"
  print ""

  if ! _ui_confirm "Proceed?"; then
    return
  fi

  rm -rf "$HOME/Library/Caches/"* 2>/dev/null
  rm -rf "$HOME/Library/Logs/"*   2>/dev/null
  rm -rf /tmp/mac-setup-*         2>/dev/null

  _ui_success "Caches cleaned"
  _ui_pause
}
