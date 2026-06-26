$ErrorActionPreference = 'SilentlyContinue'

# Auto-detect Claude Code's projects directory (override with env CLAUDE_PROJECTS_DIR).
$projRoot = $null
$cands = @()
if ($env:CLAUDE_PROJECTS_DIR) { $cands += $env:CLAUDE_PROJECTS_DIR }
if ($env:CLAUDE_CONFIG_DIR)   { $cands += (Join-Path $env:CLAUDE_CONFIG_DIR 'projects') }
$cands += (Join-Path $env:USERPROFILE '.claude\projects')
foreach ($c in $cands) { if ($c -and (Test-Path -LiteralPath $c)) { $projRoot = $c; break } }
if (-not $projRoot) {
  Write-Output ("Claude projects dir not found. Tried: " + ($cands -join '; '))
  return
}
$outJson  = Join-Path $PSScriptRoot 'index.json'

function Unescape($s){
    if ($null -eq $s) { return $s }
    $s = $s -replace '\\\\','\'
    $s = $s -replace '\\"','"'
    $s = $s -replace '\\/','/'
    return $s
}
# 预览用：把转义/换行清理成单行
function Clean($s){
    if ($null -eq $s) { return '' }
    $s = $s -replace '\\n',' ' -replace '\\r',' ' -replace '\\t',' '
    $s = $s -replace '\\"','"' -replace '\\\\','\'
    $s = $s -replace '\s+',' '
    return $s.Trim()
}

$sessions = New-Object System.Collections.Generic.List[object]
$files = Get-ChildItem -LiteralPath $projRoot -Recurse -Filter *.jsonl -File

foreach ($f in $files) {
    $cwd = $null; $title = $null; $custom = $null; $firstUser = $null
    $lastUser = $null; $lastAssist = $null
    foreach ($line in [System.IO.File]::ReadLines($f.FullName)) {
        if (-not $cwd -and $line -match '"cwd":"((?:[^"\\]|\\.)*)"') {
            $cwd = Unescape $matches[1]
        }
        if ($line -match '"type":"custom-title"') {
            if ($line -match '"customTitle":"((?:[^"\\]|\\.)*)"') { $custom = Unescape $matches[1] }
        }
        if ($line -match '"type":"ai-title"') {
            if ($line -match '"aiTitle":"((?:[^"\\]|\\.)*)"') { $title = Unescape $matches[1] }
        }
        if ($line -match '"type":"user"') {
            if ($line -match '"text":"((?:[^"\\]|\\.)*)"') {
                $raw = $matches[1]
                $t = Unescape $raw
                if ($t -notmatch '^<command' -and $t -notmatch '^\[Request interrupted' -and $t.Trim().Length -gt 0) {
                    if (-not $firstUser) { $firstUser = $t.Substring(0, [Math]::Min(80, $t.Length)) }
                    $lastUser = $raw
                }
            }
        }
        if ($line -match '"type":"assistant"') {
            if ($line -match '"text":"((?:[^"\\]|\\.)*)"') { $lastAssist = $matches[1] }
        }
    }
    $name = if ($custom) { $custom } elseif ($title) { $title } elseif ($firstUser) { $firstUser } else { $null }
    # 跳过没有具体内容的空对话（无 custom-title / ai-title / 首句提问）
    if (-not $name) { continue }
    $sessions.Add([pscustomobject]@{
        title    = $name
        cwd      = if ($cwd) { $cwd } else { '(未知文件夹)' }
        sessionId= $f.BaseName
        modified = $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
        ts       = [int64]($f.LastWriteTime - (Get-Date '1970-01-01')).TotalSeconds
        size     = $f.Length
        lastUser = if ($lastUser)  { $u = Clean $lastUser;   $u.Substring(0, [Math]::Min(260, $u.Length)) } else { '' }
        lastReply= if ($lastAssist){ $a = Clean $lastAssist; $a.Substring(0, [Math]::Min(260, $a.Length)) } else { '' }
    })
}

$sorted = $sessions | Sort-Object ts -Descending
$json = $sorted | ConvertTo-Json -Depth 4
# 确保 UTF-8（无 BOM，方便 HTA fetch/读取一致）
[System.IO.File]::WriteAllText($outJson, $json, (New-Object System.Text.UTF8Encoding($false)))

Write-Output ("已生成: " + $outJson)
Write-Output ("对话数: " + $sessions.Count + "  涉及文件夹: " + (($sessions | Select-Object -ExpandProperty cwd -Unique).Count))


