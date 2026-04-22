#!/usr/bin/env bash
# pbvm log helpers — colored stderr logging
# Source this file; it defines log_info / log_warn / log_error / log_die.

# Idempotent guard
if [[ -n "${_PBVM_LOG_LOADED:-}" ]]; then
  return 0
fi
_PBVM_LOG_LOADED=1

if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
  _pbvm_c_reset=$'\033[0m'
  _pbvm_c_bold=$'\033[1m'
  _pbvm_c_dim=$'\033[2m'
  _pbvm_c_red=$'\033[31m'
  _pbvm_c_yellow=$'\033[33m'
  _pbvm_c_green=$'\033[32m'
  _pbvm_c_blue=$'\033[34m'
else
  _pbvm_c_reset=''; _pbvm_c_bold=''; _pbvm_c_dim=''
  _pbvm_c_red=''; _pbvm_c_yellow=''; _pbvm_c_green=''; _pbvm_c_blue=''
fi

log_info() {
  printf '%s==>%s %s\n' "$_pbvm_c_blue" "$_pbvm_c_reset" "$*" >&2
}

log_ok() {
  printf '%s==>%s %s\n' "$_pbvm_c_green" "$_pbvm_c_reset" "$*" >&2
}

log_warn() {
  printf '%swarn:%s %s\n' "$_pbvm_c_yellow" "$_pbvm_c_reset" "$*" >&2
}

log_error() {
  printf '%serror:%s %s\n' "$_pbvm_c_red" "$_pbvm_c_reset" "$*" >&2
}

log_die() {
  log_error "$@"
  exit 1
}

log_step() {
  printf '%s   ->%s %s\n' "$_pbvm_c_dim" "$_pbvm_c_reset" "$*" >&2
}
