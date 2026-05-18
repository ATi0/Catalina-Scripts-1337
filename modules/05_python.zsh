#!/usr/bin/env zsh
# =============================================================================
# modules/05_python.zsh — Wire VSCode to use the freshly installed Python
# Python itself is installed via app_install in the apps module (id: "python").
# Dependencies: config.zsh, lib/ui.zsh, lib/install.zsh
# =============================================================================

VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"

# ------------------------------------------------------------------------------
# module_python
# Asks if user wants VSCode pointed at the new Python.
# Only relevant if both Python and VSCode are selected.
# ------------------------------------------------------------------------------
module_python() {
  local has_py="${APP_DEST[python]:-skip}"
  local has_vs="${APP_DEST[vscode]:-skip}"

  if [[ "$has_py" == "skip" || "$has_vs" == "skip" ]]; then
    FEAT_PYTHON_VSCODE=false
    return 0
  fi

  _ui_step "5" "Python + VSCode"

  if _ui_confirm_yes "Point VSCode at the newly-installed Python?"; then
    FEAT_PYTHON_VSCODE=true
  else
    FEAT_PYTHON_VSCODE=false
  fi
}

# ------------------------------------------------------------------------------
# python_apply
# Edit VSCode settings.json to set python.defaultInterpreterPath.
# ------------------------------------------------------------------------------
python_apply() {
  [[ "$FEAT_PYTHON_VSCODE" != "true" ]] && return 0

  # Resolve install dest
  local py_dest
  case "${APP_DEST[python]}" in
    goinfree) py_dest=$GOINFREE_DIR ;;
    session)  py_dest=$SESSION_DIR  ;;
    *)        return 0 ;;
  esac

  local py_app
  py_app=$(install_get_app_path "python" "$py_dest")

  # Find the python3 binary inside the .app
  local py_bin
  py_bin=$(find "$py_app/Contents" -type f -name "python3" 2>/dev/null | head -1)

  if [[ -z "$py_bin" ]]; then
    _ui_warn "Could not locate python3 inside $py_app"
    return 1
  fi

  # Merge into VSCode settings.json
  mkdir -p "${VSCODE_SETTINGS:h}"
  [[ ! -f "$VSCODE_SETTINGS" ]] && print "{}" > "$VSCODE_SETTINGS"

  python3 - <<EOF
import json
path = "$VSCODE_SETTINGS"
try:
    with open(path) as f:
        data = json.load(f)
except Exception:
    data = {}
data["python.defaultInterpreterPath"] = "$py_bin"
with open(path, "w") as f:
    json.dump(data, f, indent=2)
EOF

  _ui_success "VSCode pointed at $py_bin"
}
