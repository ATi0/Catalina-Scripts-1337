#!/usr/bin/env zsh
# =============================================================================
# modules/01_apps.zsh — App selection wizard
# Loads all apps from manifest, lets user pick placement for each.
# Dependencies: config.zsh, lib/ui.zsh, lib/install.zsh, lib/state.zsh
# =============================================================================

# ------------------------------------------------------------------------------
# module_apps
# Main entry point. Shows the app picker until user types 'd' (done).
# ------------------------------------------------------------------------------
module_apps() {
  _ui_step "1" "App Selection"

  # Build a stable, ordered list of app IDs (associative arrays are unordered)
  typeset -ga APP_ORDER
  APP_ORDER=($(install_list_app_ids))

  while true; do
    _apps_render
    print ""
    print -n -P "  ${UI_BOLD}>${UI_RESET} "
    local choice
    read -r choice

    case "$choice" in
      d|D|"")          break ;;
      a|A)             state_reset_to_recommended ;;
      s|S)             _apps_set_all "skip" ;;
      g|G)             _apps_set_all "goinfree" ;;
      <1->)            _apps_handle_number "$choice" ;;
      *)               _ui_warn "Unknown command: $choice" ; sleep 1 ;;
    esac
  done

  # Post-selection: if Neovim was picked, ask about NvChad
  if [[ "${APP_DEST[neovim]}" != "skip" && -n "${APP_DEST[neovim]}" ]]; then
    print ""
    if _ui_confirm_yes "Install NvChad config for Neovim?"; then
      FEAT_NVCHAD=true
    else
      FEAT_NVCHAD=false
    fi
  fi
}

# ------------------------------------------------------------------------------
# _apps_render
# Draw the numbered app list with current placement + recommendation
# ------------------------------------------------------------------------------
_apps_render() {
  _ui_banner
  _ui_step "1" "App Selection"

  print -P "  ${UI_DIM}Pick where each app installs. Tap a number to cycle:"
  print -P "  GOINFREE → SESSION → SKIP${UI_RESET}"
  print ""
  print -P "  ${UI_TAG_GOINFREE}[GOINFREE]${UI_RESET} ${UI_DIM}= machine-local, fast, auto-restored on login${UI_RESET}"
  print -P "  ${UI_TAG_SESSION}[SESSION] ${UI_RESET} ${UI_DIM}= network home, persistent (use for apps needing permissions)${UI_RESET}"
  print ""

  local i=1
  for app_id in $APP_ORDER; do
    local name dest rec reason
    name=$(install_get_manifest_field "$app_id" "name")
    dest=${APP_DEST[$app_id]:-skip}
    rec=${APP_RECOMMENDED[$app_id]:-goinfree}
    reason=$(install_get_manifest_field "$app_id" "reason")

    # Padded number
    printf "  ${UI_BOLD}%2d)${UI_RESET}  " $i

    # Placement tag
    _ui_placement_tag "$dest"
    print -n "  "

    # App name, padded to 18 chars
    printf "%-18s" "$name"

    # Reason / recommended note
    if [[ -n "$reason" ]]; then
      print -P " ${UI_DIM}— $reason${UI_RESET}"
    else
      print -P " ${UI_DIM}— recommended $rec${UI_RESET}"
    fi

    ((i++))
  done

  print ""
  print -P "  ${UI_DIM}[a] accept all recommended   [g] all goinfree   [s] skip all   [d] done${UI_RESET}"
}

# ------------------------------------------------------------------------------
# _apps_handle_number <num>
# Cycle the placement of the Nth app
# ------------------------------------------------------------------------------
_apps_handle_number() {
  local n=$1
  if (( n < 1 || n > ${#APP_ORDER[@]} )); then
    _ui_warn "Number out of range"
    sleep 1
    return
  fi
  local app_id=${APP_ORDER[$n]}
  state_cycle_app "$app_id"
}

# ------------------------------------------------------------------------------
# _apps_set_all <dest>
# Set every app to the given destination
# ------------------------------------------------------------------------------
_apps_set_all() {
  local dest=$1
  for app_id in $APP_ORDER; do
    APP_DEST[$app_id]=$dest
  done
}
