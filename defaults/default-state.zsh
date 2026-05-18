#!/usr/bin/env zsh
# =============================================================================
# defaults/default-state.zsh — Curated preset configuration
# Loaded when user picks "Default" instead of "Custom" at startup.
# Edit this to change what the default install does.
# =============================================================================

typeset -gA APP_DEST

# --- goinfree apps (machine-local, fast) ---
APP_DEST[firefox]="goinfree"
APP_DEST[vscode]="goinfree"
APP_DEST[discord]="goinfree"
APP_DEST[spotify]="goinfree"
APP_DEST[neovim]="goinfree"
APP_DEST[alacritty]="goinfree"
APP_DEST[python]="goinfree"

# --- session apps (network home, need permissions tied to install path) ---
APP_DEST[alfred]="session"
APP_DEST[rectangle]="session"
APP_DEST[maccy]="session"
APP_DEST[stats]="session"
APP_DEST[unarchiver]="session"
APP_DEST[forklift]="session"

# --- features ---
FEAT_VENCORD=true
FEAT_DARKMODE=true
FEAT_FIREFOX_PROFILE=true
FEAT_FIREFOX_DOWNGRADE=true
FEAT_PYTHON_VSCODE=true
FEAT_NVCHAD=true
