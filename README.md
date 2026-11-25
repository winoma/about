<div align="center">

<picture>
  <source media="(max-width: 600px) and (hover: none) and (pointer: coarse)" srcset="assets/banner-mobile.svg">
  <img src="assets/banner-animated.svg" alt="WinOma: PC Performance Experts" width="100%">
</picture>

# WinOma Optimization Service

<a href="https://winoma.app">
  <img src="https://readme-typing-svg.demolab.com?font=JetBrains+Mono&weight=600&size=20&duration=3000&pause=1000&color=8A2BE2&center=true&vCenter=true&width=650&lines=Low+System+Latency+%26+Stable+Frametimes;Benchmarked+%26+Fully+Reversible;Minimized+Input+Lag+%26+Boost+FPS" alt="Typing SVG" />
</a>

[![Supported OS](https://img.shields.io/badge/Windows-11%20%7C%2010-0078D4?style=for-the-badge&logo=windows)](#faq)
[![Status](https://img.shields.io/badge/Status-Active%20Development-orange?style=for-the-badge&logo=github)](https://github.com/winoma/about)
[![Anti-Cheat Safe](https://img.shields.io/badge/Anti--Cheat%20Safe-Vanguard%20%7C%20EAC%20%7C%20BattlEye-2ea44f?style=for-the-badge&logo=shield&logoColor=white)](#faq)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

</div>

---

## ℹ️About

Are you facing performance bottlenecks, high resource usage, inefficient code or system latency issues?

**WinOma Optimization Service** is founded by **Omar Ilyasov** ([omarizzw](https://github.com/omarizzw)) and Co-Founder **Metin Quliyev** ([t1nt1n](https://github.com/t1nt1n)). Based in Baku, Azerbaijan and working remotely with clients worldwide, we specialize in high-performance software development, code optimization, system automation and deep Windows OS tuning. Combining fundamental computer engineering principles with practical software design, we deliver custom tweaks and maximum performance for your PC or laptop.

**WinOma** (Windows Optimization & Maintenance Architecture) is a data-driven optimization framework for **Windows 11** (main target) and **Windows 10** (best effort). It targets system latency, background overhead and frametime consistency, with every change measured, logged and reversible where the engine supports it.

> **Status:** active development. The Full and Ultimate profiles are being tested and are not yet released. Tweaks marked `unproven` in the catalog are blocked by default until measured.

---

## 💻What We Can Do

- **Software Development & Architecture:** clean, reliable and scalable applications tailored to your technical requirements.
- **Performance Optimization:** refactoring code bases, reducing CPU/RAM overhead and eliminating system bottlenecks for faster execution.
- **OS & System-Level Tuning:** fine-tuning Windows settings, managing services and telemetry, debloating unnecessary background apps and optimizing low-level configuration for peak gaming and work performance.
- **Hardware Optimization:** CPU/GPU affinity, MSI (Message Signaled Interrupts) mode and interrupt affinity policies for minimum latency.
- **Custom Packs & Automation:** safe PowerShell, Batch and custom scripts to automate routine tasks, debloat OS environments and deploy registry tweaks.
- **In-Game Performance Optimization:** fewer frame drops, FPS fluctuations and micro-stutters. A fully optimized OS and game configuration with stable frametimes and minimal input lag.
- **Monitor Setup & Calibration:** individual monitor tuning for color accuracy, optimal scaling, better display responsiveness and an immersive viewing experience.

---

## 📋How We Work

1. **Audit:** hardware, drivers, BIOS, power/thermal profile and the current OS state.
2. **Baseline:** repeatable benchmarks (CapFrameX, in-game benchmark maps) before anything is changed.
3. **One change at a time:** every tweak is measured, and anything that doesn't help is rolled back.
4. **Verification:** LatencyMon, HWiNFO and frametime graphs to confirm the result is stable and not just a higher average.

---

## 💎Key principles

- **Measure first.** Every tweak carries an evidence label: `proven`, `situational`, `unproven` or `placebo`. Placebo tweaks are never applied, and unproven ones need an explicit flag.
- **Reversible changes.** Registry and power-plan changes are written to an undo log (`undo-log.jsonl`) before they happen, and `Undo-WinOma` restores them in reverse order. Removal of apps and services is not covered by the undo engine yet, so those tools warn before acting.
- **Safe power plans.** WinOma clones the active power plan and edits the copy. Your original plan is never modified, and undo switches back and deletes the clone.
- **Hardware-aware.** Pre-flight detects laptop vs desktop, hybrid Intel CPUs (P/E cores), administrator rights and the Windows build, then skips tweaks that don't fit the machine.
- **Restore point and log.** A restore point is requested before changes (Windows limits it to one per 24 hours by default), and every run writes a log and a JSON report to `C:\ProgramData\WinOma\Logs`.

---

## ⚙️Profiles: Full and Ultimate

| | **⚡Full** | **🔥Ultimate** |
|---|---|---|
| For | Daily PCs, work and gaming | Dedicated competitive gaming PCs |
| Approach | Low-risk, stable, secure | Aggressive, maximum low latency |
| Trade-offs | None expected | May reduce security, power saving or convenience |
| Confirmation | Standard | User must type `I UNDERSTAND` |
| Includes | Safe and moderate tweaks | Full + Ultimate-only tweaks |

Advanced-risk tweaks are never applied in Full. Windows security features that cost performance (such as Memory Integrity) are Ultimate-only, with a clear warning.

---

## 🔍WinOma Scan

**WinOma Scan** is a lightweight, **read-only** diagnostic utility that evaluates your system's latency posture and overall readiness in seconds. It analyzes key OS and hardware bottlenecks to generate a **0–100 performance score**, making zero modifications to your system and collecting no personal data.

 <picture>
  <source media="(max-width: 600px) and (hover: none) and (pointer: coarse)" srcset="assets/scan-demo-mobile.svg">
  <img src="assets/scan-demo.svg" alt="WinOma Scan running a read-only audit" width="100%">
</picture>

```powershell
powershell -ExecutionPolicy Bypass -File .\WinOma_Scan.ps1
```

---

## 🛠️Tools in this repository

- 🟢 **WinOma Scan** (Safe, read-only): system latency and health audit with a 0–100 score.
- 🟢 **WinOma Safe Performance Tweaks** (Safe): conservative tweaks (Power Throttling, Game DVR) with automatic backup and restore.
- 🟡 **WinOma System Tweaker** (Moderate): performance, privacy and UI tweaks with live status, plus Restore Defaults.
- 🟡 **WinOma Services (PC)** (Moderate): disables unneeded Windows services and background components.
- 🟡 **WinOma Bloatware Remover** (Moderate): menu-driven removal of preinstalled apps (Copilot, Teams, Clipchamp, Feedback Hub and more), one by one or all at once.
- 🔴 **WinOma USB Power Tweak** (Advanced): USB device and root hub power-management tuning.

> [!CAUTION]
> **Before you run anything:** Create a system restore point, inspect the script contents, and test on a non-critical machine first.

---

## 📄Disclaimer

Some tweaks reduce background services, convenience features or security protections. Ultimate-profile tweaks can lower security and increase power use and heat, so don't use them on work PCs or laptops running on battery. Results vary by hardware. Use at your own risk.

This project is licensed under the [MIT License](LICENSE).

---

## 📫Contact Us

<div align="center">

[![WEBSITE](https://img.shields.io/badge/-WINOMA.APP-8A2BE2?style=for-the-badge&logo=googlechrome&logoColor=white)](https://winoma.app)
[![INSTAGRAM](https://img.shields.io/badge/-WINOMA.AZ-E4405F?style=for-the-badge&logo=instagram&logoColor=white)](https://instagram.com/winoma.az)
[![MAIN CHANNEL](https://img.shields.io/badge/-MAIN%20CHANNEL-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/win_oma)
[![RESULTS](https://img.shields.io/badge/-RESULTS-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/winoma_results)

</div>

- E-Mail: [hello@winoma.app](mailto:hello@winoma.app)
- Telegram: [@omarizzww](https://t.me/omarizzww)

---

## FAQ

<details>
<summary><b>Does WinOma work on laptops without draining the battery?</b></summary>

Yes. WinOma detects the chassis and power source automatically. On laptops, battery-draining tweaks are bypassed, and EcoQoS policies are applied to keep background apps on E-Cores.

</details>

<details>
<summary><b>Will this trigger anti-cheat software (VALORANT Vanguard, Easy Anti-Cheat)?</b></summary>

WinOma uses native Windows APIs, official group policies and registry keys. It does not patch system kernels or inject code into games.

</details>

<details>
<summary><b>How is WinOma different from free tweak scripts?</b></summary>

Most free tools apply generic, untested registry files. WinOma is benchmark-driven, labels every tweak by evidence, logs registry and power-plan changes so they can be undone in reverse order, and detects hybrid CPU architectures.

</details>

<details>
<summary><b>Does WinOma work on plenty of games?</b></summary>

Yes. Unlike many services that are tied to one specific game, WinOma optimizes your entire system, so all your games benefit.

</details>

---

## 🤝Work With Us

Send us a message with your PC or laptop model, what is going wrong (FPS drops, stutters, latency, noise or heat) and your goals.

Whether you need custom software built from scratch, deep code optimization or system-wide latency reduction, feel free to get in touch.

---

<div align="center">

**WinOma: PC Performance Experts**

</div>
