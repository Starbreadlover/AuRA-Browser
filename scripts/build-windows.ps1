param(
  [Parameter(Mandatory = $true)]
  [string]$FirefoxSource,

  [ValidateSet("release", "artifact")]
  [string]$Config = "release"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$mozconfigName = if ($Config -eq "artifact") { "aura-windows-artifact.mozconfig" } else { "aura-windows-release.mozconfig" }
$mozconfigSource = Join-Path $repoRoot "mozconfigs\$mozconfigName"
$mozconfigTarget = Join-Path $FirefoxSource ".mozconfig"
$machPath = Join-Path $FirefoxSource "mach"

if (-not (Test-Path $machPath)) {
  throw "FirefoxSource does not look like a Firefox checkout: $FirefoxSource"
}

Copy-Item -Path $mozconfigSource -Destination $mozconfigTarget -Force
Write-Host "Copied $mozconfigName to $mozconfigTarget"

Push-Location $FirefoxSource
try {
  Write-Host "Running mach build. Use a MozillaBuild shell for best results."
  & .\mach build
  & .\mach package
} finally {
  Pop-Location
}
