#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

function Get-CurrentLLVMStableRelease {
  return (
    (
      Invoke-RestMethod "https://community.chocolatey.org/api/v2/Packages()?`$filter=(Id eq 'llvm') and (IsPrerelease eq false)"
    ).properties.Version |
    Sort-Object -Descending { [version] $_ } |
    Select-Object -First 1
  ).split(".")[0]
}

function Install-LLVMFromChocolatey {
  param(
    [string]$version
  )

  $incremented_version = [int]$version + 1
  $version_full = (
    Invoke-RestMethod "https://community.chocolatey.org/api/v2/Packages()?`$filter=(Id eq 'llvm') and (IsPrerelease eq false) and (Version ge '$version') and (Version lt '$incremented_version')"
  ).properties.Version |
  Sort-Object -Descending { [version] $_ } |
  Select-Object -First 1
  choco install llvm `
    --allow-downgrade `
    --no-progress `
    --yes `
    --version="$version_full"
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to install LLVM $version_full"
    exit 1
  }
}

function Test-Sanity {
  param(
    [string]$version
  )

  $llvm_version = (
    clang --version |
    Select-Object -First 1 |
    Select-String -Pattern "\d+(\.\d+)*"
  ).Matches.Value
  if ($llvm_version.split(".")[0] -ne $version) {
    Write-Error "Expected LLVM major version $version, got $llvm_version"
    exit 1
  }
}

$LLVM_VERSION = $env:LLVM_VERSION
if (!$LLVM_VERSION) {
  $LLVM_VERSION = Get-CurrentLLVMStableRelease
}
Install-LLVMFromChocolatey -version $LLVM_VERSION
Test-Sanity -version $LLVM_VERSION
