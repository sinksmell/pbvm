#!/usr/bin/env bash
# pbvm platform detection
# Provides: pbvm_platform_asset <version>  — echoes the protoc release asset filename
# for the current host, e.g. "protoc-25.1-osx-aarch_64.zip". Exits non-zero with a
# descriptive error if the platform is unsupported.

if [[ -n "${_PBVM_PLATFORM_LOADED:-}" ]]; then
  return 0
fi
_PBVM_PLATFORM_LOADED=1

# shellcheck source=log.sh
source "${PBVM_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/log.sh"

pbvm_platform_os() {
  local os
  os="$(uname -s)"
  case "$os" in
    Darwin) echo "osx" ;;
    Linux)  echo "linux" ;;
    MINGW*|MSYS*|CYGWIN*) echo "win" ;;
    *) return 1 ;;
  esac
}

pbvm_platform_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64)    echo "x86_64" ;;
    aarch64|arm64)   echo "aarch_64" ;;
    ppc64le)         echo "ppcle_64" ;;
    s390x)           echo "s390_64" ;;
    i386|i686)       echo "x86_32" ;;
    *) return 1 ;;
  esac
}

# pbvm_platform_triplet -> "osx-aarch_64"
pbvm_platform_triplet() {
  local os arch
  os="$(pbvm_platform_os)" || log_die "unsupported OS: $(uname -s)"
  arch="$(pbvm_platform_arch)" || log_die "unsupported architecture: $(uname -m)"
  if [[ "$os" == "win" ]]; then
    log_die "Windows is not supported in pbvm v1. Use WSL."
  fi
  echo "${os}-${arch}"
}

# pbvm_platform_asset <version> -> "protoc-25.1-osx-aarch_64.zip"
pbvm_platform_asset() {
  local version="$1"
  [[ -n "$version" ]] || log_die "pbvm_platform_asset: version required"
  local triplet
  triplet="$(pbvm_platform_triplet)"
  echo "protoc-${version}-${triplet}.zip"
}
