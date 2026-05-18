param(
  [Parameter(Mandatory = $true)]
  [string]$FirefoxSource
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$overlayRoot = Join-Path $repoRoot "overlays\mozilla-central"
$machPath = Join-Path $FirefoxSource "mach"
$brandingBase = Join-Path $FirefoxSource "browser\branding\unofficial"
$brandingTarget = Join-Path $FirefoxSource "browser\branding\aura"

if (-not (Test-Path $overlayRoot)) {
  throw "Overlay directory not found: $overlayRoot"
}

if (-not (Test-Path $machPath)) {
  throw "FirefoxSource does not look like a Firefox checkout: $FirefoxSource"
}

if ((Test-Path $brandingBase) -and (-not (Test-Path $brandingTarget))) {
  Copy-Item -Path $brandingBase -Destination $brandingTarget -Recurse -Force
  Write-Host "Seeded browser\branding\aura from browser\branding\unofficial"
  Write-Host "Replace inherited placeholder art before distributing AuRA Browser."
}

Get-ChildItem -Path $overlayRoot -Recurse -File | ForEach-Object {
  $relative = $_.FullName.Substring($overlayRoot.Length).TrimStart('\', '/')
  $target = Join-Path $FirefoxSource $relative
  $targetDir = Split-Path -Parent $target

  if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
  }

  Copy-Item -Path $_.FullName -Destination $target -Force
  Write-Host "Copied $relative"
}

Write-Host ""
Write-Host "Overlay copied. Next:"
Write-Host "1. Copy one mozconfig from this repo to $FirefoxSource\.mozconfig"
Write-Host "2. Port patches from the patches directory into the Firefox checkout"
Write-Host "3. Run ./mach build from a MozillaBuild shell"
