# pbvm — Protocol Buffers Version Manager

GVM-style version manager for [`protoc`](https://github.com/protocolbuffers/protobuf) (the Protocol Buffers compiler). Install and switch between multiple `protoc` versions, each with its own bundled `google/protobuf/*.proto` well-known-types.

- **Shim-based** (pyenv/rbenv style) — switch versions without re-sourcing your shell
- **Pure Bash** — transparent, auditable, no compiled binary required
- **Zero-config well-known-types** — `import "google/protobuf/timestamp.proto"` just works for the active version
- **macOS** (Intel & Apple Silicon) and **Linux** (x86_64, aarch64, ppc64le, s390x)

## Install

### curl | bash (recommended)

```sh
curl -fsSL https://raw.githubusercontent.com/sinksmell/pbvm/master/install.sh | bash
```

The installer clones pbvm into `~/.pbvm` and appends the following to your shell rc file (`~/.zshrc` or `~/.bashrc`):

```sh
export PBVM_ROOT="$HOME/.pbvm"
export PATH="$PBVM_ROOT/bin:$PBVM_ROOT/shims:$PATH"
```

Restart your shell (or `source` the rc file) and you're ready.

### Homebrew

```sh
brew tap sinksmell/pbvm
brew install pbvm
```

(Remember to add the `PBVM_ROOT` / `PATH` lines above to your shell rc — Homebrew installs the CLI, not the shell hook.)

## Usage

```sh
pbvm listall                        # available versions on GitHub
pbvm install 25.1                   # download and extract protoc 25.1
pbvm install 24.4
pbvm list                           # installed versions (active marked =>)
pbvm use 25.1                       # set the active version
protoc --version                    # → libprotoc 25.1
pbvm use 24.4 && protoc --version   # → libprotoc 24.4
pbvm exec 25.1 -- protoc --version  # temporarily use 25.1, active stays 24.4
pbvm which                          # absolute path to active binary
pbvm current                        # version + path
pbvm uninstall 24.4                 # remove an inactive version
pbvm uninstall 24.4 --purge         # also drop cached archive
```

### Makefile integration

```make
PROTOC := $(shell pbvm which)

%.pb.go: %.proto
    $(PROTOC) --go_out=. $<
```

### Pin a version via environment

```sh
export PBVM_ROOT="$HOME/.pbvm"
pbvm exec 25.1 -- make gen
```

`exec` prepends the target version's `bin/` to `PATH` for the duration of the command — any nested `protoc` call routes there without touching the globally active version.

## How it works

1. `pbvm install X` downloads `protoc-X-<platform>.zip` from GitHub Releases into `~/.pbvm/archives/` (cached), verifies, and extracts to `~/.pbvm/versions/protoc-X/`.
2. `pbvm use X` writes `X` to `~/.pbvm/version`. No PATH changes, no shell re-sourcing.
3. `~/.pbvm/shims/protoc` is on your PATH. When invoked, it reads `~/.pbvm/version` and `exec`s the real `~/.pbvm/versions/protoc-X/bin/protoc`.
4. Because the real binary is reached via `exec`, `protoc` resolves `import "google/protobuf/*.proto"` against its own `../include/` — version-correct well-known-types with no configuration.

## Directory layout

```
~/.pbvm/
├── bin/pbvm                     # CLI dispatcher
├── libexec/pbvm-<cmd>           # subcommand scripts
├── lib/                         # shared helpers (platform, github, log, ...)
├── shims/protoc                 # the shim on your PATH
├── versions/protoc-<version>/
│   ├── bin/protoc
│   └── include/google/protobuf/*.proto
├── archives/                    # download cache
├── cache/releases.json          # `listall` cache (1h TTL)
└── version                      # active version (single line)
```

## vs. alternatives

| Tool                | Standalone | Shim mode | WKT auto | Maintained |
|---------------------|:----------:|:---------:|:--------:|:----------:|
| **pbvm**            | ✅         | ✅        | ✅       | ✅         |
| asdf + asdf-protoc  | ❌ (asdf)  | ✅        | ✅       | ✅         |
| protov (Python)     | ✅         | ❌ (ln)   | ✅       | ⚠️ niche   |
| protoenv            | ✅         | —         | —        | ⚠️ inactive|
| manual install      | —          | —         | —        | —          |

## Environment

| Variable                    | Purpose                                             |
|-----------------------------|-----------------------------------------------------|
| `PBVM_ROOT`                 | Data directory (default `~/.pbvm`)                   |
| `PBVM_INCLUDE_PRERELEASE=1` | Show RC/beta tags in `pbvm listall`                  |
| `PBVM_GITHUB_CACHE_TTL`     | `listall` cache lifetime, seconds (default `3600`)   |
| `GITHUB_TOKEN`              | Raise GitHub API rate limits (optional)              |
| `NO_COLOR`                  | Disable colored output                               |

## Development

```sh
git clone https://github.com/sinksmell/pbvm.git
cd pbvm
brew install bats-core jq          # or apt-get install bats jq
bats tests/
```

Integration run (downloads real protoc):

```sh
PBVM_ROOT=/tmp/pbvm-dev ./bin/pbvm install 25.1
PBVM_ROOT=/tmp/pbvm-dev ./bin/pbvm use 25.1
PBVM_ROOT=/tmp/pbvm-dev ./shims/protoc --version
```

## License

MIT © pbvm contributors. See [LICENSE](LICENSE).
