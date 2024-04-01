# setup-llvm

This action sets up a specific version of LLVM on GitHub Actions, and adds the
command-line tools to the PATH.

## Usage

```yaml
- name: Setup LLVM
  uses: ZhongRuoyu/setup-llvm@v0
  with:
    llvm-version: 17
```

## Support Matrix

### Host OS

Currently, this action supports Debian/Ubuntu, macOS, and Windows runners.

### LLVM

The availability of LLVM major releases is determined by the upstream binary
distributors.

| OS            | Distributor                                                                                   |
| ------------- | --------------------------------------------------------------------------------------------- |
| Debian/Ubuntu | [LLVM Debian/Ubuntu nightly packages](https://apt.llvm.org/)                                  |
| macOS         | [Homebrew](https://brew.sh/)                                                                  |
| Windows       | [LLVM](https://github.com/llvm/llvm-project/releases) / [Chocolatey](https://chocolatey.org/) |

For each major release, the latest version in the series is installed.
For instance, specifying `llvm-version: 17` installs the latest LLVM 17 (i.e.,
17.0.6).

Support for the latest 5 major releases are tested regularly.

## See Also

This action does not support installing a specific minor/patch version of LLVM.
If you need that, or if your desired major release is not available, check out
[llvm-ports](https://github.com/ZhongRuoyu/llvm-ports), which provides Docker
images like `18.1.0-bookworm` and `11.1.0-bionic`.
