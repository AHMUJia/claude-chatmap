# Minimize the borderless HTA window (no caption => no native minimize box).
# Called (hidden) by index.hta's minimize button. ASCII-only.
$ErrorActionPreference = 'SilentlyContinue'
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WMin {
  public delegate bool Proc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(Proc p, IntPtr l);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
}
"@
$script:found = [IntPtr]::Zero
$cb = [WMin+Proc]{
  param($h,$l)
  if(-not [WMin]::IsWindowVisible($h)){ return $true }
  $cn = New-Object System.Text.StringBuilder 256
  [void][WMin]::GetClassName($h,$cn,256)
  if($cn.ToString() -eq "HTML Application Host Window Class"){
    $tn = New-Object System.Text.StringBuilder 256
    [void][WMin]::GetWindowText($h,$tn,256)
    if($tn.ToString() -like "*Claude*"){ $script:found = $h; return $false }
  }
  return $true
}
[void][WMin]::EnumWindows($cb, [IntPtr]::Zero)
if($script:found -ne [IntPtr]::Zero){ [void][WMin]::ShowWindow($script:found, 6) }   # SW_MINIMIZE
