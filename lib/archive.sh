#!/usr/bin/env bash
# pbvm archive helpers — zip verification and extraction.

if [[ -n "${_PBVM_ARCHIVE_LOADED:-}" ]]; then
  return 0
fi
_PBVM_ARCHIVE_LOADED=1

# shellcheck source=log.sh
source "${PBVM_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/log.sh"

# pbvm_archive_verify <zip>
pbvm_archive_verify() {
  local zip="$1"
  [[ -f "$zip" ]] || log_die "archive not found: $zip"
  if ! unzip -tq "$zip" >/dev/null 2>&1; then
    log_die "archive is corrupt: $zip"
  fi
}

# pbvm_archive_extract <zip> <dest_dir>
#   Extracts into dest_dir. Creates dest_dir if missing.
pbvm_archive_extract() {
  local zip="$1" dest="$2"
  [[ -n "$zip" && -n "$dest" ]] || log_die "pbvm_archive_extract: usage: <zip> <dest>"
  pbvm_archive_verify "$zip"
  mkdir -p "$dest"
  log_step "extracting to $dest"
  if ! unzip -q -o "$zip" -d "$dest"; then
    log_die "extract failed: $zip -> $dest"
  fi
}
