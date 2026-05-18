#!/usr/bin/env zsh
# =============================================================================
# lib/ui.zsh — All visual output lives here
# Every other file sources this. Nothing else should print directly.
# =============================================================================

# ------------------------------------------------------------------------------
# Colors & styles
# ------------------------------------------------------------------------------
UI_RESET='\033[0m'
UI_BOLD='\033[1m'
UI_DIM='\033[2m'

UI_RED='\033[0;31m'
UI_GREEN='\033[0;32m'
UI_YELLOW='\033[0;33m'
UI_BLUE='\033[0;34m'
UI_CYAN='\033[0;36m'
UI_WHITE='\033[0;37m'

# Placement tag colors — used in app picker
UI_TAG_GOINFREE='\033[0;33m'   # yellow  — temporary, machine-local
UI_TAG_SESSION='\033[0;32m'    # green   — persistent, network home

# ------------------------------------------------------------------------------
# Status symbols
# ------------------------------------------------------------------------------
SYM_OK="${UI_GREEN}✔${UI_RESET}"
SYM_ERR="${UI_RED}✘${UI_RESET}"
SYM_WARN="${UI_YELLOW}⚠${UI_RESET}"
SYM_INFO="${UI_CYAN}→${UI_RESET}"
SYM_SKIP="${UI_DIM}–${UI_RESET}"

# ------------------------------------------------------------------------------
# _ui_clear
# Clear screen without wiping scrollback
# ------------------------------------------------------------------------------
_ui_clear() {
  printf '\033[2J\033[H'
}

# ------------------------------------------------------------------------------
# _ui_banner
# Print the top-of-screen header on every wizard step
# ------------------------------------------------------------------------------
_ui_banner() {
  _ui_clear
  print -P "${UI_BOLD}${UI_CYAN}"
  print "  ╔══════════════════════════════════════╗"
  print "  ║         mac-setup  //  wizard        ║"
  print "  ╚══════════════════════════════════════╝"
  print -P "${UI_RESET}"
}

# ------------------------------------------------------------------------------
# _ui_step <number> <title>
# Print a step header — called at the top of each module
# ------------------------------------------------------------------------------
_ui_step() {
  local num=$1 title=$2
  print ""
  print -P "  ${UI_BOLD}${UI_BLUE}[$num]${UI_RESET}  ${UI_BOLD}$title${UI_RESET}"
  print -P "  ${UI_DIM}$(printf '─%.0s' {1..40})${UI_RESET}"
  print ""
}

# ------------------------------------------------------------------------------
# _ui_success / _ui_error / _ui_warn / _ui_info / _ui_skip
# Single-line status printers
# ------------------------------------------------------------------------------
_ui_success() { print -P "  $SYM_OK  $*" }
_ui_error()   { print -P "  $SYM_ERR  ${UI_RED}$*${UI_RESET}" }
_ui_warn()    { print -P "  $SYM_WARN  ${UI_YELLOW}$*${UI_RESET}" }
_ui_info()    { print -P "  $SYM_INFO  $*" }
_ui_skip()    { print -P "  $SYM_SKIP  ${UI_DIM}$*${UI_RESET}" }

# ------------------------------------------------------------------------------
# _ui_confirm <question>
# Returns 0 (yes) or 1 (no). Default is No.
# Usage: if _ui_confirm "Delete files?"; then ...
# ------------------------------------------------------------------------------
_ui_confirm() {
  local prompt="${1:-Are you sure?}"
  local reply
  print -n -P "  ${UI_BOLD}$prompt${UI_RESET} ${UI_DIM}[y/N]${UI_RESET} "
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# ------------------------------------------------------------------------------
# _ui_confirm_default_yes <question>
# Same but default is Yes.
# ------------------------------------------------------------------------------
_ui_confirm_yes() {
  local prompt="${1:-Continue?}"
  local reply
  print -n -P "  ${UI_BOLD}$prompt${UI_RESET} ${UI_DIM}[Y/n]${UI_RESET} "
  read -r reply
  [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]
}

# ------------------------------------------------------------------------------
# _ui_prompt <varname> <question> [default]
# Read a string into a variable. If user hits enter, uses default.
# Usage: _ui_prompt myvar "Enter name" "John"
# ------------------------------------------------------------------------------
_ui_prompt() {
  local varname=$1 question=$2 default=${3:-""}
  local hint=""
  [[ -n "$default" ]] && hint=" ${UI_DIM}(default: $default)${UI_RESET}"
  print -n -P "  ${UI_BOLD}$question${UI_RESET}$hint: "
  read -r $varname
  # If empty, assign default
  [[ -z "${(P)varname}" && -n "$default" ]] && eval "$varname='$default'"
}

# ------------------------------------------------------------------------------
# _ui_spinner <message> <command...>
# Runs a command in the background while showing an animated spinner.
# Returns the exit code of the command.
# Usage: _ui_spinner "Downloading Firefox" curl -fsSL ...
# ------------------------------------------------------------------------------
_ui_spinner() {
  local msg=$1; shift
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local i=0

  # Run command in background, suppress output (caller handles errors)
  "$@" &>/tmp/mac-setup-spinner.log &
  local pid=$!

  while kill -0 "$pid" 2>/dev/null; do
    printf "\r  ${UI_CYAN}%s${UI_RESET}  %s  " "${frames[$((i % ${#frames[@]} + 1))]}" "$msg"
    ((i++))
    sleep 0.08
  done

  wait "$pid"
  local exit_code=$?

  if (( exit_code == 0 )); then
    printf "\r  $SYM_OK  %s\n" "$msg"
  else
    printf "\r  $SYM_ERR  %s ${UI_DIM}(see $LOG_FILE)${UI_RESET}\n" "$msg"
    cat /tmp/mac-setup-spinner.log >> "$LOG_FILE" 2>/dev/null
  fi

  return $exit_code
}

# ------------------------------------------------------------------------------
# _ui_placement_tag <dest>
# Print a colored [GOINFREE] or [SESSION] tag inline
# ------------------------------------------------------------------------------
_ui_placement_tag() {
  case $1 in
    goinfree) print -P -n "${UI_TAG_GOINFREE}[GOINFREE]${UI_RESET}" ;;
    session)  print -P -n "${UI_TAG_SESSION}[SESSION] ${UI_RESET}"  ;;
    skip)     print -P -n "${UI_DIM}[SKIP]    ${UI_RESET}"          ;;
  esac
}

# ------------------------------------------------------------------------------
# _ui_divider
# Thin horizontal rule for separating sections
# ------------------------------------------------------------------------------
_ui_divider() {
  print -P "  ${UI_DIM}$(printf '─%.0s' {1..40})${UI_RESET}"
}

# ------------------------------------------------------------------------------
# _ui_section <title>
# A lighter header for subsections within a step
# ------------------------------------------------------------------------------
_ui_section() {
  print ""
  print -P "  ${UI_BOLD}$1${UI_RESET}"
  print ""
}

# ------------------------------------------------------------------------------
# _ui_pause
# Wait for any keypress before continuing — used at end of steps
# ------------------------------------------------------------------------------
_ui_pause() {
  local msg="${1:-Press any key to continue...}"
  print ""
  print -P "  ${UI_DIM}$msg${UI_RESET}"
  read -rsk 1
}
