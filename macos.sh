#!/bin/sh

set -eux

install_llvm() {
  llvm_formula="llvm"
  if [ "$#" -eq 1 ]; then
    llvm_formula="llvm@$1"
  fi
  HOMEBREW_NO_AUTO_UPDATE="" brew install "$llvm_formula"
  echo "$(brew --prefix "$llvm_formula")/bin" >>"$GITHUB_PATH"
  PATH="$(brew --prefix "$llvm_formula")/bin:$PATH"
  export PATH
}

sanity_check() {
  llvm_config="llvm-config"
  llvm_version="$("$llvm_config" --version)"
  llvm_major_version="$(echo "$llvm_version" | cut -d. -f1)"
  if [ "$#" -eq 1 ] && [ "$llvm_major_version" != "$1" ]; then
    echo "Expected LLVM major version $1, got $llvm_version" >&2
    exit 1
  fi
}

if [ -n "${LLVM_VERSION:-}" ]; then
  install_llvm "$LLVM_VERSION"
  sanity_check "$LLVM_VERSION"
else
  install_llvm
  sanity_check
fi
