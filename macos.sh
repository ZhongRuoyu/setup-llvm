#!/bin/sh

set -eux

current_llvm_stable() {
  # HACK: We don't want to add a dependency on jq just for this, so we use sed
  # to extract the version number from the JSON output.
  HOMEBREW_NO_AUTO_UPDATE="" brew info --json llvm |
    sed -En 's/.*"stable"[[:space:]]*:[[:space:]]*"([0-9]+)(\.[0-9]+)*".*/\1/p'
}

install_llvm() {
  llvm_formula="llvm@$1"
  HOMEBREW_NO_AUTO_UPDATE="" brew install "$llvm_formula"
}

setup_llvm_path() {
  llvm_formula="llvm@$1"
  echo "$(brew --prefix "$llvm_formula")/bin" >>"$GITHUB_PATH"
  PATH="$(brew --prefix "$llvm_formula")/bin:$PATH"
  export PATH
}

sanity_check() {
  llvm_version="$(llvm-config --version)"
  if [ "$(echo "$llvm_version" | cut -d. -f1)" != "$1" ]; then
    echo "Expected LLVM major version $1, got $llvm_version" >&2
    exit 1
  fi
}

LLVM_VERSION="${LLVM_VERSION:-$(current_llvm_stable)}"
install_llvm "$LLVM_VERSION"
setup_llvm_path "$LLVM_VERSION"
sanity_check "$LLVM_VERSION"
