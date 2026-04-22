#!/usr/bin/env bash
# pbvm download helper — curl wrapper with progress and cache semantics.

if [[ -n "${_PBVM_DOWNLOAD_LOADED:-}" ]]; then
  return 0
fi
_PBVM_DOWNLOAD_LOADED=1

# shellcheck source=log.sh
source "${PBVM_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/log.sh"

# pbvm_download <url> <dest>
#   - If dest already exists and is non-empty, skip (cache hit).
#   - Download to dest.tmp then atomically rename.
#   - Exits non-zero on HTTP failure.
pbvm_download() {
  local url="$1" dest="$2"
  [[ -n "$url" && -n "$dest" ]] || log_die "pbvm_download: usage: <url> <dest>"

  if [[ -s "$dest" ]]; then
    log_step "cache hit: ${dest##*/}"
    return 0
  fi

  local dest_dir="${dest%/*}"
  [[ -d "$dest_dir" ]] || mkdir -p "$dest_dir"

  log_info "downloading $url"

  local curl_opts=(--fail --location --retry 3 --retry-delay 1)
  # Use --progress-bar interactively, silent elsewhere (CI)
  if [[ -t 2 ]]; then
    curl_opts+=(--progress-bar)
  else
    curl_opts+=(--silent --show-error)
  fi

  local tmp="${dest}.tmp"
  if ! curl "${curl_opts[@]}" -o "$tmp" "$url"; then
    rm -f "$tmp"
    log_die "download failed: $url"
  fi

  mv -f "$tmp" "$dest"
  log_step "saved to $dest"
}
