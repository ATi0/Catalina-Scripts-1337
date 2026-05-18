#!/usr/bin/env zsh
# =============================================================================
# modules/02_discord_patch.zsh — Vencord injection
# Only runs if Discord is selected. Patches Discord with Vencord and applies
# a recommended-plugins config pulled from the app repo.
# Dependencies: config.zsh, lib/ui.zsh, lib/install.zsh
# =============================================================================

# ------------------------------------------------------------------------------
# module_discord_patch
# Asks user if they want Vencord. Sets FEAT_VENCORD. Actual patching happens
# during the install phase via discord_patch_apply.
# ------------------------------------------------------------------------------
module_discord_patch() {
  # Only relevant if Discord is being installed
  if [[ "${APP_DEST[discord]:-skip}" == "skip" ]]; then
    FEAT_VENCORD=false
    return 0
  fi

  _ui_step "2" "Discord — Vencord Patch"

  print -P "  ${UI_DIM}Vencord is a Discord mod that adds plugins, themes, and QoL features.${UI_RESET}"
  print ""

  if _ui_confirm_yes "Patch Discord with Vencord?"; then
    FEAT_VENCORD=true
    _ui_success "Vencord will be installed"
  else
    FEAT_VENCORD=false
    _ui_skip "Vencord skipped"
  fi
}

# ------------------------------------------------------------------------------
# discord_patch_apply
# Called during install phase if FEAT_VENCORD=true.
# Downloads VencordInstallerCli from the app repo, runs it against Discord,
# then writes the recommended plugins config.
# ------------------------------------------------------------------------------
discord_patch_apply() {
  [[ "$FEAT_VENCORD" != "true" ]] && return 0

  local discord_dest
  case "${APP_DEST[discord]}" in
    goinfree) discord_dest=$GOINFREE_DIR ;;
    session)  discord_dest=$SESSION_DIR  ;;
    *)        _ui_skip "Discord not installed — skipping Vencord" ; return 0 ;;
  esac

  local discord_path
  discord_path=$(install_get_app_path "discord" "$discord_dest")

  if [[ ! -d "$discord_path" ]]; then
    _ui_error "Discord.app not found at $discord_path"
    return 1
  fi

  # Download Vencord CLI installer from the app repo
  local installer_url="$APP_REPO_URL/VencordInstallerCli"
  local installer="/tmp/VencordInstallerCli"

  _ui_spinner "Downloading Vencord installer" _install_curl "$installer_url" "$installer"
  [[ $? -ne 0 ]] && { _ui_error "Could not fetch Vencord installer"; return 1; }

  chmod +x "$installer"

  # Run the installer in headless mode against the Discord path
  _ui_spinner "Patching Discord with Vencord" "$installer" -install -branch stable -location "$discord_path"
  local rc=$?
  rm -f "$installer"

  if [[ $rc -ne 0 ]]; then
    _ui_error "Vencord patch failed (see $LOG_FILE)"
    return 1
  fi

  # Write recommended plugins config
  _vencord_apply_plugins

  _ui_success "Vencord installed"
}

# ------------------------------------------------------------------------------
# _vencord_apply_plugins
# Pull recommended-plugins.json from app repo, write to Vencord settings dir
# ------------------------------------------------------------------------------
_vencord_apply_plugins() {
  local plugins_dir="$HOME/Library/Application Support/Vencord/settings"
  local settings_file="$plugins_dir/settings.json"
  local remote_url="$APP_REPO_URL/vencord-plugins.json"

  mkdir -p "$plugins_dir"

  if _install_curl "$remote_url" "$settings_file" 2>/dev/null; then
    _ui_success "Vencord plugins applied"
  else
    _ui_warn "Could not fetch plugins config — Vencord will use defaults"
  fi
}
