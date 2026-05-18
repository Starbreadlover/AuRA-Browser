param(
  [string]$Path = ".\dist"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Path)) {
  throw "Path not found: $Path"
}

$patterns = @(
  "Firefox",
  "Mozilla",
  "firefox-logo",
  "mozilla-logo"
)

$hits = @()

Get-ChildItem -Path $Path -Recurse -File | ForEach-Object {
  try {
    $fileHits = Select-String -Path $_.FullName -Pattern $patterns -SimpleMatch -ErrorAction Stop
    if ($fileHits) {
      $hits += $fileHits
    }
  } catch {
    # Binary or locked files can be reviewed separately.
  }
}

if ($hits.Count -eq 0) {
  Write-Host "No obvious protected branding strings found in $Path"
  exit 0
}

Write-Host "Potential branding issues found:"
$hits | ForEach-Object {
  Write-Host "$($_.Path):$($_.LineNumber): $($_.Line.Trim())"
}

exit 1
