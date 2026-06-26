# Delete a Claude conversation: move its session .jsonl out of Claude's projects
# dir into a local trash folder (so it disappears from Claude / the index, but
# stays recoverable for a while). Called by index.hta right-click menu.
# ASCII-only on purpose (PowerShell 5.1 mis-reads non-BOM CJK as GBK).
param([Parameter(Mandatory=$true)][string]$Sid)
$ErrorActionPreference = 'SilentlyContinue'

$proj  = 'F:\.claude\projects'
$trash = Join-Path $PSScriptRoot 'deleted'
if (-not (Test-Path -LiteralPath $trash)) { New-Item -ItemType Directory -Path $trash | Out-Null }

$f = Get-ChildItem -LiteralPath $proj -Recurse -Filter "$Sid.jsonl" -File | Select-Object -First 1
if ($f) {
  $dest = Join-Path $trash $f.Name
  if (Test-Path -LiteralPath $dest) {
    $stamp = $f.LastWriteTime.ToString('yyyyMMdd-HHmmss')
    $dest = Join-Path $trash ($f.BaseName + "." + $stamp + ".jsonl")
  }
  Move-Item -LiteralPath $f.FullName -Destination $dest -Force
  Write-Output ("MOVED: " + $f.FullName + " -> " + $dest)
} else {
  Write-Output ("NOT FOUND: " + $Sid + ".jsonl")
}
