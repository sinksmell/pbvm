#!/usr/bin/env bats
# Platform detection unit tests.

setup() {
  export PBVM_LIB_DIR="$BATS_TEST_DIRNAME/../lib"
  # shellcheck source=../lib/platform.sh
  source "$PBVM_LIB_DIR/platform.sh"
}

@test "osx x86_64 -> osx-x86_64" {
  uname() { case "$1" in -s) echo Darwin ;; -m) echo x86_64 ;; esac; }
  run pbvm_platform_triplet
  [ "$status" -eq 0 ]
  [ "$output" = "osx-x86_64" ]
}

@test "osx arm64 -> osx-aarch_64" {
  uname() { case "$1" in -s) echo Darwin ;; -m) echo arm64 ;; esac; }
  run pbvm_platform_triplet
  [ "$status" -eq 0 ]
  [ "$output" = "osx-aarch_64" ]
}

@test "linux x86_64 -> linux-x86_64" {
  uname() { case "$1" in -s) echo Linux ;; -m) echo x86_64 ;; esac; }
  run pbvm_platform_triplet
  [ "$status" -eq 0 ]
  [ "$output" = "linux-x86_64" ]
}

@test "linux aarch64 -> linux-aarch_64" {
  uname() { case "$1" in -s) echo Linux ;; -m) echo aarch64 ;; esac; }
  run pbvm_platform_triplet
  [ "$status" -eq 0 ]
  [ "$output" = "linux-aarch_64" ]
}

@test "asset name for 25.1 on linux-x86_64" {
  uname() { case "$1" in -s) echo Linux ;; -m) echo x86_64 ;; esac; }
  run pbvm_platform_asset 25.1
  [ "$status" -eq 0 ]
  [ "$output" = "protoc-25.1-linux-x86_64.zip" ]
}

@test "windows refuses" {
  uname() { case "$1" in -s) echo MINGW64_NT-10.0 ;; -m) echo x86_64 ;; esac; }
  run pbvm_platform_triplet
  [ "$status" -ne 0 ]
  [[ "$output" == *"Windows is not supported"* ]]
}

@test "unknown arch refuses" {
  uname() { case "$1" in -s) echo Linux ;; -m) echo sparc64 ;; esac; }
  run pbvm_platform_triplet
  [ "$status" -ne 0 ]
  [[ "$output" == *"unsupported architecture"* ]]
}
