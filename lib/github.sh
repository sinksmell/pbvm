#!/usr/bin/env bash
# pbvm GitHub Releases helper
# Fetches release metadata for protocolbuffers/protobuf with a filesystem cache.

if [[ -n "${_PBVM_GITHUB_LOADED:-}" ]]; then
  return 0
fi
_PBVM_GITHUB_LOADED=1

# shellcheck source=log.sh
source "${PBVM_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/log.sh"

PBVM_GITHUB_REPO="${PBVM_GITHUB_REPO:-protocolbuffers/protobuf}"
PBVM_GITHUB_CACHE_TTL="${PBVM_GITHUB_CACHE_TTL:-3600}"   # seconds

# Internal: age of file in seconds (portable across macOS/Linux).
_pbvm_file_age() {
  local f="$1"
  local now mtime
  now="$(date +%s)"
  if mtime="$(stat -f %m "$f" 2>/dev/null)"; then
    :
  elif mtime="$(stat -c %Y "$f" 2>/dev/null)"; then
    :
  else
    echo "$PBVM_GITHUB_CACHE_TTL"   # force refresh on stat failure
    return
  fi
  echo $(( now - mtime ))
}

# pbvm_github_releases_json [--refresh]
#   Echoes the JSON payload of /releases (merged across up to 3 pages, 100 each).
#   Caches to $PBVM_ROOT/cache/releases.json for $PBVM_GITHUB_CACHE_TTL seconds.
pbvm_github_releases_json() {
  local refresh=0
  if [[ "${1:-}" == "--refresh" ]]; then
    refresh=1
  fi

  local cache="$PBVM_ROOT/cache/releases.json"

  if [[ $refresh -eq 0 && -s "$cache" ]]; then
    local age
    age="$(_pbvm_file_age "$cache")"
    if (( age < PBVM_GITHUB_CACHE_TTL )); then
      cat "$cache"
      return 0
    fi
  fi

  log_info "fetching releases from github.com/$PBVM_GITHUB_REPO" >&2

  local auth_header=()
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    auth_header=(-H "Authorization: Bearer $GITHUB_TOKEN")
  fi

  local tmp="${cache}.tmp"
  : > "$tmp"
  printf '[' >> "$tmp"

  local page first=1
  for page in 1 2 3; do
    local url="https://api.github.com/repos/$PBVM_GITHUB_REPO/releases?per_page=100&page=$page"
    local body
    if ! body="$(curl --fail --silent --show-error --location \
                      -H "Accept: application/vnd.github+json" \
                      ${auth_header[@]+"${auth_header[@]}"} \
                      "$url")"; then
      rm -f "$tmp"
      log_die "failed to fetch $url (network error or rate limit — set GITHUB_TOKEN to raise limits)"
    fi

    # Strip leading '[' and trailing ']' from each page then concatenate.
    body="${body#[}"
    body="${body%]}"
    # Trim surrounding whitespace.
    body="${body#"${body%%[![:space:]]*}"}"
    body="${body%"${body##*[![:space:]]}"}"

    [[ -z "$body" ]] && break   # no more pages

    if [[ $first -eq 1 ]]; then
      printf '%s' "$body" >> "$tmp"
      first=0
    else
      printf ',%s' "$body" >> "$tmp"
    fi
  done

  printf ']' >> "$tmp"
  mv -f "$tmp" "$cache"
  cat "$cache"
}

# pbvm_github_tags [--refresh]
#   Echoes tag names ("v25.1", "v24.4", ...) one per line, preserving GitHub's order
#   (newest first). Filters pre-releases unless PBVM_INCLUDE_PRERELEASE=1.
pbvm_github_tags() {
  local json
  json="$(pbvm_github_releases_json "$@")"

  local include_prerelease="${PBVM_INCLUDE_PRERELEASE:-0}"

  if command -v jq >/dev/null 2>&1; then
    if [[ "$include_prerelease" == "1" ]]; then
      jq -r '.[] | .tag_name' <<<"$json"
    else
      jq -r '.[] | select(.prerelease | not) | .tag_name' <<<"$json"
    fi
    return
  fi

  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$json" | PBVM_INCLUDE_PRERELEASE="$include_prerelease" python3 -c '
import json, os, sys
data = json.load(sys.stdin)
include_pre = os.environ.get("PBVM_INCLUDE_PRERELEASE") == "1"
for r in data:
    if include_pre or not r.get("prerelease"):
        print(r["tag_name"])
'
    return
  fi

  # Last-resort grep fallback: extract "tag_name": "vX.Y" pairs, skipping prereleases
  # by correlating with the adjacent "prerelease" field. This is fragile but avoids
  # a hard dependency. Recommend users install jq.
  log_warn "jq and python3 not found; using grep fallback (consider installing jq)" >&2
  # Pairs up each tag_name with its prerelease flag via awk state machine.
  # shellcheck disable=SC2020 # tr is intentionally mapping 3 chars to newline
  printf '%s' "$json" \
    | tr ',{}' '\n\n\n' \
    | awk -v inc="$include_prerelease" '
        /"tag_name":/ { sub(/.*"tag_name":[[:space:]]*"/,""); sub(/".*/,""); tag=$0 }
        /"prerelease":/ {
          sub(/.*"prerelease":[[:space:]]*/,"")
          sub(/[^a-z].*/,"")
          pre=$0
          if (tag != "") {
            if (inc == "1" || pre == "false") print tag
            tag=""
          }
        }
      '
}
