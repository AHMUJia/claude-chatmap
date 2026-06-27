# Claude ChatMap · Claude 会话索引

[![中文](https://img.shields.io/badge/中文-8b9bb4?style=for-the-badge)](README.md) [![English](https://img.shields.io/badge/English-2f6feb?style=for-the-badge)](README.en.md)

A local, **zero-dependency dashboard for all your Claude Code conversations**. It scans every session on your machine, groups them by folder, shows title / time / size and a content preview, lets you favorite & delete — and **double-click to resume any chat (`claude -r`) in a new WispTerm tab**. Pure Windows `mshta` + PowerShell, no install, no network.

---

> Still hunting through folders to find where that chat was opened?
> Still retyping a long project path and digging through the `/resume` picker just to continue?
> Still unsure which conversation has quietly ballooned and is eating your usage?
> — **One panel solves all of it.**

- 🗺 **Find it instantly** — every chat is auto-grouped into a folder tree by where it was opened. No more needle-in-a-haystack.
- ⚡ **Resume in one double-click** — opens a new WispTerm tab, `cd`s into the project dir and restores the chat: **no typing paths, no clicking resume, no scrolling the picker** (falls back to plain PowerShell if WispTerm isn't installed).
- 📦 **See the size** — every conversation shows its size (KB/MB), so bloated chats that silently burn your quota are obvious at a glance.
- 🔍 **Searchable** — by title / path / date, plus a content preview (last question & last reply) so you know what a chat was about without opening it.
- ⭐ **Favorite & manage** — star the ones you use, right-click to delete the stale ones; one-click CN/EN toggle.

---

## Screenshots

Folder tree (left) · conversation list (middle) · detail panel (right) · one-click CN/EN toggle.

![English UI](shoot_EN.png)

![Chinese UI](shoot_CN.png)

---

## Features

- 🗂 **Folder tree** — folders that contain conversations, in real path hierarchy (case-insensitive merge, sorted by most-recent use).
- 📋 **Conversation list** — colored icon + title + relative time + **session size (MB)** + folder.
- ⭐ **Favorites** — star to favorite, view them together.
- 🔍 **Search** — plain text or `folder:` / `date:` / `after:` / `before:` syntax, with keyword highlight.
- 📄 **Detail panel** (single-click) — full title / time / size / path, content preview (last question + last reply), related conversations in the same folder, quick actions.
- ▶ **One-click resume** — **double-click** a chat → new WispTerm tab, `cd` into the project, `claude -r <id>` (falls back to a standalone PowerShell window if WispTerm isn't running).
- 🗑 **Delete** — moves the session `.jsonl` to `deleted/` (removed from Claude, still recoverable).
- 🪟 Frameless window + Win11 rounded corners/shadow + compact/comfortable density + remembered settings + **one-click CN/EN toggle**.

---

## Requirements

- Windows 10/11 (ships with `mshta.exe` and PowerShell).
- [Claude Code](https://claude.com/claude-code) installed (`claude` on PATH).
- Sessions live in `%USERPROFILE%\.claude\projects\` by default (auto-detected; override with env var `CLAUDE_PROJECTS_DIR`).
- **(Optional, for resuming inside WispTerm)** [WispTerm](https://github.com/xuzhougeng/wispterm) **v1.30.1+** and its `wisptermctl` client.

---

## Quick start

1. Download/clone this repo anywhere (the whole folder is path-adaptive — put it wherever).
2. Double-click `index.hta`. **It auto-refreshes on every open** (shows last data instantly, then rescans `*.jsonl`); you can also click 🔄 Refresh anytime.
3. Single-click a conversation for details; **double-click** to resume it.

> The "refresh + browse + details" features need no WispTerm and work out of the box. For "double-click to resume inside WispTerm", see the next section.

---

## WispTerm integration / how to connect

Resuming a chat prefers a **new tab in the running WispTerm**, connected via WispTerm's `wisptermctl` control API. Three steps:

### 1) Install WispTerm v1.30.1+ and drop in wisptermctl
- WispTerm: <https://github.com/xuzhougeng/wispterm> (**v1.30.1 or newer**; `spawn` was added in v1.30.0 and the agent-control response fixed in v1.30.1).
- Grab the `wisptermctl` for your platform (`wisptermctl.exe` on Windows) from WispTerm and put it **in this repo's folder** (next to `index.hta`). The binary is not bundled here.

### 2) Enable WispTerm's control API
Edit WispTerm's config at `%APPDATA%\wispterm\config` and add:
```
agent-control-enabled = true
```
then **restart WispTerm**. Verify (in any tab):
```
wisptermctl.exe panes
```
A JSON tab list means the API is live.

### 3) Use it
Double-click any conversation in Claude ChatMap and it runs:
```
wisptermctl spawn --cwd <project-dir> -- powershell -NoProfile -NoExit -Command "Set-Location <project-dir>; claude -r <session-id>"
```
= a new WispTerm tab, in the project dir, resuming that chat.

> If WispTerm isn't running or the API is off, it **automatically falls back** to a standalone PowerShell window running the same `claude -r` — functionality unaffected.

---

## Files

| File | Purpose |
|---|---|
| `index.hta` | Main UI (double-click to open; path-adaptive, locates sibling files). |
| `refresh.ps1` | Scans Claude sessions (`*.jsonl`) → builds `index.json`; auto-detects the projects dir. |
| `resume-in-wispterm.ps1` | Resume: new WispTerm tab `claude -r`, falls back to standalone PowerShell. |
| `delete-conv.ps1` | Delete: moves the session `.jsonl` to `deleted/`. |
| `style-window.ps1` | Win11 rounded corners + shadow for the frameless window (DWM/Win32). |
| `winmin.ps1` | Minimize the frameless window (Win32 ShowWindow). |
| `index.json` | Generated data (**local, gitignored**). |
| `settings.json` | UI settings/favorites (**local, gitignored**). |
| `wisptermctl.exe` | WispTerm control client (**bring your own, gitignored**). |

---

## How it works

![How it works](how-it-works.png)

- Title priority: `custom-title` > `ai-title` > first user message; empty sessions and `[Request interrupted…]` are filtered out.
- The session's folder is read from the `cwd` field inside the jsonl (not the dir name, to avoid CJK encoding loss).
- `claude` must be launched via PowerShell (on Windows it's an npm script, so it can't be run directly by `spawn -- claude`).

---

## Customization / sharing

- The whole folder is **path-adaptive** — drop it anywhere, no hardcoded paths to change.
- Different machine / custom sessions dir: set env var `CLAUDE_PROJECTS_DIR`, or make sure `%USERPROFILE%\.claude\projects` exists.
- If `claude` isn't on the system PATH (only provided by a PowerShell profile), remove `-NoProfile` in `resume-in-wispterm.ps1`.

---

## Troubleshooting

- **Double-click opens PowerShell instead of WispTerm** — WispTerm isn't running, or `agent-control-enabled` isn't set/restarted. Run `wisptermctl.exe panes` to confirm the API is live.
- **Resume blocked by a "drive-root" guard** — your PowerShell `$PROFILE` has a custom guard; the script `Set-Location`s into the project dir first, so this normally won't trigger.
- **Blank UI / script error** — make sure `index.hta`'s document mode isn't `IE=edge`/`IE=10+` (that forces a Windows title bar); this project uses `IE=9` for the frameless window.
- **No rounded corners / shadow** — some Win11 themes/GPU settings dim the shadow; this is expected.

---

## Credits

- [WispTerm](https://github.com/xuzhougeng/wispterm) and its `wisptermctl` control API — what makes "resume right in the terminal" possible.
- [Claude Code](https://claude.com/claude-code) by Anthropic.

## License

MIT — see [LICENSE](LICENSE).
