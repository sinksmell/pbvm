#!/usr/bin/env bash
# pbvm installer — downloads pbvm into ~/.pbvm and wires up shell integration.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<owner>/pbvm/main/install.sh | bash
#
# Environment:
#   PBVM_INSTALL_DIR   Install target (default: ~/.pbvm)
#   PBVM_REPO          Override source repo (default: <owner>/pbvm)
#   PBVM_REF           Git branch/tag to install (default: main)
#   PBVM_SKIP_RC       If set, don't modify shell rc files

set -euo pipefail

PBVM_INSTALL_DIR="${PBVM_INSTALL_DIR:-$HOME/.pbvm}"
PBVM_REPO="${PBVM_REPO:-sinksmell/pbvm}"
PBVM_REF="${PBVM_REF:-main}"

_c_bold=$'\033[1m'; _c_green=$'\033[32m'; _c_yellow=$'\033[33m'
_c_red=$'\033[31m'; _c_dim=$'\033[2m'; _c_reset=$'\033[0m'
[[ -t 1 ]] || { _c_bold=''; _c_green=''; _c_yellow=''; _c_red=''; _c_dim=''; _c_reset=''; }

info()  { printf '%s==>%s %s\n' "$_c_green" "$_c_reset" "$*"; }
warn()  { printf '%swarn:%s %s\n' "$_c_yellow" "$_c_reset" "$*"; }
die()   { printf '%serror:%s %s\n' "$_c_red" "$_c_reset" "$*" >&2; exit 1; }

# --- Dependency check ---------------------------------------------------------

for cmd in curl unzip bash; do
  command -v "$cmd" >/dev/null 2>&1 || die "missing required command: $cmd"
done

have_git=0
command -v git >/dev/null 2>&1 && have_git=1

# --- Fetch pbvm ---------------------------------------------------------------

if [[ -d "$PBVM_INSTALL_DIR" ]]; then
  if [[ -d "$PBVM_INSTALL_DIR/.git" && $have_git -eq 1 ]]; then
    info "updating existing pbvm at $PBVM_INSTALL_DIR"
    git -C "$PBVM_INSTALL_DIR" fetch --depth 1 origin "$PBVM_REF"
    git -C "$PBVM_INSTALL_DIR" checkout -q "$PBVM_REF"
    git -C "$PBVM_INSTALL_DIR" reset --hard "origin/$PBVM_REF"
  elif [[ -f "$PBVM_INSTALL_DIR/bin/pbvm" ]]; then
    warn "$PBVM_INSTALL_DIR exists and is not a git checkout; refusing to overwrite"
    warn "remove it manually (rm -rf \"$PBVM_INSTALL_DIR\") and rerun the installer"
    exit 1
  else
    # Directory exists but no pbvm — likely user-created data dir. Use it in place.
    warn "$PBVM_INSTALL_DIR exists and appears empty of pbvm; installing into it"
  fi
fi

if [[ ! -f "$PBVM_INSTALL_DIR/bin/pbvm" ]]; then
  if [[ $have_git -eq 1 ]]; then
    info "cloning $PBVM_REPO@$PBVM_REF into $PBVM_INSTALL_DIR"
    mkdir -p "$(dirname "$PBVM_INSTALL_DIR")"
    git clone --depth 1 --branch "$PBVM_REF" \
      "https://github.com/$PBVM_REPO.git" "$PBVM_INSTALL_DIR"
  else
    info "downloading $PBVM_REPO@$PBVM_REF tarball"
    mkdir -p "$PBVM_INSTALL_DIR"
    local_tmp="$(mktemp -d)"
    trap 'rm -rf "$local_tmp"' EXIT
    curl -fsSL -o "$local_tmp/pbvm.tar.gz" \
      "https://codeload.github.com/$PBVM_REPO/tar.gz/refs/heads/$PBVM_REF"
    tar -xzf "$local_tmp/pbvm.tar.gz" -C "$local_tmp"
    # Move contents (tarball has one top-level dir "pbvm-<ref>").
    local_top="$(find "$local_tmp" -maxdepth 1 -mindepth 1 -type d ! -name '.*' | head -1)"
    cp -R "$local_top"/. "$PBVM_INSTALL_DIR"/
    trap - EXIT
    rm -rf "$local_tmp"
  fi
fi

# --- chmod -------------------------------------------------------------------

chmod +x "$PBVM_INSTALL_DIR/bin/pbvm" \
         "$PBVM_INSTALL_DIR/shims/protoc" \
         "$PBVM_INSTALL_DIR"/libexec/pbvm-*

info "pbvm installed at $PBVM_INSTALL_DIR"

# --- Shell integration -------------------------------------------------------

if [[ -n "${PBVM_SKIP_RC:-}" ]]; then
  info "skipping rc-file modification (PBVM_SKIP_RC set)"
else
  # Detect target rc file from $SHELL (not current interpreter).
  rc=""
  case "${SHELL:-}" in
    */zsh)  rc="$HOME/.zshrc" ;;
    */bash)
      if [[ -f "$HOME/.bashrc" ]]; then
        rc="$HOME/.bashrc"
      elif [[ -f "$HOME/.bash_profile" ]]; then
        rc="$HOME/.bash_profile"
      else
        rc="$HOME/.bashrc"
      fi
      ;;
    *) rc="$HOME/.profile" ;;
  esac

  marker="# >>> pbvm >>>"
  end_marker="# <<< pbvm <<<"

  if [[ -f "$rc" ]] && grep -qF "$marker" "$rc"; then
    info "shell integration already present in $rc"
  else
    info "adding shell integration to $rc"
    {
      printf '\n%s\n' "$marker"
      printf 'export PBVM_ROOT="%s"\n' "$PBVM_INSTALL_DIR"
      # shellcheck disable=SC2016 # the rc file should keep $PBVM_ROOT unexpanded
      printf 'export PATH="$PBVM_ROOT/bin:$PBVM_ROOT/shims:$PATH"\n'
      printf '%s\n' "$end_marker"
    } >> "$rc"
  fi
fi

# --- Done --------------------------------------------------------------------

cat <<EOF

${_c_bold}pbvm installed successfully.${_c_reset}

Next steps:
  1. Restart your shell, or run: ${_c_dim}source "$rc"${_c_reset}
  2. List available versions:    ${_c_dim}pbvm listall${_c_reset}
  3. Install a protoc version:   ${_c_dim}pbvm install 25.1${_c_reset}
  4. Activate it:                ${_c_dim}pbvm use 25.1${_c_reset}
  5. Verify:                     ${_c_dim}protoc --version${_c_reset}

EOF
