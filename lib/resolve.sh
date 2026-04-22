#!/usr/bin/env bash
# pbvm version resolution
#
# Resolves the active protoc version using a three-tier priority:
#   1. PBVM_VERSION environment variable (shell-level override)
#   2. .protoc-version file found by walking up from $PWD
#   3. Global $PBVM_ROOT/version file
#
# Provides:
#   pbvm_resolve_version   -> echoes the version, or non-zero if unset
#   pbvm_resolve           -> echoes "<version>\n<source>", or non-zero if unset
#
# Source values used by pbvm_resolve:
#   shell                 (PBVM_VERSION env)
#   local:/abs/path       (the .protoc-version file that matched)
#   global                ($PBVM_ROOT/version)

if [[ -n "${_PBVM_RESOLVE_LOADED:-}" ]]; then
  return 0
fi
_PBVM_RESOLVE_LOADED=1

# _pbvm_read_line_trimmed <file>
#   Echoes the first line of the file with surrounding whitespace stripped.
#   Echoes empty string if the file is empty or unreadable.
_pbvm_read_line_trimmed() {
  local f="$1" line
  [[ -s "$f" ]] || return 0
  IFS= read -r line < "$f" || true
  # Strip leading/trailing whitespace (bash parameter expansion is portable).
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  printf '%s' "$line"
}

# pbvm_resolve -> writes two lines to stdout: the version and its source.
pbvm_resolve() {
  if [[ -n "${PBVM_VERSION:-}" ]]; then
    printf '%s\nshell\n' "$PBVM_VERSION"
    return 0
  fi

  # Walk up from $PWD looking for .protoc-version.
  local dir="$PWD" version
  while [[ -n "$dir" ]]; do
    if [[ -f "$dir/.protoc-version" ]]; then
      version="$(_pbvm_read_line_trimmed "$dir/.protoc-version")"
      if [[ -n "$version" ]]; then
        printf '%s\nlocal:%s\n' "$version" "$dir/.protoc-version"
        return 0
      fi
    fi
    # Stop after checking /.
    [[ "$dir" == "/" ]] && break
    dir="${dir%/*}"
    [[ -z "$dir" ]] && dir="/"
  done

  if [[ -s "${PBVM_ROOT:-$HOME/.pbvm}/version" ]]; then
    version="$(_pbvm_read_line_trimmed "${PBVM_ROOT:-$HOME/.pbvm}/version")"
    if [[ -n "$version" ]]; then
      printf '%s\nglobal\n' "$version"
      return 0
    fi
  fi

  return 1
}

# pbvm_resolve_version -> writes just the version, or returns non-zero.
pbvm_resolve_version() {
  local out
  out="$(pbvm_resolve)" || return 1
  printf '%s\n' "${out%%$'\n'*}"
}
