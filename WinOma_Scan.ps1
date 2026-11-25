<#
.SYNOPSIS
    WinOma Scan - read-only PC health and latency audit.
.DESCRIPTION
    Checks power, gaming, background load, drivers and interrupt settings,
    then prints a 0-100 score with the top fixes. It never changes the system.
    Run as administrator for the full set of checks (the timer check needs it).
.PARAMETER Json
    Also save a JSON report to C:\ProgramData\WinOma\Logs.
.PARAMETER NoPause
    Exit without waiting for a key press.
.NOTES
    WinOma Optimization Service - https://winoma.app
    Save this file as UTF-8 with BOM so the banner renders in Windows PowerShell 5.1.
#>
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$NoPause
)

$ErrorActionPreference = 'SilentlyContinue'
$Version = '1.0.1-beta'
$Results = New-Object System.Collections.Generic.List[object]
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
try { $Host.UI.RawUI.WindowTitle = "WinOma Scan - $Version" } catch {}
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ================= UI helpers =================
function Write-Prompt {
    param([string]$Text, [ConsoleColor]$Color = 'Gray')
    Write-Host 'winoma >> ' -ForegroundColor Magenta -NoNewline
    Write-Host $Text -ForegroundColor $Color
}

function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host ('  ' + $Title.ToUpper()) -ForegroundColor Magenta
    Write-Host ('  ' + ('-' * 66)) -ForegroundColor DarkMagenta
}

function Get-Reg {
    param([string]$Path, [string]$Name)
    try { (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name } catch { $null }
}

function Get-ActiveStartupCount {
    $disabledNames = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
    $approvedPaths = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder'
    )
    foreach ($p in $approvedPaths) {
        if (Test-Path $p) {
            $props = Get-ItemProperty -LiteralPath $p
            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Name -notmatch '^PS' -and $prop.Value -is [byte[]] -and $prop.Value.Length -gt 0) {
                    if ($prop.Value[0] -notin @(2, 6)) {
                        [void]$disabledNames.Add($prop.Name)
                    }
                }
            }
        }
    }

    $allStartup = @(Get-CimInstance Win32_StartupCommand)
    $active = $allStartup | Where-Object {
        -not $disabledNames.Contains($_.Name) -and
        -not $disabledNames.Contains([System.IO.Path]::GetFileName(($_.Command -replace '"', '')))
    }
    return @($active).Count
}

function Add-Check {
    param(
        [string]$Category,
        [string]$Name,
        [ValidateSet('OK','WARN','FAIL','INFO')][string]$Status,
        [string]$Detail,
        [int]$Weight = 0,
        [ValidateSet('proven','situational','info')][string]$Evidence = 'info',
        [string]$Fix = ''
    )
    $max    = if ($Status -eq 'INFO') { 0 } else { $Weight }
    $earned = switch ($Status) { 'OK' { $Weight } 'WARN' { [math]::Floor($Weight / 2) } default { 0 } }
    $Results.Add([pscustomobject]@{
        Category = $Category; Name = $Name; Status = $Status; Detail = $Detail
        Weight = $max; Earned = $earned; Evidence = $Evidence; Fix = $Fix
    })
    $color = switch ($Status) { 'OK' {'Green'} 'WARN' {'Yellow'} 'FAIL' {'Red'} default {'Cyan'} }
    Write-Host '  ' -NoNewline
    Write-Host (('[' + $Status + ']').PadRight(8)) -ForegroundColor $color -NoNewline
    Write-Host ($Name.PadRight(28)) -ForegroundColor White -NoNewline
    Write-Host $Detail -ForegroundColor DarkGray
}

# ================= Banner =================
Clear-Host
$banner = @'
          ██╗    ██╗██╗███╗   ██╗ ██████╗ ███╗   ███╗ █████╗ 
          ██║    ██║██║████╗  ██║██╔═══██╗████╗ ████║██╔══██╗
          ██║ █╗ ██║██║██╔██╗ ██║██║   ██║██╔████╔██║███████║
          ██║███╗██║██║██║╚██╗██║██║   ██║██║╚██╔╝██║██╔══██║
          ╚███╔███╔╝██║██║ ╚████║╚██████╔╝██║ ╚═╝ ██║██║  ██║
           ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝
                    ███████╗ ██████╗ █████╗ ███╗   ██╗
                    ██╔════╝██╔════╝██╔══██╗████╗  ██║
                    ███████╗██║     ███████║██╔██╗ ██║
                    ╚════██║██║     ██╔══██║██║╚██╗██║
                    ███████║╚██████╗██║  ██║██║ ╚████║
                    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝
'@
Write-Host $banner -ForegroundColor Magenta
Write-Host "                          v$Version" -ForegroundColor DarkMagenta
Write-Host ''
Write-Prompt 'Read-only scan. Nothing on this PC will be changed.' 'White'
if (-not $IsAdmin) { Write-Prompt 'Not running as administrator: the timer check will be skipped.' 'Yellow' }
Write-Prompt 'Scanning system...' 'Gray'

# ================= Collect =================
$os  = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$cs  = Get-CimInstance Win32_ComputerSystem
$gpu = Get-CimInstance Win32_VideoController |
       Where-Object { $_.Name -notmatch 'Microsoft|Remote|Virtual|Parsec|Meta|Citrix' } |
       Select-Object -First 1
$laptopTypes = 8,9,10,11,12,14,18,21,30,31,32
$IsLaptop = [bool]((Get-CimInstance Win32_SystemEnclosure).ChassisTypes | Where-Object { $laptopTypes -contains $_ })

# ================= System (info) =================
Write-Section 'System'
$ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB)
Add-Check 'System' 'Windows'     'INFO' ("{0} (build {1})" -f ($os.Caption -replace 'Microsoft ', ''), $os.BuildNumber)
Add-Check 'System' 'CPU'         'INFO' ($cpu.Name.Trim())
Add-Check 'System' 'Memory'      'INFO' ("$ramGB GB")
Add-Check 'System' 'GPU'         'INFO' ($(if ($gpu) { $gpu.Name } else { 'Not detected' }))
Add-Check 'System' 'Form factor' 'INFO' ($(if ($IsLaptop) { 'Laptop' } else { 'Desktop' }))

# ================= Power =================
Write-Section 'Power'
$scheme   = (powercfg /getactivescheme) -join ' '
$planGuid = if ($scheme -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') { $Matches[1].ToLower() } else { '' }
$planName = if ($scheme -match '\(([^)]+)\)') { $Matches[1] } else { 'Unknown' }
$saver    = 'a1841308-3541-4fab-bc81-f71556f20b4a'
$balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'

if ($planGuid -eq $saver -and -not $IsLaptop) {
    Add-Check 'Power' 'Power plan' 'FAIL' $planName 10 'proven' 'Leave Power saver: it caps CPU clocks.'
} elseif ($planGuid -eq $saver) {
    Add-Check 'Power' 'Power plan' 'WARN' $planName 10 'situational' 'Use Balanced or a tuned plan when gaming on a laptop.'
} elseif ($planGuid -eq $balanced -and -not $IsLaptop) {
    Add-Check 'Power' 'Power plan' 'WARN' $planName 10 'situational' 'Use High performance or a tuned plan on desktops.'
} else {
    Add-Check 'Power' 'Power plan' 'OK' $planName 10 'proven'
}

if ($IsLaptop) {
    $bat = Get-CimInstance Win32_Battery | Select-Object -First 1
    if ($bat) {
        $src = if ($bat.BatteryStatus -eq 1) { 'On battery' } else { 'Plugged in' }
        Add-Check 'Power' 'Power source' 'INFO' ("$src, $($bat.EstimatedChargeRemaining)% charge")
    }
}

# ================= Gaming =================
Write-Section 'Gaming'
$gameMode = Get-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled'
if ($gameMode -eq 0) {
    Add-Check 'Gaming' 'Game Mode' 'WARN' 'Off' 6 'situational' 'Turn Game Mode on in Settings > Gaming.'
} else {
    Add-Check 'Gaming' 'Game Mode' 'OK' 'On' 6 'situational'
}

$histCap = Get-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'HistoricalCaptureEnabled'
$dvr     = Get-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled'
if ($histCap -eq 1) {
    Add-Check 'Gaming' 'Background recording' 'FAIL' 'Always recording in the background' 10 'proven' 'Turn off "Record what happened" in Settings > Gaming > Captures.'
} elseif ($dvr -eq 1) {
    Add-Check 'Gaming' 'Background recording' 'WARN' 'Game Bar capture is on' 10 'situational' 'Disable Game Bar captures if you do not record clips.'
} else {
    Add-Check 'Gaming' 'Background recording' 'OK' 'Off' 10 'proven'
}

$hags = Get-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode'
switch ($hags) {
    2       { Add-Check 'Gaming' 'GPU scheduling (HAGS)' 'OK'   'On'  4 'situational' }
    1       { Add-Check 'Gaming' 'GPU scheduling (HAGS)' 'WARN' 'Off' 4 'situational' 'Test HAGS on: Settings > Display > Graphics.' }
    default { Add-Check 'Gaming' 'GPU scheduling (HAGS)' 'INFO' 'Default or not supported' }
}

$mouseSpeed = Get-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed'
if ($mouseSpeed -eq '1') {
    Add-Check 'Gaming' 'Mouse acceleration' 'WARN' 'Enhance pointer precision is on' 4 'situational' 'Turn off Enhance pointer precision for consistent aim.'
} else {
    Add-Check 'Gaming' 'Mouse acceleration' 'OK' 'Off' 4 'situational'
}

# ================= Background load =================
Write-Section 'Background load'
$procCount = @(Get-Process).Count
$procFix   = 'Remove or disable apps that run in the background.'
if     ($procCount -le 150) { Add-Check 'Background' 'Running processes' 'OK'   "$procCount (target under 150)" 8 'situational' }
elseif ($procCount -le 220) { Add-Check 'Background' 'Running processes' 'WARN' "$procCount (target under 150)" 8 'situational' $procFix }
else                        { Add-Check 'Background' 'Running processes' 'FAIL' "$procCount (target under 150)" 8 'situational' $procFix }

$startup    = Get-ActiveStartupCount
$startupFix = 'Disable unneeded apps in Task Manager > Startup apps.'
if     ($startup -le 5)  { Add-Check 'Background' 'Startup apps' 'OK'   "$startup active at boot" 8 'situational' }
elseif ($startup -le 10) { Add-Check 'Background' 'Startup apps' 'WARN' "$startup active at boot" 8 'situational' $startupFix }
else                     { Add-Check 'Background' 'Startup apps' 'FAIL' "$startup active at boot" 8 'situational' $startupFix }

$usedPct = [math]::Round((1 - $os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100)
$ramFix  = 'Close or remove memory-heavy background apps.'
if     ($usedPct -le 50) { Add-Check 'Background' 'RAM in use' 'OK'   "$usedPct% right now" 8 'proven' }
elseif ($usedPct -le 75) { Add-Check 'Background' 'RAM in use' 'WARN' "$usedPct% right now" 8 'proven' $ramFix }
else                     { Add-Check 'Background' 'RAM in use' 'FAIL' "$usedPct% right now" 8 'proven' $ramFix }

$diag = Get-Service -Name DiagTrack
if ($diag -and $diag.Status -eq 'Running') {
    Add-Check 'Background' 'Telemetry service' 'WARN' 'DiagTrack is running' 3 'situational' 'Covered by the WinOma Services pack.'
} else {
    Add-Check 'Background' 'Telemetry service' 'OK' 'Not running' 3 'situational'
}

$sysDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'"
if ($sysDisk -and $sysDisk.Size) {
    $freePct = [math]::Round($sysDisk.FreeSpace / $sysDisk.Size * 100)
    $freeGB  = [math]::Round($sysDisk.FreeSpace / 1GB)
    $diskFix = 'Free space on the system drive (aim for 20%+).'
    if     ($freePct -ge 20) { Add-Check 'Background' 'System drive space' 'OK'   "$freePct% free ($freeGB GB)" 6 'proven' }
    elseif ($freePct -ge 10) { Add-Check 'Background' 'System drive space' 'WARN' "$freePct% free ($freeGB GB)" 6 'proven' $diskFix }
    else                     { Add-Check 'Background' 'System drive space' 'FAIL' "$freePct% free ($freeGB GB)" 6 'proven' $diskFix }
}

# ================= Hardware and drivers =================
Write-Section 'Hardware and drivers'
if ($gpu -and $gpu.DriverDate) {
    $age    = [int]((Get-Date) - $gpu.DriverDate).TotalDays
    $detail = "$age days old (v$($gpu.DriverVersion))"
    $drvFix = 'Clean-install the latest GPU driver.'
    if     ($age -le 180) { Add-Check 'Hardware' 'GPU driver age' 'OK'   $detail 8 'proven' }
    elseif ($age -le 365) { Add-Check 'Hardware' 'GPU driver age' 'WARN' $detail 8 'proven' $drvFix }
    else                  { Add-Check 'Hardware' 'GPU driver age' 'FAIL' $detail 8 'proven' $drvFix }
} else {
    Add-Check 'Hardware' 'GPU driver age' 'INFO' 'Could not read driver date'
}

$displays = Get-PnpDevice -Class Display -PresentOnly | Where-Object { $_.InstanceId -like 'PCI\*' }
foreach ($dev in $displays) {
    $msiPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
    $msi     = Get-Reg $msiPath 'MSISupported'
    $gpuName = ($dev.FriendlyName -replace '\(R\)|\(TM\)', '').Trim()
    if ($msi -eq 1) {
        Add-Check 'Hardware' 'GPU MSI mode' 'OK' "On - $gpuName" 3 'situational'
    } else {
        Add-Check 'Hardware' 'GPU MSI mode' 'WARN' "Off - $gpuName" 3 'situational' 'Enable MSI mode for the GPU (WinOma Hardware pack).'
    }
}

$uptimeDays = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
$upFix      = 'Use Restart, not Shut down: Fast Startup keeps uptime running.'
if     ($uptimeDays -le 3) { Add-Check 'Hardware' 'Uptime' 'OK'   "$uptimeDays days" 4 'situational' }
elseif ($uptimeDays -le 7) { Add-Check 'Hardware' 'Uptime' 'WARN' "$uptimeDays days" 4 'situational' $upFix }
else                       { Add-Check 'Hardware' 'Uptime' 'FAIL' "$uptimeDays days" 4 'situational' $upFix }

$pending = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or
           (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
if ($pending) {
    Add-Check 'Hardware' 'Pending restart' 'WARN' 'Restart needed to finish updates' 3 'proven' 'Restart to finish pending Windows updates.'
} else {
    Add-Check 'Hardware' 'Pending restart' 'OK' 'None' 3 'proven'
}

if ($IsAdmin) {
    $bcd = (bcdedit /enum '{current}') -join "`n"
    if ($bcd -match 'useplatformclock\s+Yes') {
        Add-Check 'Hardware' 'Timer (HPET)' 'WARN' 'HPET forced on (useplatformclock)' 6 'situational' 'Remove useplatformclock unless benchmarks prove it helps.'
    } elseif ($bcd -match 'disabledynamictick\s+Yes') {
        Add-Check 'Hardware' 'Timer (HPET)' 'INFO' 'Dynamic tick disabled'
    } else {
        Add-Check 'Hardware' 'Timer (HPET)' 'OK' 'Windows default' 6 'situational'
    }
} else {
    Add-Check 'Hardware' 'Timer (HPET)' 'INFO' 'Skipped (needs administrator)'
}

# ================= Security (never scored) =================
Write-Section 'Security (info only, never scored)'
$hvci = Get-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled'
Add-Check 'Security' 'Memory Integrity' 'INFO' ($(if ($hvci -eq 1) { 'On - protects the kernel, costs a little performance' } else { 'Off' }))

# ================= Score =================
$max    = ($Results | Measure-Object -Property Weight -Sum).Sum
$earned = ($Results | Measure-Object -Property Earned -Sum).Sum
$score  = if ($max -gt 0) { [int][math]::Round($earned / $max * 100) } else { 0 }

if     ($score -ge 90) { $grade = 'Excellent';    $gColor = 'Green'  }
elseif ($score -ge 75) { $grade = 'Good';         $gColor = 'Green'  }
elseif ($score -ge 50) { $grade = 'Needs tuning'; $gColor = 'Yellow' }
else                   { $grade = 'Critical';     $gColor = 'Red'    }

$full   = [string][char]0x2588
$empty  = [string][char]0x2591
$filled = [int][math]::Round($score / 100 * 40)

Write-Host ''
Write-Host '  SCORE  ' -ForegroundColor Magenta -NoNewline
Write-Host ($full * $filled) -ForegroundColor $gColor -NoNewline
Write-Host ($empty * (40 - $filled)) -ForegroundColor DarkGray -NoNewline
Write-Host ("  $score/100  ") -ForegroundColor $gColor -NoNewline
Write-Host $grade -ForegroundColor White
Write-Host ''

$fixes = $Results |
    Where-Object { ($_.Status -eq 'FAIL' -or $_.Status -eq 'WARN') -and $_.Fix } |
    Sort-Object -Property @{ Expression = { $_.Weight - $_.Earned }; Descending = $true } |
    Select-Object -First 3

if ($fixes) {
    Write-Prompt 'Top fixes:' 'White'
    $i = 1
    foreach ($f in $fixes) {
        Write-Host "    $i. " -ForegroundColor Magenta -NoNewline
        Write-Host $f.Fix -ForegroundColor Gray
        $i++
    }
} else {
    Write-Prompt 'No fixes needed. This PC is in great shape.' 'Green'
}

# ================= JSON report =================
if ($Json) {
    $logDir = Join-Path $env:ProgramData 'WinOma\Logs'
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    $file = Join-Path $logDir ("scan-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $report = [ordered]@{
        tool       = 'WinOma Scan'
        version    = $Version
        date       = (Get-Date).ToString('s')
        score      = $score
        grade      = $grade
        formFactor = $(if ($IsLaptop) { 'Laptop' } else { 'Desktop' })
        checks     = $Results
    }
    $report | ConvertTo-Json -Depth 4 | Set-Content -Path $file -Encoding UTF8
    Write-Host ''
    if (Test-Path $file) { Write-Prompt 'Report saved to ProgramData\WinOma\Logs' 'Green' }
    else                 { Write-Prompt 'Could not save the report. Try running as administrator.' 'Yellow' }
}

# ================= Call to action =================
Write-Host ''
if ($score -lt 95) { Write-Prompt 'Want 95+? Book a tune-up: t.me/omarizzww | winoma.app' 'Cyan' }

if (-not $NoPause) {
    Write-Host ''
    Write-Host '  Press any key to exit...' -ForegroundColor DarkGray
    try { $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } catch {}
}