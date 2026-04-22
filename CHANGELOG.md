# Changelog

All notable changes to this project are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Added
- Per-project version selection via `.protoc-version` file (walks up from `$PWD`).
- `pbvm use --local <version>` writes `./.protoc-version`; `pbvm use --global <version>` (the default) writes `$PBVM_ROOT/version`.
- `PBVM_VERSION` environment variable for shell-level overrides (highest priority).
- `pbvm current` now reports the source of the resolved version (`shell` / `local:<file>` / `global`).
- `lib/resolve.sh` centralizes version resolution for `pbvm current`, `pbvm which`, and internal callers.

### Changed
- `pbvm use <version>` without flags continues to set the global version (backward compatible).
- The shim resolves the active version via the 3-tier priority on every invocation; no re-sourcing required to pick up a new `.protoc-version`.

## [0.1.0] - 2026-04-21

### Added
- Initial release of pbvm, a GVM-style version manager for `protoc`.
- Commands: `install`, `uninstall`, `list`, `listall`, `use`, `current`, `which`, `exec`, `version`, `help`.
- Shim-based shell integration (pyenv/rbenv style) — no re-sourcing needed when switching versions.
- Automatic well-known-types resolution: `import "google/protobuf/timestamp.proto"` works out of the box for any installed version.
- GitHub Releases listing with 1-hour filesystem cache; `--refresh` to force.
- Platform support: macOS (Intel & Apple Silicon), Linux (x86_64, aarch64, ppc64le, s390x).
- `curl | bash` bootstrap installer + Homebrew tap.
- bats test suite and GitHub Actions CI (macOS + Linux matrix).
- bash and zsh completions.
