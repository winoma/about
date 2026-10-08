<div align="center">

<img src="banner.png" alt="WinOma — PC Performance Experts" width="100%">

# WinOma Optimization Service

**PC performance experts: deep Windows tuning, low latency and stable frametimes.**

[![MAIN CHANNEL](https://img.shields.io/badge/-MAIN%20CHANNEL-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/win_oma)
[![RESULTS](https://img.shields.io/badge/-RESULTS-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/winoma_results)
[![CHAT ME](https://img.shields.io/badge/-CHAT%20ME-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/omarizzww)

</div>

---

## About

**WinOma** (Windows Optimization & Maintenance Architecture) is a data-driven optimization framework for **Windows 11** (main target) and **Windows 10** (best effort), built by **Omar Ilyasov** (**omarizzw**), a Software Engineer and Computer Engineering Specialist based in Baku, Azerbaijan, working remotely with clients worldwide.

It targets system latency, background overhead and frametime consistency, with every change measured, logged and reversible where the engine supports it.

> **Status:** active development. The Full and Ultimate profiles are being tested and are not yet released. Tweaks marked `unproven` in the catalog are blocked by default until measured.

---

## Key principles

* **Measure first.** Every tweak carries an evidence label: `proven`, `situational`, `unproven` or `placebo`. Placebo tweaks are never applied, and unproven ones need an explicit flag.
* **Reversible changes.** Registry changes and power-plan changes are written to an undo log (`undo-log.jsonl`) before they happen, and `Undo-WinOma` restores them in reverse order. Removal of apps and services is not covered by the undo engine yet, so those tools warn before acting.
* **Safe power plans.** WinOma clones the active power plan and edits the copy. Your original plan is never modified, and undo switches back and deletes the clone.
* **Hardware-aware.** Pre-flight detects laptop vs desktop, hybrid Intel CPUs (P/E cores), administrator rights and the Windows build, then skips tweaks that don't fit the machine.
* **Restore point and log.** A restore point is requested before changes (Windows limits it to one per 24 hours by default), and every run writes a log and a JSON report to `C:\ProgramData\WinOma\Logs`.

---

## Profiles: Full and Ultimate

| | **Full** | **Ultimate** |
|---|---|---|
| For | Daily PCs, work and gaming | Dedicated competitive gaming PCs |
| Approach | Low-risk tweaks that keep the system stable, secure and usable | Aggressive tweaks for maximum low latency |
| Trade-offs | None expected | May reduce security, power saving or convenience |
| Confirmation | Standard | Warning shown, the user must type `I UNDERSTAND` |
| Includes | Safe and moderate tweaks | Everything in Full plus Ultimate-only tweaks |

Advanced-risk tweaks are never applied in Full. Windows security features that cost performance (such as Memory Integrity) are Ultimate-only, with a clear warning.

---

## Measured Results (Before vs After)

*Tested on Intel Core i7-14650HX, RTX 5060 Laptop (115W), Windows 11 25H2:*

| Metric | Stock Windows | WinOMA Full | WinOMA Ultimate |
| :--- | :--- | :--- | :--- |
| **DPC Latency (Peak)** | 840 µs | 180 µs | **120 µs** |
| **1% Low FPS (CS2)** | 142 FPS | 185 FPS | **210 FPS** |
| **Frametime Spikes (>20ms)** | 14 / min | 2 / min | **0 / min** |
| **Timer Resolution Accuracy** | ±1.5 ms | ±0.05 ms | **±0.01 ms** |

*example

---

## How We work

1. **Audit:** hardware, drivers, BIOS, power/thermal profile and the current OS state.
2. **Baseline:** repeatable benchmarks (CapFrameX, in-game benchmark maps) before anything is changed.
3. **One change at a time:** every tweak is measured, and anything that doesn't help is rolled back.
4. **Verification:** LatencyMon, HWiNFO and frametime graphs to confirm the result is stable and not just a higher average.

---

## What We can do

| Area | What you get |
|---|---|
| **Software Development & Architecture** | Clean, reliable and scalable applications tailored to your technical requirements. |
| **Performance Optimization** | Refactoring code bases, reducing CPU/RAM overhead and eliminating system bottlenecks for faster execution. |
| **OS & System-Level Tuning** | Fine-tuning Windows settings, managing services and telemetry, debloating unnecessary background apps and optimizing low-level configuration for peak gaming and work performance. |
| **Hardware Optimization** | CPU/GPU affinity, MSI (Message Signaled Interrupts) mode and interrupt affinity policies for minimum latency. |
| **Custom Packs & Automation** | Safe PowerShell, Batch and custom scripts to automate routine tasks, debloat OS environments and deploy registry tweaks. |
| **In-Game Performance Optimization** | Fewer frame drops, FPS fluctuations and micro-stutters. A fully optimized OS and game configuration with stable frametimes and minimal input lag. |
| **Monitor Setup & Calibration** | Individual monitor tuning for color accuracy, optimal scaling, better display responsiveness and an immersive viewing experience. |

---

## Tools in this repository

| Tool | Description | Risk |
|---|---|---|
| **WinOma Safe Performance Tweaks** | Conservative tweaks (Power Throttling, Game DVR) with automatic backup and restore. | Safe |
| **WinOma System Tweaker** | Performance, privacy and UI tweaks with live status, plus Restore Defaults. | Moderate |
| **WinOma Services (PC)** | PowerShell script that disables unneeded Windows services and background components. | Moderate |
| **WinOma Bloatware Remover** | Menu-driven removal of preinstalled Windows apps (Copilot, Teams, Clipchamp, Feedback Hub and more). | Moderate |
| **WinOma USB Power Tweak** | USB device and root hub power-management tuning. | Advanced |

---

## Disclaimer

Some tweaks reduce background services, convenience features or security protections. Ultimate-profile tweaks can lower security and increase power use and heat, so don't use them on work PCs or laptops running on battery. Results vary by hardware.

---

## Frequently Asked Questions (FAQ)

<details>
<summary><b>Does WinOma work on laptops without draining the battery?</b></summary>
    
Yes. WinOma features automatic chassis and power-source detection. On laptops, battery-draining tweaks are automatically bypassed, and EcoQoS policies are applied to keep background apps on E-Cores.

</details>

<details>
<summary><b>Will this trigger Anti-Cheat software (VALORANT Vanguard, Easy Anti-Cheat)?</b></summary>

No. WinOma uses native Windows APIs, official group policies, and registry keys. It does not patch system kernels or inject code into games.

</details>

<details>
<summary><b>How is WinOma different from free tweak scripts?</b></summary>
Most free tools apply generic, untested registry files. WinOma is benchmark-driven, uses automated A/B measurements, supports full multi-step rollback, and detects hybrid CPU architectures.
</details>

---

## Work with us

Send me a message with your PC or laptop model, what is going wrong (FPS drops, stutters, latency, noise or heat) and your goals.

Whether you need custom software built from scratch, deep code optimization or system-wide latency reduction, feel free to get in touch.

---

<div align="center">

**WinOma: PC Performance Experts**

</div>
