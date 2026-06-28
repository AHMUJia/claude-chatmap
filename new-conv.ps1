# Start a NEW Claude conversation (`claude`, no -r) inside the running WispTerm as
# a new tab; optionally create the target folder first. Falls back to a standalone
# PowerShell window when the WispTerm agent-control API is unreachable, and (once)
# tells the user how to enable the WispTerm integration.
# Called by index.hta. Uses $PSScriptRoot to avoid CJK path literals. ASCII only.
param(
  [Parameter(Mandatory=$true)][string]$Cwd,
  [switch]$MkDir
)
$ErrorActionPreference = 'SilentlyContinue'
$exe = Join-Path $PSScriptRoot 'wisptermctl.exe'

# Create the folder if asked (or if it simply does not exist yet).
if ($MkDir -or -not (Test-Path -LiteralPath $Cwd)) {
  try { New-Item -ItemType Directory -Path $Cwd -Force | Out-Null } catch {}
}

# cd into the (now existing) folder, then start a fresh chat.
$cwdEsc = $Cwd.Replace("'", "''")
$inner  = "Set-Location -LiteralPath '$cwdEsc'; claude"

# Is WispTerm available AND its agent-control API reachable?
# (No wisptermctl.exe / WispTerm not running / API off  ->  $reachable stays $false)
$exeExists = Test-Path -LiteralPath $exe
$reachable = $false
if ($exeExists) {
  try {
    $p = & $exe panes 2>$null
    if ($LASTEXITCODE -eq 0 -and $p) { $reachable = $true }
  } catch { $reachable = $false }
}

if ($reachable) {
  # New WispTerm tab: launch powershell straight into a fresh `claude`.
  & $exe spawn --cwd $Cwd -- powershell -NoProfile -NoExit -Command $inner 2>$null | Out-Null
  return
}

# ---- Fallback: standalone PowerShell window runs the same fresh `claude`. ----
Start-Process powershell -ArgumentList '-NoProfile','-NoExit','-Command',$inner

# Show a one-time notice explaining why it did NOT open inside WispTerm and how to
# enable the integration. Shares the same marker file as resume-in-wispterm.ps1 so
# the user is never nagged twice.
$flag = Join-Path $PSScriptRoot '.wisp-notice-shown'
if (-not (Test-Path -LiteralPath $flag)) {
  if (-not $exeExists) {
    $msg = @"
This chat opened in a plain PowerShell window instead of a WispTerm tab,
because WispTerm integration is not set up yet.

To open chats inside WispTerm (one tab, no extra window):
  1. Install WispTerm v1.30.1 or newer
       https://github.com/xuzhougeng/wispterm
  2. In %APPDATA%\wispterm\config add:  agent-control-enabled = true
     then restart WispTerm.
  3. Put wisptermctl.exe in THIS folder (next to index.hta).

If you do not use WispTerm, you can ignore this -- plain PowerShell works fine.

(This notice is shown only once.)
"@
  } else {
    $msg = @"
This chat opened in a plain PowerShell window instead of a WispTerm tab.

wisptermctl.exe was found, but WispTerm's control API is not reachable. Check:
  - WispTerm v1.30.1+ is actually running.
  - %APPDATA%\wispterm\config has:  agent-control-enabled = true
    (restart WispTerm after changing it).
  - Verify in any tab:  wisptermctl.exe panes   (should print JSON).

(This notice is shown only once.)
"@
  }
  try {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
      $msg, 'Claude ChatMap - WispTerm not active',
      [System.Windows.Forms.MessageBoxButtons]::OK,
      [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
  } catch {
    try { (New-Object -ComObject WScript.Shell).Popup($msg, 0, 'Claude ChatMap - WispTerm not active', 64) | Out-Null } catch {}
  }
  New-Item -ItemType File -Path $flag -Force | Out-Null
}
