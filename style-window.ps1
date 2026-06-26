# Give the borderless HTA window Win11-style rounded corners + drop shadow.
# Adds WS_THICKFRAME (enables DWM shadow + resizable, no title bar) and sets
# the DWM corner preference to ROUND. Launched (hidden) by index.hta on startup.
# ASCII-only (PowerShell 5.1 mis-reads non-BOM CJK as GBK).
$ErrorActionPreference = 'SilentlyContinue'
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WStyle {
  public delegate bool Proc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(Proc p, IntPtr l);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetClassLongPtr(IntPtr h, int i);
  [DllImport("user32.dll")] public static extern IntPtr SetClassLongPtr(IntPtr h, int i, IntPtr v);
  [DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr h, int attr, ref int val, int sz);
}
"@
$script:found = [IntPtr]::Zero
$cb = [WStyle+Proc]{
  param($h,$l)
  if(-not [WStyle]::IsWindowVisible($h)){ return $true }
  $cn = New-Object System.Text.StringBuilder 256
  [void][WStyle]::GetClassName($h,$cn,256)
  if($cn.ToString() -eq "HTML Application Host Window Class"){
    $tn = New-Object System.Text.StringBuilder 256
    [void][WStyle]::GetWindowText($h,$tn,256)
    if($tn.ToString() -like "*Claude*"){ $script:found = $h; return $false }
  }
  return $true
}

$DWMWA_CORNER   = 33
$ROUND          = 2
$GCL_STYLE      = -26
$CS_DROPSHADOW  = 0x00020000

$h = [IntPtr]::Zero
for($i=0; $i -lt 40; $i++){
  $script:found = [IntPtr]::Zero
  [void][WStyle]::EnumWindows($cb, [IntPtr]::Zero)
  if($script:found -ne [IntPtr]::Zero){ $h = $script:found; break }
  Start-Sleep -Milliseconds 150
}
if($h -eq [IntPtr]::Zero){ Write-Output "HTA window not found"; return }

# Win11 rounded corners
$v = $ROUND
[void][WStyle]::DwmSetWindowAttribute($h, $DWMWA_CORNER, [ref]$v, 4)
# drop shadow without adding any non-client frame (keeps top filled, no resize strip)
try {
  $cs  = [WStyle]::GetClassLongPtr($h, $GCL_STYLE)
  $new = [IntPtr]([Int64]$cs -bor $CS_DROPSHADOW)
  [void][WStyle]::SetClassLongPtr($h, $GCL_STYLE, $new)
} catch {}
Write-Output ("styled hwnd=" + $h)
