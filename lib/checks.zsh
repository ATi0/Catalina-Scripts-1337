#!/usr/bin/env zsh
# =============================================================================
# lib/checks.zsh — Preflight checks before wizard runs
# Dependencies: config.zsh, lib/ui.zsh
# =============================================================================

# ------------------------------------------------------------------------------
# checks_run_all
# Run every check. Aborts script if anything critical fails.
# ------------------------------------------------------------------------------
checks_run_all() {
  _ui_step "0" "Preflight checks"

  _check_macos_version  || exit 1
  _check_goinfree       || exit 1
  _check_session_dir    || exit 1
  _check_python3        || exit 1
  _check_repo_reachable || exit 1
  _check_disk_space

  _ui_success "All checks passed"
  print ""
}

# ------------------------------------------------------------------------------
# _check_macos_version — must be ≥ 10.15
# ------------------------------------------------------------------------------
_check_macos_version() {
  local version major minor
  version=$(sw_vers -productVersion)
  major=${version%%.*}
  minor=${${version#*.}%%.*}

  if (( major < 10 )) || (( major == 10 && minor < 15 )); then
    _ui_error "macOS 10.15+ required (you have $version)"
    return 1
  fi
  _ui_success "macOS $version"
  return 0
}

# ------------------------------------------------------------------------------
# _check_goinfree — /goinfree/$USER must exist and be writable
# ------------------------------------------------------------------------------
_check_goinfree() {
  local base="/goinfree/$USER"
  if [[ ! -d "$base" ]]; then
    _ui_warn "/goinfree/$USER does not exist — creating it"
    if ! mkdir -p "$base" 2>/dev/null; then
      _ui_error "Could not create $base — goinfree apps will fail"
      return 1
    fi
  fi
  if [[ ! -w "$base" ]]; then
    _ui_error "$base is not writable"
    return 1
  fi
  mkdir -p "$GOINFREE_DIR"
  _ui_success "Goinfree directory ready ($GOINFREE_DIR)"
  return 0
}

# ------------------------------------------------------------------------------
# _check_session_dir — ~/Applications must be writable
# ------------------------------------------------------------------------------
_check_session_dir() {
  mkdir -p "$SESSION_DIR" 2>/dev/null
  if [[ ! -w "$SESSION_DIR" ]]; then
    _ui_error "$SESSION_DIR is not writable"
    return 1
  fi
  _ui_success "Session directory ready ($SESSION_DIR)"
  return 0
}

# ------------------------------------------------------------------------------
# _check_python3 — needed for parsing manifest.json
# ------------------------------------------------------------------------------
_check_python3() {
  if ! command -v python3 &>/dev/null; then
    _ui_error "python3 not found — install Xcode Command Line Tools:"
    _ui_error "  xcode-select --install"
    return 1
  fi
  _ui_success "python3 available"
  return 0
}

# ------------------------------------------------------------------------------
# _check_repo_reachable — HEAD request to manifest.json
# ------------------------------------------------------------------------------
_check_repo_reachable() {
  local manifest_url="$APP_REPO_URL/manifest.json"
  local curl_args=(-fsI --max-time 10)
  [[ -n "$REPO_TOKEN" ]] && curl_args+=(--header "PRIVATE-TOKEN: $REPO_TOKEN")

  if ! curl "${curl_args[@]}" "$manifest_url" &>/dev/null; then
    _ui_error "App repo unreachable: $APP_REPO_URL"
    _ui_error "Check APP_REPO_URL and REPO_TOKEN in config.zsh"
    return 1
  fi
  _ui_success "App repo reachable"
  return 0
}

# ------------------------------------------------------------------------------
# _check_disk_space — warn if /goinfree has <2GB free (not fatal)
# ------------------------------------------------------------------------------
_check_disk_space() {
  local free_kb
  free_kb=$(df -k "/goinfree/$USER" 2>/dev/null | awk 'NR==2 {print $4}')
  if [[ -n "$free_kb" ]] && (( free_kb < 2000000 )); then
    _ui_warn "Less than 2GB free on /goinfree — installs may fail"
  fi
}

# ------------------------------------------------------------------------------
# checks_ensure_setup_home — create ~/.mac-setup/ if missing
# ------------------------------------------------------------------------------
checks_ensure_setup_home() {
  mkdir -p "$SETUP_HOME"
  : > "$LOG_FILE"
}
