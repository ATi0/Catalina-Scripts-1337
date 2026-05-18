#!/usr/bin/env zsh
# =============================================================================
# mac-setup.sh — Entry point
# Run from the cloned scripts repo: ./mac-setup.sh
# =============================================================================

# Resolve the directory this script lives in
SCRIPT_DIR="${0:A:h}"
cd "$SCRIPT_DIR" || exit 1

# -----------------------------------------------------------------------------
# Source everything in dependency order
# -----------------------------------------------------------------------------
source "$SCRIPT_DIR/config.zsh"
source "$SCRIPT_DIR/lib/ui.zsh"
source "$SCRIPT_DIR/lib/install.zsh"
source "$SCRIPT_DIR/lib/state.zsh"
source "$SCRIPT_DIR/lib/checks.zsh"

source "$SCRIPT_DIR/modules/01_apps.zsh"
source "$SCRIPT_DIR/modules/02_discord_patch.zsh"
source "$SCRIPT_DIR/modules/03_darkmode.zsh"
source "$SCRIPT_DIR/modules/04_firefox.zsh"
source "$SCRIPT_DIR/modules/05_python.zsh"
source "$SCRIPT_DIR/modules/06_storage.zsh"

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
main() {
  _ui_banner
  checks_ensure_setup_home
  checks_run_all

  state_init
  _install_fetch_manifest
  state_populate_recommendations

  _menu_install_type

  _menu_review_screen

  _run_install_phase

  _install_persistent_agent

  _final_summary
}

# -----------------------------------------------------------------------------
# _menu_install_type
# Asks: default or custom? Default skips the wizard.
# -----------------------------------------------------------------------------
_menu_install_type() {
  _ui_banner
  print -P "  ${UI_BOLD}How do you want to install?${UI_RESET}"
  print ""
  print -P "  ${UI_BOLD}1)${UI_RESET}  Default  ${UI_DIM}— curated preset, skip the wizard${UI_RESET}"
  print -P "  ${UI_BOLD}2)${UI_RESET}  Custom   ${UI_DIM}— full interactive wizard${UI_RESET}"
  print -P "  ${UI_BOLD}q)${UI_RESET}  Quit"
  print ""
  print -n -P "  ${UI_BOLD}>${UI_RESET} "

  local choice
  read -r choice
  case "$choice" in
    1) _load_default_state ;;
    2) _run_wizard         ;;
    q|Q) exit 0            ;;
    *)   _menu_install_type ;;
  esac
}

# -----------------------------------------------------------------------------
# _load_default_state
# Sources defaults/default-state.zsh on top of the initialized state.
# -----------------------------------------------------------------------------
_load_default_state() {
  source "$SCRIPT_DIR/defaults/default-state.zsh"
  _ui_success "Default configuration loaded"
  sleep 1
}

# -----------------------------------------------------------------------------
# _run_wizard
# Walk through every module in order.
# -----------------------------------------------------------------------------
_run_wizard() {
  module_apps
  module_discord_patch
  module_darkmode
  module_firefox
  module_python
  # Storage is interactive cleanup — offered at end, not now
}

# -----------------------------------------------------------------------------
# _menu_review_screen
# Show every choice, let user jump back to any step.
# -----------------------------------------------------------------------------
_menu_review_screen() {
  while true; do
    _ui_banner
    _ui_step "★" "Review"

    print -P "  ${UI_BOLD}Apps:${UI_RESET}"
    for app_id in $(install_list_app_ids); do
      local name dest
      name=$(install_get_manifest_field "$app_id" "name")
      dest=${APP_DEST[$app_id]:-skip}
      printf "    "
      _ui_placement_tag "$dest"
      printf "  %s\n" "$name"
    done

    print ""
    print -P "  ${UI_BOLD}Features:${UI_RESET}"
    _review_flag "Vencord (Discord patch)"    "$FEAT_VENCORD"
    _review_flag "Dark mode on login"         "$FEAT_DARKMODE"
    _review_flag "Firefox profile cleanup"    "$FEAT_FIREFOX_PROFILE"
    _review_flag "Firefox downgrade fix"      "$FEAT_FIREFOX_DOWNGRADE"
    _review_flag "Wire VSCode → Python"       "$FEAT_PYTHON_VSCODE"
    _review_flag "NvChad config for Neovim"   "$FEAT_NVCHAD"

    print ""
    print -P "  ${UI_DIM}[1] redo apps  [2] redo discord  [3] redo darkmode${UI_RESET}"
    print -P "  ${UI_DIM}[4] redo firefox  [5] redo python  [ENTER] confirm & install${UI_RESET}"
    print ""
    print -n -P "  ${UI_BOLD}>${UI_RESET} "

    local choice
    read -r choice
    case "$choice" in
      1) module_apps ;;
      2) module_discord_patch ;;
      3) module_darkmode ;;
      4) module_firefox ;;
      5) module_python ;;
      "") break ;;
      *) _ui_warn "Unknown" ; sleep 1 ;;
    esac
  done
}

# -----------------------------------------------------------------------------
# _review_flag <label> <value>
# Print a flag with green ON / dim OFF
# -----------------------------------------------------------------------------
_review_flag() {
  local label=$1 val=$2
  if [[ "$val" == "true" ]]; then
    print -P "    ${UI_GREEN}ON ${UI_RESET}  $label"
  else
    print -P "    ${UI_DIM}OFF  $label${UI_RESET}"
  fi
}

# -----------------------------------------------------------------------------
# _run_install_phase
# Execute the actual installs based on confirmed state.
# -----------------------------------------------------------------------------
_run_install_phase() {
  _ui_banner
  _ui_step "▶" "Installing"

  state_save
  _ui_success "State saved to $STATE_FILE"
  print ""

  local failed=()

  # Install apps
  for app_id in $(install_list_app_ids); do
    local dest_label=${APP_DEST[$app_id]:-skip}
    local dest_dir

    case "$dest_label" in
      goinfree) dest_dir=$GOINFREE_DIR ;;
      session)  dest_dir=$SESSION_DIR  ;;
      skip)     _ui_skip "$(install_get_manifest_field $app_id name)" ; continue ;;
    esac

    if ! app_install "$app_id" "$dest_dir"; then
      failed+=("$app_id")
    fi
  done

  # Post-install actions
  print ""
  _ui_section "Post-install"

  discord_patch_apply  || failed+=("discord-patch")
  darkmode_apply       || failed+=("darkmode")
  firefox_apply        || failed+=("firefox")
  python_apply         || failed+=("python-vscode")
  _nvchad_apply        || failed+=("nvchad")

  # Store failures for the summary
  INSTALL_FAILED=("${failed[@]}")
}

# -----------------------------------------------------------------------------
# _nvchad_apply
# Clone NvChad into ~/.config/nvim if FEAT_NVCHAD=true
# -----------------------------------------------------------------------------
_nvchad_apply() {
  [[ "$FEAT_NVCHAD" != "true" ]] && return 0

  local nvim_cfg="$HOME/.config/nvim"
  if [[ -d "$nvim_cfg" ]]; then
    _ui_warn "$nvim_cfg already exists — skipping NvChad install"
    return 0
  fi

  _ui_spinner "Cloning NvChad" git clone --depth 1 https://github.com/NvChad/NvChad "$nvim_cfg"
}

# -----------------------------------------------------------------------------
# _install_persistent_agent
# Copy lib + agent + state into ~/.mac-setup/ and register LaunchAgent.
# This is what allows restore.zsh to run on any future machine login.
# -----------------------------------------------------------------------------
_install_persistent_agent() {
  _ui_section "Setting up login agent"

  mkdir -p "$SETUP_HOME/lib" "$SETUP_HOME/agent"

  cp "$SCRIPT_DIR/config.zsh"          "$SETUP_HOME/config.zsh"
  cp "$SCRIPT_DIR/lib/ui.zsh"          "$SETUP_HOME/lib/ui.zsh"
  cp "$SCRIPT_DIR/lib/install.zsh"     "$SETUP_HOME/lib/install.zsh"
  cp "$SCRIPT_DIR/agent/restore.zsh"   "$SETUP_HOME/agent/restore.zsh"

  chmod +x "$SETUP_HOME/agent/restore.zsh"

  # Build the LaunchAgent plist from the template
  local plist_target="$HOME/Library/LaunchAgents/com.user.mac-restore.plist"
  mkdir -p "$HOME/Library/LaunchAgents"

  sed -e "s|__RESTORE_SCRIPT__|$SETUP_HOME/agent/restore.zsh|g" \
      -e "s|__LOG_FILE__|$LOG_FILE|g" \
      "$SCRIPT_DIR/agent/com.user.mac-restore.plist" \
      > "$plist_target"

  # Reload it
  launchctl unload "$plist_target" 2>/dev/null
  launchctl load "$plist_target" 2>/dev/null

  _ui_success "Login agent installed — goinfree apps will auto-restore on new machines"
}

# -----------------------------------------------------------------------------
# _final_summary
# Print what worked / what didn't. Offer to run the storage cleaner.
# -----------------------------------------------------------------------------
_final_summary() {
  print ""
  _ui_divider

  if (( ${#INSTALL_FAILED[@]} == 0 )); then
    _ui_success "All steps completed successfully"
  else
    _ui_warn "Some steps failed:"
    for item in $INSTALL_FAILED; do
      print -P "    ${UI_RED}✘${UI_RESET}  $item"
    done
    print ""
    _ui_info "See $LOG_FILE for details"
  fi

  print ""
  if _ui_confirm "Run the storage cleaner now?"; then
    module_storage
  fi

  print ""
  _ui_success "Done. You can re-run this script at any time."
  print ""
}

# -----------------------------------------------------------------------------
# Run
# -----------------------------------------------------------------------------
main "$@"
