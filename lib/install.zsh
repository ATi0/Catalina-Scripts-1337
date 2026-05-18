#!/usr/bin/env zsh
# =============================================================================
# lib/install.zsh — Core app install primitive
# Dependencies: config.zsh, lib/ui.zsh
# =============================================================================

# ------------------------------------------------------------------------------
# _install_curl <url> <output>
# Wrapper around curl that adds the GitLab token header if set.
# ------------------------------------------------------------------------------
_install_curl() {
  local url=$1 out=$2
  if [[ -n "$REPO_TOKEN" ]]; then
    curl -fsSL --header "PRIVATE-TOKEN: $REPO_TOKEN" "$url" -o "$out"
  else
    curl -fsSL "$url" -o "$out"
  fi
}

# ------------------------------------------------------------------------------
# _install_fetch_manifest
# Download manifest.json once per session, cache at /tmp.
# ------------------------------------------------------------------------------
_install_fetch_manifest() {
  local cache="/tmp/mac-setup-manifest.json"
  [[ -f "$cache" ]] && return 0

  _ui_info "Fetching app manifest..."
  if ! _install_curl "$APP_REPO_URL/manifest.json" "$cache" 2>/dev/null; then
    _ui_error "Could not reach app repo: $APP_REPO_URL"
    exit 1
  fi
  _ui_success "Manifest loaded"
}

# ------------------------------------------------------------------------------
# install_get_manifest_field <app_id> <field>
# Read a field from manifest.json using python3 (no jq on 10.15).
# ------------------------------------------------------------------------------
install_get_manifest_field() {
  local app_id=$1 field=$2
  python3 - <<EOF
import json, sys
with open("/tmp/mac-setup-manifest.json") as f:
    data = json.load(f)
apps = {a["id"]: a for a in data["apps"]}
if "$app_id" not in apps: sys.exit(1)
print(apps["$app_id"].get("$field", ""))
EOF
}

# ------------------------------------------------------------------------------
# install_list_app_ids
# Print all app IDs from the manifest, one per line.
# ------------------------------------------------------------------------------
install_list_app_ids() {
  _install_fetch_manifest
  python3 - <<EOF
import json
with open("/tmp/mac-setup-manifest.json") as f:
    data = json.load(f)
for app in data["apps"]:
    print(app["id"])
EOF
}

# ------------------------------------------------------------------------------
# app_install <app_id> <dest_dir>
# Download zip, verify sha256, extract .app, cleanup.
# ------------------------------------------------------------------------------
app_install() {
  local app_id=$1 dest=$2
  _install_fetch_manifest

  local filename app_bundle sha256
  filename=$(install_get_manifest_field "$app_id" "filename")
  app_bundle=$(install_get_manifest_field "$app_id" "app_bundle")
  sha256=$(install_get_manifest_field "$app_id" "sha256")

  if [[ -z "$filename" ]]; then
    _ui_error "App '$app_id' not found in manifest"
    return 1
  fi

  local url="$APP_REPO_URL/$filename"
  local tmp="/tmp/mac-setup-${app_id}.zip"
  mkdir -p "$dest"

  _ui_spinner "Downloading $app_bundle" _install_curl "$url" "$tmp"
  if [[ $? -ne 0 ]]; then
    _ui_error "Download failed: $url"
    rm -f "$tmp"
    return 1
  fi

  if [[ -n "$sha256" ]]; then
    local actual
    actual=$(shasum -a 256 "$tmp" | awk '{print $1}')
    if [[ "$actual" != "$sha256" ]]; then
      _ui_error "SHA256 mismatch for $app_bundle"
      rm -f "$tmp"
      return 1
    fi
  fi

  [[ -d "$dest/$app_bundle" ]] && rm -rf "$dest/$app_bundle"

  _ui_spinner "Installing $app_bundle" unzip -q "$tmp" -d "$dest"
  local rc=$?
  rm -f "$tmp"

  if [[ $rc -ne 0 ]]; then
    _ui_error "Failed to extract $filename"
    return 1
  fi

  return 0
}

# ------------------------------------------------------------------------------
# app_is_installed <app_id> <dest_dir>
# Returns 0 if the .app bundle exists at dest.
# ------------------------------------------------------------------------------
app_is_installed() {
  local app_id=$1 dest=$2
  _install_fetch_manifest
  local app_bundle
  app_bundle=$(install_get_manifest_field "$app_id" "app_bundle")
  [[ -d "$dest/$app_bundle" ]]
}

# ------------------------------------------------------------------------------
# install_get_app_path <app_id> <dest>
# Print the full path to the installed .app bundle.
# ------------------------------------------------------------------------------
install_get_app_path() {
  local app_id=$1 dest=$2
  _install_fetch_manifest
  local app_bundle
  app_bundle=$(install_get_manifest_field "$app_id" "app_bundle")
  print "$dest/$app_bundle"
}
