#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$global:LLVM_PATH = ""
$global:llvm_stable_releases = @()

function Get-FromGitHubAPI {
  param(
    [string]$endpoint
  )

  $headers = @{}
  if (Test-Path env:SETUP_LLVM_GITHUB_TOKEN) {
    $headers["Authorization"] = "Bearer $env:SETUP_LLVM_GITHUB_TOKEN"
  }
  return Invoke-RestMethod "https://api.github.com/$endpoint" -Headers $headers
}

function Get-LLVMStableReleases {
  if ($global:llvm_stable_releases.Count -eq 0) {
    $tags = @()
    for ($page = 1; $true; ++$page) {
      $tags_on_page = (
        Get-FromGitHubAPI "repos/llvm/llvm-project/releases?page=$page&per_page=100"
      ).tag_name
      if ($tags_on_page.Count -eq 0) {
        break
      }
      $tags += $tags_on_page
    }
    $global:llvm_stable_releases = $tags |
    Select-String -Pattern "^llvmorg-(\d+(\.\d+)*)$" |
    ForEach-Object { $_.Matches.Groups[1].Value } |
    Sort-Object -Descending { [version] $_ }
  }
  return $global:llvm_stable_releases
}

function Get-CurrentLLVMStableRelease {
  return (Get-LLVMStableReleases | Select-Object -First 1).split(".")[0]
}

function Install-LLVM {
  param(
    [string]$version
  )

  $version_full = Get-LLVMStableReleases |
  Where-Object { $_.StartsWith("$version.") } |
  Select-Object -First 1

  $target = "$env:LOCALAPPDATA\Programs\llvm-$version_full"
  New-Item -ItemType Directory -Force -Path $target
  Set-Location $target

  $archive_basename = "clang+llvm-$version_full-x86_64-pc-windows-msvc"
  $archive_tar = "$archive_basename.tar"
  $archive = "$archive_tar.xz"
  try {
    Invoke-WebRequest "https://github.com/llvm/llvm-project/releases/download/llvmorg-$version_full/$archive" -OutFile $archive
  }
  catch {
    return $false
  }

  # tar on Windows hangs while extracting .tar.xz archives, so we process the
  # archive in two steps instead.
  # https://github.com/libarchive/libarchive/issues/1419

  unxz $archive
  if ($LASTEXITCODE -ne 0) {
    return $false
  }

  tar -xf $archive_tar
  if ($LASTEXITCODE -ne 0) {
    return $false
  }

  Remove-Item -Force $archive_tar
  Get-ChildItem -Force $archive_basename | Move-Item -Force -Destination $target

  $(
    Write-Output "$target\bin"
    Get-Content $env:GITHUB_PATH -Raw
  ) | Set-Content $env:GITHUB_PATH
  $env:PATH = "$target\bin;$env:PATH"

  $global:LLVM_PATH = $target
  return $true
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
    return $false
  }

  $target = "$env:PROGRAMFILES\LLVM"
  $(
    Write-Output "$target\bin"
    Get-Content $env:GITHUB_PATH -Raw
  ) | Set-Content $env:GITHUB_PATH
  $env:PATH = "$target\bin;$env:PATH"

  $global:LLVM_PATH = $target
  return $true
}

function Test-Sanity {
  param(
    [string]$version
  )

  $version_full = (
    clang --version |
    Select-Object -First 1 |
    Select-String -Pattern "\d+(\.\d+)*"
  ).Matches.Value
  if ($version_full.split(".")[0] -ne $version) {
    Write-Error "Expected LLVM major version $version, got $version_full"
    exit 1
  }
}

$LLVM_VERSION = $env:LLVM_VERSION
if (!$LLVM_VERSION) {
  $LLVM_VERSION = Get-CurrentLLVMStableRelease
}
while ($true) {
  Install-LLVM -version $LLVM_VERSION
  if ($LASTEXITCODE -eq 0) {
    break
  }
  Install-LLVMFromChocolatey -version $LLVM_VERSION
  if ($LASTEXITCODE -eq 0) {
    break
  }
  Write-Error "Failed to install LLVM $LLVM_VERSION"
  exit 1
}
Test-Sanity -version $LLVM_VERSION

Write-Output "LLVM $LLVM_VERSION has been installed to $global:LLVM_PATH"
Write-Output "LLVM_PATH=$global:LLVM_PATH" | Set-Content "$env:GITHUB_ENV"
