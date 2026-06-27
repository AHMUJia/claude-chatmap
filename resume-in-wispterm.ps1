# Resume a Claude conversation inside the running WispTerm as a NEW tab.
# Strategy: bake the command into spawn so a powershell tab launches straight
# into `claude -r` — no polling / wait-for / send-text, so it's fast and never
# double-launches. Falls back to a standalone PowerShell window only when the
# WispTerm agent-control API is unreachable.
# Called by 对话总览.hta. Uses $PSScriptRoot to avoid CJK path literals.
param(
  [Parameter(Mandatory=$true)][string]$Cwd,
  [Parameter(Mandatory=$true)][string]$Sid
)
$ErrorActionPreference = 'SilentlyContinue'
$exe = Join-Path $PSScriptRoot 'wisptermctl.exe'

# cd into the project dir first (so Claude loads the right project), then resume.
$cwdEsc = $Cwd.Replace("'", "''")
$inner  = "Set-Location -LiteralPath '$cwdEsc'; claude -r $Sid"

# Is WispTerm available AND its agent-control API reachable?
# (No wisptermctl.exe / WispTerm not running / API off  ->  $reachable stays $false)
$reachable = $false
if (Test-Path -LiteralPath $exe) {
  try {
    $p = & $exe panes 2>$null
    if ($LASTEXITCODE -eq 0 -and $p) { $reachable = $true }
  } catch { $reachable = $false }
}

if ($reachable) {
  # New WispTerm tab: launch powershell straight into the resume command.
  & $exe spawn --cwd $Cwd -- powershell -NoProfile -NoExit -Command $inner 2>$null | Out-Null
} else {
  # Fallback (no WispTerm): standalone PowerShell window runs the same claude -r.
  Start-Process powershell -ArgumentList '-NoProfile','-NoExit','-Command',$inner
}
