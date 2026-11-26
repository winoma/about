<#
.SYNOPSIS
    WinOma Scan - read-only PC health and latency audit.
.DESCRIPTION
    Measures power, gaming, background load and hardware settings and gives a
    0-100 score. It never changes the system and sends nothing anywhere.

    Customer mode (default): a score per area, the number of optimization
    opportunities, the estimated score after a tune-up and a scan code.
    The scan code carries the full result, so a technician can read it with
    -Decode without connecting to the PC.

    Technician mode (-Technician): every check, its value and its fix.
.PARAMETER Technician
    Show every check, its value and the recommended fixes.
.PARAMETER Decode
    Read a customer's scan code (for example WS-ABCD-EFGH-JKMN-P) and show the full result.
.PARAMETER Json
    Save a JSON report to C:\ProgramData\WinOma\Logs (technician mode only).
.PARAMETER NoPause
    Exit without waiting for a key press.
.NOTES
    WinOma Optimization Service - https://winoma.app
    This file is plain ASCII, so it works however it is saved.
    For the copy you give to customers, set $AllowTechnician to $false.
#>
[CmdletBinding()]
param(
    [switch]$Technician,
    [string]$Decode = '',
    [switch]$Json,
    [switch]$NoPause
)

$ErrorActionPreference = 'SilentlyContinue'
$Version         = '1.2.0-beta'
$AllowTechnician = $true
$CodeFormat      = 1
$Contact         = 't.me/omarizzww'
$Website         = 'winoma.app'
$B32             = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
$Full            = [string][char]0x2588
$Empty           = [string][char]0x2591
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
try { $Host.UI.RawUI.WindowTitle = "WinOma Scan $Version" } catch {}
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

if (-not $AllowTechnician) { $Technician = $false; $Decode = ''; $Json = $false }

$Areas = [ordered]@{
    Power      = 'Power and boot'
    Gaming     = 'Gaming and display'
    Background = 'Background load'
    Hardware   = 'Hardware and drivers'
}

# ================= Check catalog =================
# The order of this list is part of the scan code. Never reorder or remove
# entries; only add new ones at the end. Raise $CodeFormat if the meaning of
# an existing entry changes. Fixable = can be solved in a remote tune-up.
$Catalog = @(
    @{ Id = 'PowerPlan';      Area = 'Power';      Name = 'Power plan';            Weight = 10; Evidence = 'proven';      Fixable = $true;  Fix = 'Switch to a tuned power plan.' }
    @{ Id = 'PowerThrottle';  Area = 'Power';      Name = 'Power Throttling';      Weight = 4;  Evidence = 'situational'; Fixable = $true;  Fix = 'Turn off Power Throttling (Safe Performance Tweaks).' }
    @{ Id = 'UsbSuspend';     Area = 'Power';      Name = 'USB selective suspend'; Weight = 3;  Evidence = 'situational'; Fixable = $true;  Fix = 'Disable USB selective suspend on AC (USB Power Tweak).' }
    @{ Id = 'FastStartup';    Area = 'Power';      Name = 'Fast Startup';          Weight = 3;  Evidence = 'situational'; Fixable = $true;  Fix = 'Disable Fast Startup so every boot starts clean.' }
    @{ Id = 'GameMode';       Area = 'Gaming';     Name = 'Game Mode';             Weight = 6;  Evidence = 'situational'; Fixable = $true;  Fix = 'Turn Game Mode on.' }
    @{ Id = 'GameDvr';        Area = 'Gaming';     Name = 'Background recording';  Weight = 10; Evidence = 'proven';      Fixable = $true;  Fix = 'Turn off Game Bar background recording and captures.' }
    @{ Id = 'Hags';           Area = 'Gaming';     Name = 'GPU scheduling (HAGS)'; Weight = 4;  Evidence = 'situational'; Fixable = $true;  Fix = 'Test HAGS on and keep it if frametimes improve.' }
    @{ Id = 'RefreshRate';    Area = 'Gaming';     Name = 'Refresh rate';          Weight = 8;  Evidence = 'proven';      Fixable = $true;  Fix = 'Set the monitor to its highest refresh rate.' }
    @{ Id = 'MouseAccel';     Area = 'Gaming';     Name = 'Mouse acceleration';    Weight = 4;  Evidence = 'situational'; Fixable = $true;  Fix = 'Turn off Enhance pointer precision.' }
    @{ Id = 'VisualFx';       Area = 'Gaming';     Name = 'Visual effects';        Weight = 3;  Evidence = 'situational'; Fixable = $true;  Fix = 'Trim animations and transparency (System Tweaker).' }
    @{ Id = 'Processes';      Area = 'Background'; Name = 'Running processes';     Weight = 8;  Evidence = 'situational'; Fixable = $true;  Fix = 'Cut background apps and services (Services pack).' }
    @{ Id = 'Startup';        Area = 'Background'; Name = 'Startup apps';          Weight = 8;  Evidence = 'situational'; Fixable = $true;  Fix = 'Disable unneeded startup apps.' }
    @{ Id = 'RamUse';         Area = 'Background'; Name = 'RAM in use';            Weight = 8;  Evidence = 'proven';      Fixable = $false; Fix = 'Close or remove memory-heavy background apps.' }
    @{ Id = 'Bloat';          Area = 'Background'; Name = 'Preinstalled apps';     Weight = 6;  Evidence = 'situational'; Fixable = $true;  Fix = 'Remove unused preinstalled apps (Bloatware Remover).' }
    @{ Id = 'BgApps';         Area = 'Background'; Name = 'Background apps';       Weight = 3;  Evidence = 'situational'; Fixable = $true;  Fix = 'Stop Store apps from running in the background.' }
    @{ Id = 'Telemetry';      Area = 'Background'; Name = 'Telemetry service';     Weight = 3;  Evidence = 'situational'; Fixable = $true;  Fix = 'Disable telemetry services (Services pack).' }
    @{ Id = 'Disk';           Area = 'Background'; Name = 'System drive space';    Weight = 6;  Evidence = 'proven';      Fixable = $false; Fix = 'Free space on the system drive (aim for 20%+).' }
    @{ Id = 'RamChannels';    Area = 'Hardware';   Name = 'Memory channels';       Weight = 6;  Evidence = 'proven';      Fixable = $false; Fix = 'Use two matched sticks for dual-channel memory.' }
    @{ Id = 'RamSpeed';       Area = 'Hardware';   Name = 'Memory speed';          Weight = 6;  Evidence = 'situational'; Fixable = $false; Fix = 'Enable XMP/EXPO in BIOS if the kit supports it.' }
    @{ Id = 'GpuDriver';      Area = 'Hardware';   Name = 'GPU driver age';        Weight = 8;  Evidence = 'proven';      Fixable = $true;  Fix = 'Clean-install the latest GPU driver.' }
    @{ Id = 'GpuMsi';         Area = 'Hardware';   Name = 'GPU MSI mode';          Weight = 3;  Evidence = 'situational'; Fixable = $true;  Fix = 'Enable MSI mode for the GPU (Hardware pack).' }
    @{ Id = 'Uptime';         Area = 'Hardware';   Name = 'Uptime';                Weight = 4;  Evidence = 'situational'; Fixable = $true;  Fix = 'Restart regularly (Restart, not Shut down).' }
    @{ Id = 'PendingRestart'; Area = 'Hardware';   Name = 'Pending restart';       Weight = 3;  Evidence = 'proven';      Fixable = $true;  Fix = 'Restart to finish pending Windows updates.' }
    @{ Id = 'Timer';          Area = 'Hardware';   Name = 'Timer (HPET)';          Weight = 6;  Evidence = 'situational'; Fixable = $true;  Fix = 'Remove forced HPET unless benchmarks prove it helps.' }
)

$State = @{}
$Info  = New-Object System.Collections.Generic.List[object]

# ================= Banner (stored as Base64 so the file stays ASCII) =================
$BannerB64 = @'
4paI4paI4pWXICAgIOKWiOKWiOKVl+KWiOKWiOKVl+KWiOKWiOKWiOKVlyAgIOKWiOKWiOKVlyDi
lojilojilojilojilojilojilZcg4paI4paI4paI4pWXICAg4paI4paI4paI4pWXIOKWiOKWiOKW
iOKWiOKWiOKVlwrilojilojilZEgICAg4paI4paI4pWR4paI4paI4pWR4paI4paI4paI4paI4pWX
ICDilojilojilZHilojilojilZTilZDilZDilZDilojilojilZfilojilojilojilojilZcg4paI
4paI4paI4paI4pWR4paI4paI4pWU4pWQ4pWQ4paI4paI4pWXCuKWiOKWiOKVkSDilojilZcg4paI
4paI4pWR4paI4paI4pWR4paI4paI4pWU4paI4paI4pWXIOKWiOKWiOKVkeKWiOKWiOKVkSAgIOKW
iOKWiOKVkeKWiOKWiOKVlOKWiOKWiOKWiOKWiOKVlOKWiOKWiOKVkeKWiOKWiOKWiOKWiOKWiOKW
iOKWiOKVkQrilojilojilZHilojilojilojilZfilojilojilZHilojilojilZHilojilojilZHi
lZrilojilojilZfilojilojilZHilojilojilZEgICDilojilojilZHilojilojilZHilZriloji
lojilZTilZ3ilojilojilZHilojilojilZTilZDilZDilojilojilZEK4pWa4paI4paI4paI4pWU
4paI4paI4paI4pWU4pWd4paI4paI4pWR4paI4paI4pWRIOKVmuKWiOKWiOKWiOKWiOKVkeKVmuKW
iOKWiOKWiOKWiOKWiOKWiOKVlOKVneKWiOKWiOKVkSDilZrilZDilZ0g4paI4paI4pWR4paI4paI
4pWRICDilojilojilZEKIOKVmuKVkOKVkOKVneKVmuKVkOKVkOKVnSDilZrilZDilZ3ilZrilZDi
lZ0gIOKVmuKVkOKVkOKVkOKVnSDilZrilZDilZDilZDilZDilZDilZ0g4pWa4pWQ4pWdICAgICDi
lZrilZDilZ3ilZrilZDilZ0gIOKVmuKVkOKVnQogICAgICAgICAg4paI4paI4paI4paI4paI4paI
4paI4pWXIOKWiOKWiOKWiOKWiOKWiOKWiOKVlyDilojilojilojilojilojilZcg4paI4paI4paI
4pWXICAg4paI4paI4pWXCiAgICAgICAgICDilojilojilZTilZDilZDilZDilZDilZ3ilojiloji
lZTilZDilZDilZDilZDilZ3ilojilojilZTilZDilZDilojilojilZfilojilojilojilojilZcg
IOKWiOKWiOKVkQogICAgICAgICAg4paI4paI4paI4paI4paI4paI4paI4pWX4paI4paI4pWRICAg
ICDilojilojilojilojilojilojilojilZHilojilojilZTilojilojilZcg4paI4paI4pWRCiAg
ICAgICAgICDilZrilZDilZDilZDilZDilojilojilZHilojilojilZEgICAgIOKWiOKWiOKVlOKV
kOKVkOKWiOKWiOKVkeKWiOKWiOKVkeKVmuKWiOKWiOKVl+KWiOKWiOKVkQogICAgICAgICAg4paI
4paI4paI4paI4paI4paI4paI4pWR4pWa4paI4paI4paI4paI4paI4paI4pWX4paI4paI4pWRICDi
lojilojilZHilojilojilZEg4pWa4paI4paI4paI4paI4pWRCiAgICAgICAgICDilZrilZDilZDi
lZDilZDilZDilZDilZ0g4pWa4pWQ4pWQ4pWQ4pWQ4pWQ4pWd4pWa4pWQ4pWdICDilZrilZDilZ3i
lZrilZDilZ0gIOKVmuKVkOKVkOKVkOKVnQ==
'@

# ================= Helpers =================
function Get-ConsoleWidth {
    $w = 0
    try { $w = $Host.UI.RawUI.WindowSize.Width } catch {}
    if (-not $w -or $w -lt 20) { $w = 100 }
    return $w
}

function Write-Prompt {
    param([string]$Text, [ConsoleColor]$Color = 'Gray')
    Write-Host '  winoma >> ' -ForegroundColor Magenta -NoNewline
    Write-Host $Text -ForegroundColor $Color
}

function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host ('  ' + $Title.ToUpper()) -ForegroundColor Magenta
    Write-Host ('  ' + ('-' * 66)) -ForegroundColor DarkMagenta
}

function Write-Bar {
    param([int]$Percent, [int]$Width, [ConsoleColor]$Color)
    $filled = [int][math]::Round($Percent / 100 * $Width)
    Write-Host ($Full * $filled) -ForegroundColor $Color -NoNewline
    Write-Host ($Empty * ($Width - $filled)) -ForegroundColor DarkGray -NoNewline
}

function Get-ScoreColor {
    param([int]$Percent)
    if ($Percent -ge 75) { 'Green' } elseif ($Percent -ge 50) { 'Yellow' } else { 'Red' }
}

function Get-Grade {
    param([int]$Score)
    if ($Score -ge 90) { 'Excellent' } elseif ($Score -ge 75) { 'Good' } elseif ($Score -ge 50) { 'Needs tuning' } else { 'Critical' }
}

function Write-CheckLine {
    param([string]$Status, [string]$Name, [string]$Detail)
    $color = switch ($Status) { 'OK' {'Green'} 'WARN' {'Yellow'} 'FAIL' {'Red'} 'INFO' {'Cyan'} default {'DarkGray'} }
    $label = if ($Status -eq 'SKIP') { '[N/A]' } else { '[' + $Status + ']' }
    $room  = (Get-ConsoleWidth) - 40
    if ($room -gt 10 -and $Detail.Length -gt $room) { $Detail = $Detail.Substring(0, $room - 3) + '...' }
    Write-Host '  ' -NoNewline
    Write-Host ($label.PadRight(8)) -ForegroundColor $color -NoNewline
    Write-Host ($Name.PadRight(26)) -ForegroundColor White -NoNewline
    Write-Host $Detail -ForegroundColor DarkGray
}

function Show-Banner {
    param([string]$Subtitle)
    Clear-Host
    $width = Get-ConsoleWidth
    $text  = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($BannerB64 -replace '\s', '')))
    $lines = $text -split "`n"
    $maxLen = ($lines | Measure-Object -Property Length -Maximum).Maximum
    Write-Host ''
    if ($width -ge $maxLen + 4) {
        foreach ($l in $lines) { Write-Host ('  ' + $l) -ForegroundColor Magenta }
    } else {
        Write-Host '  W I N O M A   S C A N' -ForegroundColor Magenta
    }
    Write-Host ''
    Write-Host ("  v$Version  -  $Subtitle") -ForegroundColor DarkMagenta
    Write-Host ''
}

function Get-Reg {
    param([string]$Path, [string]$Name)
    try { (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name } catch { $null }
}

function Set-Result {
    param([string]$Id, [ValidateSet('OK','WARN','FAIL','SKIP')][string]$Status, [string]$Detail = '')
    $script:State[$Id] = [pscustomobject]@{ Status = $Status; Detail = $Detail }
}

function Add-Info {
    param([string]$Name, [string]$Detail)
    $script:Info.Add([pscustomobject]@{ Name = $Name; Detail = $Detail })
}

function Start-Area {
    param([string]$Label)
    if (-not $Technician) { Write-Prompt ('Analyzing ' + $Label.ToLower() + '...') 'DarkGray' }
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
                    if ($prop.Value[0] -notin @(2, 6)) { [void]$disabledNames.Add($prop.Name) }
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

# ================= Scoring =================
function Get-Score {
    param($StateMap, [string]$Area = '', [switch]$AfterTuneUp)
    $max = 0
    $earned = 0
    foreach ($c in $Catalog) {
        if ($Area -and $c.Area -ne $Area) { continue }
        $s = $StateMap[$c.Id]
        if (-not $s -or $s.Status -eq 'SKIP') { continue }
        $status = $s.Status
        if ($AfterTuneUp -and $c.Fixable) { $status = 'OK' }
        $max += $c.Weight
        $earned += switch ($status) { 'OK' { $c.Weight } 'WARN' { [math]::Floor($c.Weight / 2) } default { 0 } }
    }
    if ($max -eq 0) { return 100 }
    return [int][math]::Round($earned / $max * 100)
}

function Get-OpenChecks {
    param($StateMap)
    @($Catalog | Where-Object { $s = $StateMap[$_.Id]; $s -and ($s.Status -eq 'WARN' -or $s.Status -eq 'FAIL') })
}

# ================= Scan code =================
function ConvertTo-ScanCode {
    param($StateMap, [int]$Score, [bool]$Laptop, [bool]$Vm)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append([Convert]::ToString($CodeFormat, 2).PadLeft(3, '0'))
    [void]$sb.Append($(if ($Laptop) { '1' } else { '0' }))
    [void]$sb.Append($(if ($Vm) { '1' } else { '0' }))
    [void]$sb.Append([Convert]::ToString([math]::Min($Score, 127), 2).PadLeft(7, '0'))
    foreach ($c in $Catalog) {
        $s = $StateMap[$c.Id]
        $pair = '11'
        if ($s) { $pair = switch ($s.Status) { 'OK' { '00' } 'WARN' { '01' } 'FAIL' { '10' } default { '11' } } }
        [void]$sb.Append($pair)
    }
    $bits = $sb.ToString()
    while ($bits.Length % 5 -ne 0) { $bits += '0' }

    $chars = ''
    $sum = 0
    $idx = 0
    for ($i = 0; $i -lt $bits.Length; $i += 5) {
        $n = [Convert]::ToInt32($bits.Substring($i, 5), 2)
        $idx++
        $sum += $n * $idx
        $chars += $B32[$n]
    }
    $chars += $B32[$sum % 32]

    $groups = for ($i = 0; $i -lt $chars.Length; $i += 4) { $chars.Substring($i, [math]::Min(4, $chars.Length - $i)) }
    return 'WS-' + ($groups -join '-')
}

function ConvertFrom-ScanCode {
    param([string]$Code)
    $clean = $Code.ToUpper() -replace '^\s*WS', '' -replace '[^0-9A-Z]', ''
    $clean = $clean -replace 'O', '0' -replace '[IL]', '1'
    if ($clean.Length -lt 4) { return $null }

    $data  = $clean.Substring(0, $clean.Length - 1)
    $check = [string]$clean[$clean.Length - 1]
    $bits  = ''
    $sum   = 0
    $idx   = 0
    foreach ($ch in $data.ToCharArray()) {
        $n = $B32.IndexOf($ch)
        if ($n -lt 0) { return $null }
        $idx++
        $sum += $n * $idx
        $bits += [Convert]::ToString($n, 2).PadLeft(5, '0')
    }
    if ([string]$B32[$sum % 32] -ne $check) { return $null }
    if ($bits.Length -lt 12) { return $null }
    if ([Convert]::ToInt32($bits.Substring(0, 3), 2) -ne $CodeFormat) { return $null }

    $map = @{}
    $pos = 12
    foreach ($c in $Catalog) {
        if ($pos + 2 -gt $bits.Length) { break }
        $pair = $bits.Substring($pos, 2)
        $pos += 2
        $st = switch ($pair) { '00' { 'OK' } '01' { 'WARN' } '10' { 'FAIL' } default { 'SKIP' } }
        $map[$c.Id] = [pscustomobject]@{ Status = $st; Detail = '' }
    }
    return [pscustomobject]@{
        Laptop = ($bits.Substring(3, 1) -eq '1')
        Vm     = ($bits.Substring(4, 1) -eq '1')
        Score  = [Convert]::ToInt32($bits.Substring(5, 7), 2)
        State  = $map
    }
}

# ================= Report blocks =================
function Show-Details {
    param($StateMap, [switch]$ShowInfo)
    if ($ShowInfo -and $Info.Count -gt 0) {
        Write-Section 'System'
        foreach ($i in $Info) { Write-CheckLine 'INFO' $i.Name $i.Detail }
    }
    foreach ($key in $Areas.Keys) {
        Write-Section $Areas[$key]
        foreach ($c in ($Catalog | Where-Object { $_.Area -eq $key })) {
            $s = $StateMap[$c.Id]
            if (-not $s) { Write-CheckLine 'SKIP' $c.Name 'Not checked'; continue }
            $detail = if ($s.Detail) { $s.Detail } else { '(' + $c.Evidence + ')' }
            Write-CheckLine $s.Status $c.Name $detail
        }
    }
}

function Show-Areas {
    param($StateMap)
    Write-Section 'Results by area'
    foreach ($key in $Areas.Keys) {
        $items = @($Catalog | Where-Object { $s = $StateMap[$_.Id]; $_.Area -eq $key -and $s -and $s.Status -ne 'SKIP' })
        if ($items.Count -eq 0) { continue }
        $pct  = Get-Score $StateMap -Area $key
        $open = @($items | Where-Object { $StateMap[$_.Id].Status -ne 'OK' }).Count
        $col  = Get-ScoreColor $pct
        $txt  = if ($open -eq 0) { 'optimized' } elseif ($open -eq 1) { '1 opportunity' } else { "$open opportunities" }
        Write-Host ('  ' + $Areas[$key].PadRight(22)) -ForegroundColor White -NoNewline
        Write-Bar $pct 20 $col
        Write-Host ('  ' + ("$pct%").PadLeft(4)) -ForegroundColor $col -NoNewline
        Write-Host ('   ' + $txt) -ForegroundColor DarkGray
    }
}

function Show-ScoreBlock {
    param([int]$Score, [int]$After)
    $col = Get-ScoreColor $Score
    Write-Host ''
    Write-Host '  SCORE          ' -ForegroundColor Magenta -NoNewline
    Write-Bar $Score 30 $col
    Write-Host ("  $Score/100  ") -ForegroundColor $col -NoNewline
    Write-Host (Get-Grade $Score) -ForegroundColor White
    if ($After -gt $Score) {
        Write-Host '  AFTER TUNE-UP  ' -ForegroundColor Magenta -NoNewline
        Write-Bar $After 30 'Green'
        Write-Host ("  $After/100  ") -ForegroundColor Green -NoNewline
        Write-Host 'estimated' -ForegroundColor DarkGray
    }
    Write-Host ''
}

function Show-Fixes {
    param($StateMap)
    $list = Get-OpenChecks $StateMap | Sort-Object -Property @{
        Expression = { if ($StateMap[$_.Id].Status -eq 'FAIL') { $_.Weight } else { $_.Weight / 2 } }
        Descending = $true
    }
    if (-not $list) { Write-Prompt 'No fixes needed. This PC is in great shape.' 'Green'; return }
    Write-Prompt 'Fixes, most important first:' 'White'
    $i = 1
    foreach ($c in $list) {
        $st  = $StateMap[$c.Id].Status
        $col = if ($st -eq 'FAIL') { 'Red' } else { 'Yellow' }
        $tag = if ($c.Fixable) { '' } else { '  [hardware/BIOS]' }
        Write-Host ('    ' + "$i.".PadRight(4)) -ForegroundColor Magenta -NoNewline
        Write-Host ($st.PadRight(5)) -ForegroundColor $col -NoNewline
        Write-Host $c.Fix -ForegroundColor Gray -NoNewline
        Write-Host $tag -ForegroundColor DarkGray
        $i++
    }
}

function Exit-Scan {
    if (-not $NoPause) {
        Write-Host ''
        Write-Host '  Press any key to exit...' -ForegroundColor DarkGray
        try { $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } catch {}
    }
}

# ================= Decode mode =================
if ($Decode) {
    Show-Banner 'decode'
    $r = ConvertFrom-ScanCode $Decode
    if (-not $r) {
        Write-Prompt 'Invalid or mistyped scan code. Ask the customer to copy it again.' 'Red'
        Exit-Scan
        return
    }
    $form = if ($r.Laptop) { 'Laptop' } else { 'Desktop' }
    if ($r.Vm) { $form += ' (virtual machine)' }
    Write-Prompt ("Scan code " + $Decode.ToUpper() + "  -  " + $form) 'White'
    Show-Details $r.State
    Show-Areas $r.State
    Show-ScoreBlock $r.Score (Get-Score $r.State -AfterTuneUp)
    Show-Fixes $r.State
    Exit-Scan
    return
}

# ================= Scan =================
Show-Banner $(if ($Technician) { 'technician mode' } else { 'free PC performance check' })
Write-Prompt 'Read-only scan. Nothing on this PC is changed or sent anywhere.' 'White'
if ($Technician -and -not $IsAdmin) { Write-Prompt 'Not running as administrator: the timer check is skipped.' 'Yellow' }
Write-Host ''

$os  = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$cs  = Get-CimInstance Win32_ComputerSystem
$gpu = Get-CimInstance Win32_VideoController |
       Where-Object { $_.Name -notmatch 'Microsoft|Basic Display|Remote|Virtual|Parsec|Meta|Citrix|VMware|VirtualBox|Hyper-V' } |
       Select-Object -First 1
$laptopTypes = 8,9,10,11,12,14,18,21,30,31,32
$IsLaptop = [bool]((Get-CimInstance Win32_SystemEnclosure).ChassisTypes | Where-Object { $laptopTypes -contains $_ })
$IsVM = [bool](($cs.Model -match 'Virtual|VMware|VirtualBox|KVM|QEMU|HVM|Parallels') -or
               ($cs.Manufacturer -match 'VMware|QEMU|Xen|innotek|Parallels'))

# ---------- System (info only) ----------
Start-Area 'system'
Add-Info 'Windows'     ("{0} (build {1})" -f ($os.Caption -replace 'Microsoft ', ''), $os.BuildNumber)
Add-Info 'CPU'         ($cpu.Name.Trim())
Add-Info 'Memory'      ("{0} GB" -f [math]::Round($cs.TotalPhysicalMemory / 1GB))
Add-Info 'GPU'         ($(if ($gpu) { $gpu.Name } else { 'Not detected' }))
Add-Info 'Form factor' ($(if ($IsLaptop) { 'Laptop' } else { 'Desktop' }))
if ($IsVM) { Add-Info 'Environment' 'Virtual machine - GPU, display and memory checks skipped' }
$hvci = Get-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled'
Add-Info 'Memory Integrity' ($(if ($hvci -eq 1) { 'On (security, never scored)' } else { 'Off' }))

# ---------- Power and boot ----------
Start-Area $Areas['Power']
$scheme   = (powercfg /getactivescheme) -join ' '
$planGuid = if ($scheme -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') { $Matches[1].ToLower() } else { '' }
$planName = if ($scheme -match '\(([^)]+)\)') { $Matches[1] } else { 'Unknown' }
$saver    = 'a1841308-3541-4fab-bc81-f71556f20b4a'
$balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'
if     ($planGuid -eq $saver -and -not $IsLaptop)    { Set-Result 'PowerPlan' 'FAIL' $planName }
elseif ($planGuid -eq $saver)                        { Set-Result 'PowerPlan' 'WARN' $planName }
elseif ($planGuid -eq $balanced -and -not $IsLaptop) { Set-Result 'PowerPlan' 'WARN' $planName }
else                                                 { Set-Result 'PowerPlan' 'OK'   $planName }

if ($IsLaptop) {
    Set-Result 'PowerThrottle' 'SKIP' 'Laptop - kept on for battery life'
    $bat = Get-CimInstance Win32_Battery | Select-Object -First 1
    if ($bat) {
        $src = if ($bat.BatteryStatus -eq 1) { 'On battery' } else { 'Plugged in' }
        Add-Info 'Power source' ("$src, $($bat.EstimatedChargeRemaining)% charge")
    }
} else {
    $pt = Get-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff'
    if ($pt -eq 1) { Set-Result 'PowerThrottle' 'OK' 'Off' } else { Set-Result 'PowerThrottle' 'WARN' 'On (Windows default)' }
}

if ($planGuid) {
    $usbSub  = '2a737441-1930-4402-8d77-b2bebba308a3'
    $usbSet  = '48e6b7a6-50f5-4782-a5d4-53bb8f07e226'
    $usb = Get-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$planGuid\$usbSub\$usbSet" 'ACSettingIndex'
    if ($null -eq $usb) { $usb = Get-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\$usbSub\$usbSet\DefaultPowerSchemeValues\$planGuid" 'ACSettingIndex' }
    if ($usb -eq 0) { Set-Result 'UsbSuspend' 'OK' 'Off while plugged in' } else { Set-Result 'UsbSuspend' 'WARN' 'On while plugged in' }
}

$hiber = Get-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled'
if ($hiber -eq 1) { Set-Result 'FastStartup' 'WARN' 'On - shutdown does not fully reset Windows' } else { Set-Result 'FastStartup' 'OK' 'Off' }

# ---------- Gaming and display ----------
Start-Area $Areas['Gaming']
$gameMode = Get-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled'
if ($gameMode -eq 0) { Set-Result 'GameMode' 'WARN' 'Off' } else { Set-Result 'GameMode' 'OK' 'On' }

$histCap = Get-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'HistoricalCaptureEnabled'
$dvr     = Get-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled'
if     ($histCap -eq 1) { Set-Result 'GameDvr' 'FAIL' 'Always recording in the background' }
elseif ($dvr -eq 1)     { Set-Result 'GameDvr' 'WARN' 'Game Bar capture is on' }
else                    { Set-Result 'GameDvr' 'OK'   'Off' }

if ($IsVM) {
    Set-Result 'Hags' 'SKIP' 'Virtual machine'
    Set-Result 'RefreshRate' 'SKIP' 'Virtual machine'
} else {
    $hags = Get-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode'
    if     ($hags -eq 2) { Set-Result 'Hags' 'OK'   'On' }
    elseif ($hags -eq 1) { Set-Result 'Hags' 'WARN' 'Off' }
    else                 { Set-Result 'Hags' 'SKIP' 'Default or not supported' }

    if ($gpu -and $gpu.CurrentRefreshRate) {
        $curHz = [int]$gpu.CurrentRefreshRate
        $maxHz = [int]$gpu.MaxRefreshRate
        $hzTxt = "$curHz Hz (display reports up to $maxHz Hz)"
        if     ($maxHz -ge 100 -and $curHz -le 60)            { Set-Result 'RefreshRate' 'FAIL' $hzTxt }
        elseif ($maxHz -ge 100 -and $curHz -lt ($maxHz - 5)) { Set-Result 'RefreshRate' 'WARN' $hzTxt }
        else                                                  { Set-Result 'RefreshRate' 'OK'   "$curHz Hz" }
    }
}

$mouseSpeed = Get-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed'
if ($mouseSpeed -eq '1') { Set-Result 'MouseAccel' 'WARN' 'Enhance pointer precision is on' } else { Set-Result 'MouseAccel' 'OK' 'Off' }

$vfx    = Get-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting'
$transp = Get-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency'
if ($vfx -eq 2 -or ($vfx -eq 3 -and $transp -eq 0)) { Set-Result 'VisualFx' 'OK' 'Tuned' }
else { Set-Result 'VisualFx' 'WARN' 'Windows default animations and transparency' }

# ---------- Background load ----------
Start-Area $Areas['Background']
$procCount = @(Get-Process).Count
$procTxt   = "$procCount (tuned PCs: 80-120)"
if     ($procCount -le 120) { Set-Result 'Processes' 'OK'   $procTxt }
elseif ($procCount -le 180) { Set-Result 'Processes' 'WARN' $procTxt }
else                        { Set-Result 'Processes' 'FAIL' $procTxt }

$startup = Get-ActiveStartupCount
if     ($startup -le 3) { Set-Result 'Startup' 'OK'   "$startup active at boot" }
elseif ($startup -le 8) { Set-Result 'Startup' 'WARN' "$startup active at boot" }
else                    { Set-Result 'Startup' 'FAIL' "$startup active at boot" }

$usedPct = [math]::Round((1 - $os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100)
if     ($usedPct -le 50) { Set-Result 'RamUse' 'OK'   "$usedPct% right now" }
elseif ($usedPct -le 75) { Set-Result 'RamUse' 'WARN' "$usedPct% right now" }
else                     { Set-Result 'RamUse' 'FAIL' "$usedPct% right now" }

$bloatList = @(
    'Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.BingSearch', 'Clipchamp.Clipchamp',
    'MicrosoftTeams', 'MSTeams', 'Microsoft.GetHelp', 'Microsoft.Getstarted',
    'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.People', 'Microsoft.WindowsFeedbackHub',
    'Microsoft.ZuneMusic', 'Microsoft.ZuneVideo', 'Microsoft.YourPhone', 'Microsoft.Copilot',
    'Microsoft.MicrosoftOfficeHub', 'Microsoft.549981C3F5F10', 'Microsoft.Todos',
    'Microsoft.PowerAutomateDesktop', 'Microsoft.WindowsMaps', 'Microsoft.MixedReality.Portal',
    'Microsoft.SkypeApp', 'Microsoft.OutlookForWindows', 'Microsoft.Windows.DevHome'
)
$bloat = @(Get-AppxPackage | Where-Object { $bloatList -contains $_.Name }).Count
if     ($bloat -le 2) { Set-Result 'Bloat' 'OK'   "$bloat found" }
elseif ($bloat -le 6) { Set-Result 'Bloat' 'WARN' "$bloat found" }
else                  { Set-Result 'Bloat' 'FAIL' "$bloat found" }

$bgApps = Get-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled'
if ($bgApps -eq 1) { Set-Result 'BgApps' 'OK' 'Blocked' } else { Set-Result 'BgApps' 'WARN' 'Allowed for all apps' }

$diag = Get-Service -Name DiagTrack
if ($diag -and $diag.Status -eq 'Running') { Set-Result 'Telemetry' 'WARN' 'DiagTrack is running' } else { Set-Result 'Telemetry' 'OK' 'Not running' }

$sysDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'"
if ($sysDisk -and $sysDisk.Size) {
    $freePct = [math]::Round($sysDisk.FreeSpace / $sysDisk.Size * 100)
    $diskTxt = "$freePct% free ({0} GB)" -f [math]::Round($sysDisk.FreeSpace / 1GB)
    if     ($freePct -ge 20) { Set-Result 'Disk' 'OK'   $diskTxt }
    elseif ($freePct -ge 10) { Set-Result 'Disk' 'WARN' $diskTxt }
    else                     { Set-Result 'Disk' 'FAIL' $diskTxt }
}

# ---------- Hardware and drivers ----------
Start-Area $Areas['Hardware']
if ($IsVM) {
    foreach ($id in 'RamChannels', 'RamSpeed', 'GpuDriver', 'GpuMsi') { Set-Result $id 'SKIP' 'Virtual machine' }
} else {
    $dimms = @(Get-CimInstance Win32_PhysicalMemory)
    if ($dimms.Count -gt 0) {
        $ramSpeed = [int]$dimms[0].ConfiguredClockSpeed
        $ramType  = [int]$dimms[0].SMBIOSMemoryType
        if ($IsLaptop) {
            Add-Info 'Memory setup' ("$($dimms.Count) module(s), $ramSpeed MT/s")
            Set-Result 'RamChannels' 'SKIP' 'Laptop'
            Set-Result 'RamSpeed'    'SKIP' 'Laptop'
        } else {
            if ($dimms.Count -eq 1) { Set-Result 'RamChannels' 'FAIL' 'Single stick - single-channel memory' }
            else                    { Set-Result 'RamChannels' 'OK'   "$($dimms.Count) sticks" }
            $baseSpeed = if ($ramType -eq 34) { 4800 } elseif ($ramType -eq 26) { 2400 } else { 0 }
            if ($baseSpeed -gt 0 -and $ramSpeed -gt 0) {
                if ($ramSpeed -le $baseSpeed) { Set-Result 'RamSpeed' 'WARN' "$ramSpeed MT/s - likely base speed (XMP/EXPO off?)" }
                else                          { Set-Result 'RamSpeed' 'OK'   "$ramSpeed MT/s" }
            }
        }
    }

    if ($gpu -and $gpu.DriverDate) {
        $age    = [int]((Get-Date) - $gpu.DriverDate).TotalDays
        $drvTxt = "$age days old (v$($gpu.DriverVersion))"
        if     ($age -le 180) { Set-Result 'GpuDriver' 'OK'   $drvTxt }
        elseif ($age -le 365) { Set-Result 'GpuDriver' 'WARN' $drvTxt }
        else                  { Set-Result 'GpuDriver' 'FAIL' $drvTxt }
    }

    $msiStatus = $null
    $msiDetail = ''
    $displays = Get-PnpDevice -Class Display -PresentOnly | Where-Object {
        $_.InstanceId -like 'PCI\*' -and $_.FriendlyName -notmatch 'Basic Display|Hyper-V|VMware|VirtualBox'
    }
    foreach ($dev in $displays) {
        $msiPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        $gpuName = ($dev.FriendlyName -replace '\(R\)|\(TM\)', '').Trim()
        if ((Get-Reg $msiPath 'MSISupported') -ne 1) {
            $msiStatus = 'WARN'
            $msiDetail = "Off - $gpuName"
        } elseif (-not $msiStatus) {
            $msiStatus = 'OK'
            $msiDetail = "On - $gpuName"
        }
    }
    if ($msiStatus) { Set-Result 'GpuMsi' $msiStatus $msiDetail }
}

$uptimeDays = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
if     ($uptimeDays -le 3) { Set-Result 'Uptime' 'OK'   "$uptimeDays days" }
elseif ($uptimeDays -le 7) { Set-Result 'Uptime' 'WARN' "$uptimeDays days" }
else                       { Set-Result 'Uptime' 'FAIL' "$uptimeDays days" }

$pending = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or
           (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
if ($pending) { Set-Result 'PendingRestart' 'WARN' 'Restart needed to finish updates' } else { Set-Result 'PendingRestart' 'OK' 'None' }

if ($IsAdmin) {
    $bcd = (bcdedit /enum '{current}') -join "`n"
    if ($bcd -match 'useplatformclock\s+Yes') { Set-Result 'Timer' 'WARN' 'HPET forced on (useplatformclock)' }
    else                                       { Set-Result 'Timer' 'OK'   'Windows default' }
} else {
    Set-Result 'Timer' 'SKIP' 'Needs administrator'
}

# ================= Results =================
$score     = Get-Score $State
$after     = Get-Score $State -AfterTuneUp
$open      = Get-OpenChecks $State
$fixable   = @($open | Where-Object { $_.Fixable }).Count
$scanCode  = ConvertTo-ScanCode $State $score $IsLaptop $IsVM

if ($Technician) {
    Show-Details $State -ShowInfo
}
Show-Areas $State
Show-ScoreBlock $score $after

if ($Technician) {
    Show-Fixes $State
    Write-Host ''
    Write-Prompt ("Scan code: $scanCode") 'Cyan'
} else {
    if ($open.Count -gt 0) {
        $word = if ($open.Count -eq 1) { 'opportunity' } else { 'opportunities' }
        Write-Prompt ("$($open.Count) optimization $word found ($fixable fixable remotely).") 'White'
    } else {
        Write-Prompt 'No optimization opportunities found. This PC is well tuned.' 'Green'
    }
    Write-Host ''
    Write-Host '  YOUR SCAN CODE   ' -ForegroundColor Magenta -NoNewline
    Write-Host $scanCode -ForegroundColor White -NoNewline
    $copied = $false
    try { Set-Clipboard -Value $scanCode; $copied = $true } catch {}
    if ($copied) { Write-Host '   (copied)' -ForegroundColor DarkGray } else { Write-Host '' }
    Write-Host ''
    Write-Prompt ("Send this code to $Contact for your full report.") 'Cyan'
    Write-Prompt ("Remote tune-ups: $Website") 'Cyan'
}

# ================= JSON report (technician only) =================
if ($Json -and $Technician) {
    $logDir = Join-Path $env:ProgramData 'WinOma\Logs'
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    $file = Join-Path $logDir ("scan-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $checks = foreach ($c in $Catalog) {
        $s = $State[$c.Id]
        [ordered]@{
            id       = $c.Id
            area     = $c.Area
            name     = $c.Name
            status   = $(if ($s) { $s.Status } else { 'SKIP' })
            detail   = $(if ($s) { $s.Detail } else { '' })
            evidence = $c.Evidence
            fixable  = $c.Fixable
            fix      = $c.Fix
        }
    }
    $report = [ordered]@{
        tool        = 'WinOma Scan'
        version     = $Version
        date        = (Get-Date).ToString('s')
        scanCode    = $scanCode
        score       = $score
        afterTuneUp = $after
        formFactor  = $(if ($IsLaptop) { 'Laptop' } else { 'Desktop' })
        virtual     = $IsVM
        system      = $Info
        checks      = $checks
    }
    $report | ConvertTo-Json -Depth 5 | Set-Content -Path $file -Encoding UTF8
    Write-Host ''
    if (Test-Path $file) { Write-Prompt 'Report saved to ProgramData\WinOma\Logs' 'Green' }
    else                 { Write-Prompt 'Could not save the report. Try running as administrator.' 'Yellow' }
}

Exit-Scan
