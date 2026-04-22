# Typed strictly from memory; update url/sha256 at each release. See
# https://docs.brew.sh/Formula-Cookbook for reference.
class Pbvm < Formula
  desc "Protocol Buffers version manager (GVM-style, for protoc)"
  homepage "https://github.com/sinksmell/pbvm"
  url "https://github.com/sinksmell/pbvm/releases/download/v0.1.0/pbvm-0.1.0.tar.gz"
  sha256 "REPLACE_WITH_SHA256_OF_TARBALL"
  license "MIT"
  version "0.1.0"

  depends_on "bash"
  depends_on "jq" => :recommended

  def install
    libexec.install "bin", "libexec", "lib", "shims", "VERSION"
    bin.install_symlink libexec/"bin/pbvm"

    bash_completion.install "completions/pbvm.bash" => "pbvm"
    zsh_completion.install  "completions/_pbvm"
  end

  def caveats
    <<~EOS
      To finish setting up pbvm, add the following to your shell rc file
      (~/.zshrc, ~/.bashrc, or ~/.bash_profile):

        export PBVM_ROOT="$HOME/.pbvm"
        export PATH="$PBVM_ROOT/bin:$PBVM_ROOT/shims:$PATH"

      Then run:

        pbvm install 25.1
        pbvm use 25.1
        protoc --version
    EOS
  end

  test do
    assert_match "0.1.0", shell_output("#{bin}/pbvm version")
    assert_match "install", shell_output("#{bin}/pbvm help")
  end
end
