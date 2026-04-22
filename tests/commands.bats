#!/usr/bin/env bats
# use / list / current / which / uninstall command behavior.
# Each test gets its own $PBVM_ROOT; no real protoc is downloaded.

setup() {
  export PBVM_ROOT="$BATS_TEST_TMPDIR/root"
  export PBVM="$BATS_TEST_DIRNAME/../bin/pbvm"
  mkdir -p "$PBVM_ROOT/versions"
}

# Helper: create a fake installed version with a working `protoc` stub.
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

@test "list: no versions installed prints hint" {
  run "$PBVM" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"no versions installed"* ]]
}

@test "use: fails when version not installed" {
  run "$PBVM" use 99.9
  [ "$status" -ne 0 ]
  [[ "$output" == *"not installed"* ]]
}

@test "use: writes active version file" {
  _install_fake 25.1
  run "$PBVM" use 25.1
  [ "$status" -eq 0 ]
  [ -s "$PBVM_ROOT/version" ]
  [ "$(cat "$PBVM_ROOT/version")" = "25.1" ]
}

@test "list: marks active version with =>" {
  _install_fake 25.1
  _install_fake 24.4
  echo "25.1" > "$PBVM_ROOT/version"

  run "$PBVM" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"=> 25.1"* ]]
  [[ "$output" == *"   24.4"* ]]
}

@test "current: prints version + path when active" {
  _install_fake 25.1
  echo "25.1" > "$PBVM_ROOT/version"

  run "$PBVM" current
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == "25.1"* ]]
  [[ "${lines[1]}" == *"protoc-25.1/bin/protoc"* ]]
}

@test "current: fails when no active version" {
  run "$PBVM" current
  [ "$status" -eq 1 ]
  [[ "$output" == *"no protoc version set"* ]]
}

@test "which: prints absolute path" {
  _install_fake 25.1
  echo "25.1" > "$PBVM_ROOT/version"
  run "$PBVM" which
  [ "$status" -eq 0 ]
  [ "$output" = "$PBVM_ROOT/versions/protoc-25.1/bin/protoc" ]
}

@test "uninstall: refuses active version" {
  _install_fake 25.1
  echo "25.1" > "$PBVM_ROOT/version"
  run "$PBVM" uninstall 25.1
  [ "$status" -ne 0 ]
  [[ "$output" == *"refusing"* ]]
  [ -d "$PBVM_ROOT/versions/protoc-25.1" ]
}

@test "uninstall: removes an inactive version" {
  _install_fake 25.1
  _install_fake 24.4
  echo "25.1" > "$PBVM_ROOT/version"
  run "$PBVM" uninstall 24.4
  [ "$status" -eq 0 ]
  [ ! -d "$PBVM_ROOT/versions/protoc-24.4" ]
  [ -d "$PBVM_ROOT/versions/protoc-25.1" ]
}

@test "exec: routes to specified version, not active" {
  _install_fake 25.1
  _install_fake 24.4
  echo "25.1" > "$PBVM_ROOT/version"
  run "$PBVM" exec 24.4 -- protoc --version
  [ "$status" -eq 0 ]
  [ "$output" = "libprotoc 24.4" ]
}

@test "version: prints pbvm VERSION file" {
  run "$PBVM" version
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat "$BATS_TEST_DIRNAME/../VERSION")" ]
}

@test "help: lists commands" {
  run "$PBVM" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"install"* ]]
  [[ "$output" == *"uninstall"* ]]
  [[ "$output" == *"listall"* ]]
}

@test "unknown command fails with usage" {
  run "$PBVM" nosuchcmd
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown command"* ]]
}
