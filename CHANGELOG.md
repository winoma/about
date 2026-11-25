## [2.1-LPT] - 2026-11-25

### Added
- **WinOma Scan:** read-only system audit with a 0-100 score, evidence labels and top fixes. Startup count ignores apps disabled in Task Manager.
- **DevBuild & Error Logging (`DEVBUILD` toggle):** Added a debug mode switch (`DEVBUILD=1` / `0`). In DevBuild mode, blocked registry writes/deletes and service permission errors are captured in `%temp%\winoma_tweaker.log` and summarized on screen instead of failing silently.
- **Console Environment Backup & Restore (`:console_restore`):** Automatically backs up existing `HKCU\Console` settings (`CodePage`, `FaceName`, `VirtualTerminalLevel`, font properties) on launch and restores the user's original console state when exiting via `[0] Quit`.

### Fixed
- **Non-Elevated Explorer Restart (`:restart_explorer`):** Replaced the fixed 2-second timeout and elevated `start explorer.exe` fallback with an 8-second polling check. If Windows does not respawn the shell automatically, Explorer is launched via `runas /trustlevel:0x20000` to prevent running the entire desktop with administrator privileges.
- **Action Feedback Visibility:** Added a 3-second hold and failure counter output before `cls` in `:bl_item` and `:svc_toggle` so status messages (such as Edge uninstall results or access errors) remain readable before returning to the menu.
- **Windows 11 Widgets Cleanup (`:RemoveWidgets`):** Replaced blocked `reg add` calls with PowerShell `Set-ItemProperty` for `TaskbarDa` and removed the legacy Windows 10 `ShellFeedsTaskbarViewMode` key to eliminate false access errors on Windows 11.
