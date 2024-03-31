#!/bin/sh

set -eux

current_llvm_stable() {
  curl -fsSL https://apt.llvm.org/llvm.sh |
    sed -En 's/^CURRENT_LLVM_STABLE=([0-9]+)$/\1/p'
}

install_llvm() {
  llvm_version="$1"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf -- "$tmpdir"' EXIT
  cd "$tmpdir"
  curl -fsSL https://apt.llvm.org/llvm.sh -o llvm.sh
  chmod +x llvm.sh
  # Set DPKG_FORCE to overwrite because the packages may conflict with the
  # pre-installed ones from the GitHub Actions runner image.
  sudo env DPKG_FORCE=overwrite ./llvm.sh "$llvm_version" all
}

setup_llvm_path() {
  llvm_version="$1"
  echo "/usr/lib/llvm-$llvm_version/bin" >>"$GITHUB_PATH"
  PATH="/usr/lib/llvm-$llvm_version/bin:$PATH"
  export PATH
}

sanity_check() {
  llvm_version="$(llvm-config --version)"
  if [ "$(echo "$llvm_version" | cut -d. -f1)" != "$1" ]; then
    echo "Expected LLVM major version $1, got $llvm_version" >&2
    exit 1
  fi
}

if ! apt-get --version >/dev/null; then
  echo "Currently, this action only supports Debian-based systems." >&2
  exit 1
fi

LLVM_VERSION="${LLVM_VERSION:-$(current_llvm_stable)}"
install_llvm "$LLVM_VERSION"
setup_llvm_path "$LLVM_VERSION"
sanity_check "$LLVM_VERSION"
