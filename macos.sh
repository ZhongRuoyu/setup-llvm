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

if [ -n "${LLVM_VERSION:-}" ]; then
  install_llvm "$LLVM_VERSION"
else
  install_llvm
fi
