#!/usr/bin/env zsh
# =============================================================================
# modules/03_darkmode.zsh — Enable dark mode on login
# Sets dark mode now, and installs a LaunchAgent that enforces it on every login.
# Dependencies: config.zsh, lib/ui.zsh
# =============================================================================

DARKMODE_AGENT_LABEL="com.user.mac-darkmode"
DARKMODE_AGENT_PLIST="$HOME/Library/LaunchAgents/${DARKMODE_AGENT_LABEL}.plist"

# ------------------------------------------------------------------------------
# module_darkmode
# Ask user if they want dark mode enabled on every login.
# ------------------------------------------------------------------------------
module_darkmode() {
  _ui_step "3" "Dark Mode"

  if _ui_confirm_yes "Enable dark mode automatically on every login?"; then
    FEAT_DARKMODE=true
    _ui_success "Dark mode will be enforced on login"
  else
    FEAT_DARKMODE=false
    _ui_skip "Dark mode not enforced"
  fi
}

# ------------------------------------------------------------------------------
# darkmode_apply
# Run during install phase: enables dark mode now + writes LaunchAgent.
# ------------------------------------------------------------------------------
darkmode_apply() {
  [[ "$FEAT_DARKMODE" != "true" ]] && return 0

  # Set dark mode immediately
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null

  # Write LaunchAgent to enforce it on every login
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$DARKMODE_AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${DARKMODE_AGENT_LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/osascript</string>
    <string>-e</string>
    <string>tell application "System Events" to tell appearance preferences to set dark mode to true</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF

  # Reload (unload first, ignoring errors, then load fresh)
  launchctl unload "$DARKMODE_AGENT_PLIST" 2>/dev/null
  launchctl load "$DARKMODE_AGENT_PLIST" 2>/dev/null

  _ui_success "Dark mode enabled and enforced on login"
}
