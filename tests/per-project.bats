#!/usr/bin/env bats
# End-to-end tests for shim + use --local + use --global wired together.

bats_require_minimum_version 1.5.0

setup() {
  export PBVM_ROOT="$BATS_TEST_TMPDIR/root"
  export PBVM="$BATS_TEST_DIRNAME/../bin/pbvm"
  export SHIM="$BATS_TEST_DIRNAME/../shims/protoc"
  mkdir -p "$PBVM_ROOT/versions" "$BATS_TEST_TMPDIR/proj/sub" "$BATS_TEST_TMPDIR/other"
  unset PBVM_VERSION
  _install_fake 25.1
  _install_fake 24.4
}

_install_fake() {
  local version="$1"
  local dir="$PBVM_ROOT/versions/protoc-$version/bin"
  mkdir -p "$dir"
  cat > "$dir/protoc" <<EOS
#!/usr/bin/env bash
echo "libprotoc $version"
EOS
  chmod +x "$dir/protoc"
}

@test "use --global is the default behavior of 'use'" {
  run "$PBVM" use 25.1
  [ "$status" -eq 0 ]
  [ -s "$PBVM_ROOT/version" ]
  [ "$(cat "$PBVM_ROOT/version")" = "25.1" ]
  [[ "$output" == *"(global)"* ]]
}

@test "use --global writes the global version file" {
  run "$PBVM" use --global 25.1
  [ "$status" -eq 0 ]
  [ "$(cat "$PBVM_ROOT/version")" = "25.1" ]
}

@test "use --local writes .protoc-version in cwd" {
  cd "$BATS_TEST_TMPDIR/proj"
  run "$PBVM" use --local 24.4
  [ "$status" -eq 0 ]
  [ -s "./.protoc-version" ]
  [ "$(cat ./.protoc-version)" = "24.4" ]
  [[ "$output" == *"local:"* ]]
}

@test "use --local refuses uninstalled version" {
  cd "$BATS_TEST_TMPDIR/proj"
  run "$PBVM" use --local 99.9
  [ "$status" -ne 0 ]
  [ ! -f ./.protoc-version ]
}

@test "shim honors local over global" {
  "$PBVM" use 25.1
  echo "24.4" > "$BATS_TEST_TMPDIR/proj/.protoc-version"

  cd "$BATS_TEST_TMPDIR/proj"
  run "$SHIM" --version
  [ "$status" -eq 0 ]
  [ "$output" = "libprotoc 24.4" ]
}

@test "shim walks up from subdir to find .protoc-version" {
  "$PBVM" use 25.1
  echo "24.4" > "$BATS_TEST_TMPDIR/proj/.protoc-version"

  cd "$BATS_TEST_TMPDIR/proj/sub"
  run "$SHIM" --version
  [ "$status" -eq 0 ]
  [ "$output" = "libprotoc 24.4" ]
}

@test "shim falls back to global outside project" {
  "$PBVM" use 25.1
  echo "24.4" > "$BATS_TEST_TMPDIR/proj/.protoc-version"

  cd "$BATS_TEST_TMPDIR/other"
  run "$SHIM" --version
  [ "$status" -eq 0 ]
  [ "$output" = "libprotoc 25.1" ]
}

@test "PBVM_VERSION env beats both local and global" {
  "$PBVM" use 24.4
  echo "24.4" > "$BATS_TEST_TMPDIR/proj/.protoc-version"

  cd "$BATS_TEST_TMPDIR/proj"
  PBVM_VERSION=25.1 run "$SHIM" --version
  [ "$status" -eq 0 ]
  [ "$output" = "libprotoc 25.1" ]
}

@test "current shows global source" {
  "$PBVM" use 25.1
  cd "$BATS_TEST_TMPDIR/other"
  run "$PBVM" current
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == *"25.1 (global)"* ]]
}

@test "current shows local source with file path" {
  echo "24.4" > "$BATS_TEST_TMPDIR/proj/.protoc-version"
  cd "$BATS_TEST_TMPDIR/proj"
  run "$PBVM" current
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == *"24.4 (set by"*".protoc-version)"* ]]
}

@test "current shows shell source when PBVM_VERSION set" {
  "$PBVM" use 24.4
  cd "$BATS_TEST_TMPDIR/other"
  PBVM_VERSION=25.1 run "$PBVM" current
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == *"25.1 (set by PBVM_VERSION)"* ]]
}

@test "which resolves via the same priority as the shim" {
  "$PBVM" use 25.1
  echo "24.4" > "$BATS_TEST_TMPDIR/proj/.protoc-version"

  cd "$BATS_TEST_TMPDIR/proj/sub"
  run "$PBVM" which
  [ "$status" -eq 0 ]
  [[ "$output" == *"protoc-24.4/bin/protoc" ]]
}
