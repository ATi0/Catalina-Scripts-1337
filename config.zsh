#!/usr/bin/env zsh
# =============================================================================
# config.zsh — Global configuration (hand-edit this file)
# =============================================================================

# ------------------------------------------------------------------------------
# App repo — GitLab Generic Package Registry URL
# Format: https://gitlab.com/<group>/<project>/-/packages/generic/<package>/<version>
# ------------------------------------------------------------------------------
APP_REPO_URL="https://gitlab.com/1337-mac-scripts/mac-apps/-/packages/generic/apps/v1.0"

# Set to your GitLab personal access token if the repo is private.
# Leave empty if the repo is public.
REPO_TOKEN=""

# ------------------------------------------------------------------------------
# Install roots
# ------------------------------------------------------------------------------
GOINFREE_DIR="/goinfree/$USER/Applications"   # fast, local, machine-specific
SESSION_DIR="$HOME/Applications"              # network home, persistent

# ------------------------------------------------------------------------------
# Persistent setup dir — lives on network home, follows the user
# ------------------------------------------------------------------------------
SETUP_HOME="$HOME/.mac-setup"
LOG_FILE="$SETUP_HOME/restore.log"
STATE_FILE="$SETUP_HOME/state.zsh"
