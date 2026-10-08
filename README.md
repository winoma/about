# ⚡ WinOMA Pack — Windows Optimization & Architecture Framework

<p align="center">
  <img src="https://media.moderngamer.com/wp-content/uploads/2025/09/ultimate_windows_11_gaming_optimization_hvkt7.jpg?strip=all" alt="WinOMA Optimization Setup" width="100%"/>
</p>

> **WinOMA (Windows Optimization & Maintenance Architecture)** is an enterprise-grade, data-driven optimization suite designed to eliminate system latency, remove OS bloatware, and enhance gaming frametime consistency on **Windows 10** and **Windows 11**.

---

## 🎯 Key Principles

* **Zero Placebo Policy:** Every tweak is empirically tested using benchmark metrics (CapFrameX, LatencyMon).
* **Guaranteed Rollback (Undo Engine):** Full backup logging (`undo-log.jsonl`) ensures 100% reversible changes without corrupting OS files.
* **Safe Power Plan Clones:** Never overwrites default Windows power profiles; duplicates active plans safely.
* **Hardware-Aware Execution:** Auto-detects Laptop vs. Desktop, Intel Hybrid CPUs (P/E cores), and OS builds (Windows 10 vs. Windows 11 23H2/24H2).

---

## 🛠 Framework Architecture

<p align="center">
  <img src="https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/media/tcpip-performance-known-issues/check-autotuning-level-powershell.png" alt="PowerShell Automation Logs" width="80%"/>
</p>

```text
WinOMA_Pack/
├── Engine/
│   ├── BackupEngine/
│   │   └── WinOMA.Backup.ps1    # Logging, State Tracking & Clean Rollback
│   ├── PreFlight/
│   │   └── Check-Environment.ps1# Hardware/OS Compatibility Inspector
│   ├── Catalog/
│   │   └── catalog.json         # Structured Database of Tweaks
│   └── Apply-WinOMA.ps1         # Main Execution Runner & Safety Gating
└── README.md<img width="2172" height="724" alt="banner" src="https://github.com/user-attachments/assets/69053718-c487-44a3-84e9-c929e535819b" />
