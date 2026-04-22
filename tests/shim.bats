#!/usr/bin/env bats
# Shim behavior tests. Isolated PBVM_ROOT per test via BATS_TEST_TMPDIR.

bats_require_minimum_version 1.5.0

setup() {
  export PBVM_ROOT="$BATS_TEST_TMPDIR/root"
  mkdir -p "$PBVM_ROOT/versions"
  export SHIM="$BATS_TEST_DIRNAME/../shims/protoc"
}

@test "shim fails when no version is active" {
  run -127 "$SHIM" --version
  [[ "$output" == *"no active protoc version"* ]]
}

@test "shim fails when active version is not installed" {
  echo "99.9" > "$PBVM_ROOT/version"
  run -127 "$SHIM" --version
  [[ "$output" == *"not installed"* ]]
}

@test "shim execs target when version is installed" {
  # Create a fake protoc that prints its path and args.
  fake_dir="$PBVM_ROOT/versions/protoc-99.9/bin"
  mkdir -p "$fake_dir"
  cat > "$fake_dir/protoc" <<'EOS'
#!/usr/bin/env bash
echo "fake-protoc $*"
EOS
  chmod +x "$fake_dir/protoc"

  echo "99.9" > "$PBVM_ROOT/version"
  run "$SHIM" --version
  [ "$status" -eq 0 ]
  [ "$output" = "fake-protoc --version" ]
}
