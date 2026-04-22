# Changelog

All notable changes to this project are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/).

## [Unreleased]

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
