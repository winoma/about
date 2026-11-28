# Changelog

WinOma Scan (`WinOma_Scan.ps1`) is the script published in this repository, and its version is the one shown in the scan window.
The remote tune-up tools are not published here and keep their own version numbers.

## WinOma Scan

### [1.3.0-beta] - 2026-11-28

#### Changed
- **Scan code format 2:** the check character now uses the Damm algorithm over GF(32), which catches every single mistyped character and every swap of two neighbouring characters. The old check (weighted sum mod 32) let some single typos through. Codes from 1.2.x (format 1) can still be decoded.
- **Clipboard notice:** the scan now says it is about to copy the scan code to the clipboard before it does, and reports when the copy fails.

#### Fixed
- **No false OK on missing data:** when Windows does not return the data a check needs (power plan, startup apps, memory usage, installed apps, boot time, boot settings), the check now shows N/A and is left out of the score instead of passing.

#### CI
- PSScriptAnalyzer workflow: pinned to PSScriptAnalyzer 1.25.0, uses the repository settings file (`PSScriptAnalyzerSettings.psd1`) and the same `actions/checkout` and `upload-sarif` versions as the Scorecard workflow.
- Corrected the version comments on pinned GitHub Actions.

### [1.2.0-beta] - 2026-11-25

#### Added
- Read-only system audit with a 0-100 score, evidence labels and top fixes. Startup count ignores apps disabled in Task Manager.

## WinOma Tweaker ++ (not published)

### [2.1-LPT] - 2026-11-25

#### Added
- **DevBuild & Error Logging (`DEVBUILD` toggle):** Added a debug mode switch (`DEVBUILD=1` / `0`). In DevBuild mode, blocked registry writes/deletes and service permission errors are captured in `%temp%\winoma_tweaker.log` and summarized on screen instead of failing silently.
- **Console Environment Backup & Restore (`:console_restore`):** Automatically backs up existing `HKCU\Console` settings (`CodePage`, `FaceName`, `VirtualTerminalLevel`, font properties) on launch and restores the user's original console state when exiting via `[0] Quit`.

#### Fixed
- **Non-Elevated Explorer Restart (`:restart_explorer`):** Replaced the fixed 2-second timeout and elevated `start explorer.exe` fallback with an 8-second polling check. If Windows does not respawn the shell automatically, Explorer is launched via `runas /trustlevel:0x20000` to prevent running the entire desktop with administrator privileges.
- **Action Feedback Visibility:** Added a 3-second hold and failure counter output before `cls` in `:bl_item` and `:svc_toggle` so status messages (such as Edge uninstall results or access errors) remain readable before returning to the menu.
- **Windows 11 Widgets Cleanup (`:RemoveWidgets`):** Replaced blocked `reg add` calls with PowerShell `Set-ItemProperty` for `TaskbarDa` and removed the legacy Windows 10 `ShellFeedsTaskbarViewMode` key to eliminate false access errors on Windows 11.
