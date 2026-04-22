#!/usr/bin/env bats
# Version resolution tests for lib/resolve.sh.
# Exercises the three-tier priority: PBVM_VERSION env > .protoc-version walk-up > global.

bats_require_minimum_version 1.5.0

setup() {
  export PBVM_ROOT="$BATS_TEST_TMPDIR/root"
  export PBVM_LIB_DIR="$BATS_TEST_DIRNAME/../lib"
  mkdir -p "$PBVM_ROOT" "$BATS_TEST_TMPDIR/proj/sub" "$BATS_TEST_TMPDIR/other"
  # shellcheck source=../lib/resolve.sh
  source "$PBVM_LIB_DIR/resolve.sh"
  unset PBVM_VERSION
}

@test "resolve: nothing set -> non-zero" {
  cd "$BATS_TEST_TMPDIR/other"
  run pbvm_resolve
  [ "$status" -ne 0 ]
}

@test "resolve: global only" {
  echo "25.1" > "$PBVM_ROOT/version"
  cd "$BATS_TEST_TMPDIR/other"
  run pbvm_resolve
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "25.1" ]
  [ "${lines[1]}" = "global" ]
}

@test "resolve: local file beats global" {
  echo "25.1" > "$PBVM_ROOT/version"
  echo "24.4" > "$BATS_TEST_TMPDIR/proj/.protoc-version"
  cd "$BATS_TEST_TMPDIR/proj"
  run pbvm_resolve
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "24.4" ]
  [ "${lines[1]}" = "local:$BATS_TEST_TMPDIR/proj/.protoc-version" ]
}

@test "resolve: local file walk-up from subdir" {
  echo "24.4" > "$BATS_TEST_TMPDIR/proj/.protoc-version"
  cd "$BATS_TEST_TMPDIR/proj/sub"
  run pbvm_resolve
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "24.4" ]
  [ "${lines[1]}" = "local:$BATS_TEST_TMPDIR/proj/.protoc-version" ]
}

@test "resolve: walk-up misses when file is outside ancestor chain" {
  echo "25.1" > "$PBVM_ROOT/version"
  echo "24.4" > "$BATS_TEST_TMPDIR/proj/.protoc-version"
  cd "$BATS_TEST_TMPDIR/other"
  run pbvm_resolve
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "25.1" ]
  [ "${lines[1]}" = "global" ]
}

@test "resolve: PBVM_VERSION env beats everything" {
  echo "25.1" > "$PBVM_ROOT/version"
  echo "24.4" > "$BATS_TEST_TMPDIR/proj/.protoc-version"
  cd "$BATS_TEST_TMPDIR/proj"
  PBVM_VERSION=99.9 run pbvm_resolve
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "99.9" ]
  [ "${lines[1]}" = "shell" ]
}

@test "resolve: empty local file falls through" {
  echo "25.1" > "$PBVM_ROOT/version"
  : > "$BATS_TEST_TMPDIR/proj/.protoc-version"
  cd "$BATS_TEST_TMPDIR/proj"
  run pbvm_resolve
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "25.1" ]
  [ "${lines[1]}" = "global" ]
}

@test "resolve: whitespace-only local file falls through" {
  echo "25.1" > "$PBVM_ROOT/version"
  printf '   \n' > "$BATS_TEST_TMPDIR/proj/.protoc-version"
  cd "$BATS_TEST_TMPDIR/proj"
  run pbvm_resolve
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "25.1" ]
  [ "${lines[1]}" = "global" ]
}

@test "resolve: local file with surrounding whitespace is trimmed" {
  printf '  25.9  \n' > "$BATS_TEST_TMPDIR/proj/.protoc-version"
  cd "$BATS_TEST_TMPDIR/proj"
  run pbvm_resolve_version
  [ "$status" -eq 0 ]
  [ "$output" = "25.9" ]
}
