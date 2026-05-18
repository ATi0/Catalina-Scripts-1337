#!/usr/bin/env zsh
# =============================================================================
# modules/04_firefox.zsh — Firefox profile cleanup + downgrade fix
# Dependencies: config.zsh, lib/ui.zsh
# =============================================================================

FIREFOX_DIR="$HOME/Library/Application Support/Firefox"
FIREFOX_PROFILES_INI="$FIREFOX_DIR/profiles.ini"

# ------------------------------------------------------------------------------
# module_firefox
# Asks about profile cleanup + downgrade fix.
# ------------------------------------------------------------------------------
module_firefox() {
  _ui_step "4" "Firefox"

  # Skip if Firefox isn't installed/selected
  if [[ "${APP_DEST[firefox]:-skip}" == "skip" && ! -f "$FIREFOX_PROFILES_INI" ]]; then
    _ui_skip "Firefox not selected and no existing profile — skipping"
    return 0
  fi

  if _ui_confirm_yes "Auto-select the most recent profile and remove old ones?"; then
    FEAT_FIREFOX_PROFILE=true
  else
    FEAT_FIREFOX_PROFILE=false
  fi

  if _ui_confirm_yes "Fix 'profile too new' errors on every launch?"; then
    FEAT_FIREFOX_DOWNGRADE=true
  else
    FEAT_FIREFOX_DOWNGRADE=false
  fi
}

# ------------------------------------------------------------------------------
# firefox_apply
# Runs during install phase.
# ------------------------------------------------------------------------------
firefox_apply() {
  if [[ ! -f "$FIREFOX_PROFILES_INI" ]]; then
    _ui_skip "No Firefox profile found — nothing to fix"
    return 0
  fi

  [[ "$FEAT_FIREFOX_PROFILE" == "true" ]]    && _firefox_fix_profiles
  [[ "$FEAT_FIREFOX_DOWNGRADE" == "true" ]]  && _firefox_fix_downgrade
}

# ------------------------------------------------------------------------------
# _firefox_fix_profiles
# Find most-recently-modified profile, set it as default, delete the rest.
# ------------------------------------------------------------------------------
_firefox_fix_profiles() {
  local profiles_root="$FIREFOX_DIR/Profiles"
  [[ ! -d "$profiles_root" ]] && return 0

  # Find the most recently modified profile directory
  local newest
  newest=$(ls -1td "$profiles_root"/*/ 2>/dev/null | head -1)
  if [[ -z "$newest" ]]; then
    _ui_warn "No profiles found in $profiles_root"
    return 0
  fi
  newest=${newest%/}                          # strip trailing slash
  local newest_name=${newest:t}               # basename

  _ui_info "Keeping profile: $newest_name"

  # Rewrite profiles.ini to set newest as default
  python3 - <<EOF
import configparser, os
ini_path = "$FIREFOX_PROFILES_INI"
newest = "Profiles/$newest_name"

cfg = configparser.ConfigParser()
cfg.read(ini_path)

# Clear out existing Profile sections, write a fresh one
for section in list(cfg.sections()):
    if section.startswith("Profile"):
        cfg.remove_section(section)

cfg["Profile0"] = {
    "Name": "default",
    "IsRelative": "1",
    "Path": newest,
    "Default": "1",
}

# Update Install section if present
for section in cfg.sections():
    if section.startswith("Install"):
        cfg[section]["Default"] = newest
        cfg[section]["Locked"] = "1"

with open(ini_path, "w") as f:
    cfg.write(f, space_around_delimiters=False)
EOF

  # Delete every profile dir except the newest
  for dir in "$profiles_root"/*/; do
    [[ "${dir%/}" != "$newest" ]] && rm -rf "$dir"
  done

  _ui_success "Old Firefox profiles removed"
}

# ------------------------------------------------------------------------------
# _firefox_fix_downgrade
# Removes compatibility.ini files which trigger the "profile too new" error.
# Also adds a LaunchAgent that re-removes them on every login.
# ------------------------------------------------------------------------------
_firefox_fix_downgrade() {
  local profiles_root="$FIREFOX_DIR/Profiles"

  # Remove now
  find "$profiles_root" -name "compatibility.ini" -delete 2>/dev/null

  # Install LaunchAgent to remove on every login
  local label="com.user.firefox-downgrade"
  local plist="$HOME/Library/LaunchAgents/${label}.plist"

  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${label}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>-c</string>
    <string>find "$profiles_root" -name compatibility.ini -delete</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF

  launchctl unload "$plist" 2>/dev/null
  launchctl load "$plist" 2>/dev/null

  _ui_success "Firefox downgrade fix installed"
}
