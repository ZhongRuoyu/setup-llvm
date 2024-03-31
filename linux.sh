#!/bin/sh

set -eux

install_llvm() {
  tmpdir="$(mktemp -d)"
  trap 'rm -rf -- "$tmpdir"' EXIT
  cd "$tmpdir"
  curl -fsSL https://apt.llvm.org/llvm.sh -o llvm.sh
  chmod +x llvm.sh
  sudo ./llvm.sh "$@"
}

if ! apt-get --version >/dev/null; then
  echo "Currently, this action only supports Debian-based systems." >&2
  exit 1
fi

if [ -n "${LLVM_VERSION:-}" ]; then
  install_llvm "$LLVM_VERSION"
else
  install_llvm
fi
