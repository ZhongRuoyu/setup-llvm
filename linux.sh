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

sanity_check() {
  llvm_config="llvm-config${1:+-$1}"
  llvm_version="$("$llvm_config" --version)"
  llvm_major_version="$(echo "$llvm_version" | cut -d. -f1)"
  if [ "$#" -eq 1 ] && [ "$llvm_major_version" != "$1" ]; then
    echo "Expected LLVM major version $1, got $llvm_version" >&2
    exit 1
  fi
}

if ! apt-get --version >/dev/null; then
  echo "Currently, this action only supports Debian-based systems." >&2
  exit 1
fi

if [ -n "${LLVM_VERSION:-}" ]; then
  install_llvm "$LLVM_VERSION"
  sanity_check "$LLVM_VERSION"
else
  install_llvm
  sanity_check
fi
