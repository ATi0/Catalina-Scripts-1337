#!/usr/bin/env zsh
# =============================================================================
# agent/restore.zsh — Runs on every login via LaunchAgent
# Silently restores any missing goinfree apps based on the user's saved state.
# This file lives in ~/.mac-setup/agent/ after install.
# =============================================================================

# Source from the persistent setup home (NOT the original scripts repo,
# which may not be on this machine).
SETUP_HOME="$HOME/.mac-setup"

source "$SETUP_HOME/config.zsh"     || exit 1
source "$SETUP_HOME/lib/ui.zsh"     || exit 1
source "$SETUP_HOME/lib/install.zsh" || exit 1

# Load state — if there's no state yet, nothing to do
[[ ! -f "$SETUP_HOME/state.zsh" ]] && exit 0
source "$SETUP_HOME/state.zsh"

# Ensure log file exists
mkdir -p "$(dirname "$LOG_FILE")"
exec >> "$LOG_FILE" 2>&1

print ""
print "===== restore @ $(date) ====="

# Ensure target directory exists
mkdir -p "$GOINFREE_DIR"

# Iterate over every app in state, restore any missing goinfree apps
for app_id dest in ${(kv)APP_DEST}; do
  [[ "$dest" != "goinfree" ]] && continue

  if app_is_installed "$app_id" "$GOINFREE_DIR"; then
    print "[$app_id] already installed, skipping"
    continue
  fi

  print "[$app_id] missing — installing"
  if app_install "$app_id" "$GOINFREE_DIR"; then
    print "[$app_id] OK"
  else
    print "[$app_id] FAILED"
  fi
done

print "===== restore done ====="
