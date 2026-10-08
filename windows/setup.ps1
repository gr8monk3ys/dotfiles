<#
.SYNOPSIS
    Link the Omarchy-style Windows layer (GlazeWM + Zebar + Windows Terminal
    theme) to this dotfiles checkout.

.DESCRIPTION
    Windows has no make or stow, so this is the Windows counterpart of
    `make link`. Nothing is copied that could drift: GlazeWM is started with
    --config pointing into the checkout, and the Zebar widget pack is a
    directory junction into it. No admin rights needed (winget may ask for
    them on its own when an installer requires it).

    No switch (dry run): show what is installed and linked. Changes nothing.

    -Apply:
      1. winget-installs every id in install/wingetfile that is missing
         (read through bin/manifest with Git Bash, like every other consumer)
      2. HKCU Run value "GlazeWM": start GlazeWM at sign-in with
         --config <checkout>\windows\glazewm\config.yaml
      3. %USERPROFILE%\.glzr\zebar\danse -> junction to windows\zebar\danse;
         settings.json from windows\zebar (an existing one is kept as
         settings.json.bak-<date>)
      4. Windows Terminal fragment: windows\windows-terminal\danse.json.tpl,
         with the Arch profile's GUID read from settings.json, written to
         %LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\dotfiles\
      5. the look: taskbar auto-hide, dark mode, the palette's blue as
         accent colour, and the La Danse wallpaper built by bin/wallpaper
         (ImageMagick, at the screen's resolution). Each original value is
         saved once under HKCU\Software\dotfiles\windows-setup first.
      6. -Start also launches GlazeWM now (it re-tiles every open window)

    -Remove: undo 2-5 (the junction is unlinked, never recursed into; a
    backed-up settings.json is restored; taskbar, colours and wallpaper go
    back to the saved originals) and stop GlazeWM. Packages stay installed:
    `winget uninstall --id <id>` if wanted.

    Run it from the checkout that should stay: links point at this copy, and
    from a normal PowerShell: it refuses to change anything when started
    inside an MSIX app container (such as a shell a packaged app spawned),
    because there every HKCU write goes to the app's private copy.

.EXAMPLE
    .\windows\setup.ps1                 # status
    .\windows\setup.ps1 -Apply -Start   # install, link, start tiling now
    .\windows\setup.ps1 -Remove
#>
[CmdletBinding()]
param(
    [switch]$Apply,
    [switch]$Start,
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'

$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$GlazeExe = Join-Path $env:ProgramFiles 'glzr.io\GlazeWM\glazewm.exe'
$GlazeConfig = Join-Path $Repo 'windows\glazewm\config.yaml'
$RunKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$RunValue = '"{0}" start --config "{1}"' -f $GlazeExe, $GlazeConfig
$ZebarDir = Join-Path $env:USERPROFILE '.glzr\zebar'
$ZebarPackLink = Join-Path $ZebarDir 'danse'
$ZebarPackSource = Join-Path $Repo 'windows\zebar\danse'
$ZebarSettings = Join-Path $ZebarDir 'settings.json'
$ZebarSettingsSource = Join-Path $Repo 'windows\zebar\settings.json'
$WtSettings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$WtFragmentDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\dotfiles'
$WtFragment = Join-Path $WtFragmentDir 'danse.json'
$WtTemplate = Join-Path $Repo 'windows\windows-terminal\danse.json.tpl'
$Bash = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'

function Say([string]$Message) { Write-Host $Message }

function Get-WingetIds {
    # The manifest is read only through bin/manifest (CLAUDE.md), so this
    # borrows Git Bash rather than parse install/wingetfile here.
    if (-not (Test-Path -LiteralPath $Bash)) { throw "Git Bash not found at $Bash (needed to read install/wingetfile via bin/manifest)." }
    $env:DOTFILES_DIR = $Repo
    $manifest = $Repo.Replace('\', '/') + '/bin/manifest'
    $ids = & $Bash -c "'$manifest' list winget" 2>&1
    if ($LASTEXITCODE -ne 0) { throw "bin/manifest list winget failed: $ids" }
    return @($ids | Where-Object { $_ })
}

function Test-WingetInstalled([string]$Id) {
    $out = (& winget list -e --id $Id --accept-source-agreements --disable-interactivity 2>$null | Out-String)
    return ($LASTEXITCODE -eq 0 -and $out -match [regex]::Escape($Id))
}

function Test-Junction([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    return ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint))
}

function Get-JunctionTarget([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($item -and $item.Target) { return @($item.Target)[0] }
    return $null
}

function Get-ArchProfileGuid {
    if (-not (Test-Path -LiteralPath $WtSettings)) { return $null }
    # settings.json may carry // comments, which ConvertFrom-Json in 5.1 rejects.
    $raw = (Get-Content -LiteralPath $WtSettings -Raw) -replace '(?m)^\s*//.*$', ''
    $json = $raw | ConvertFrom-Json
    $arch = @($json.profiles.list | Where-Object { $_.name -eq 'Arch' -and -not $_.hidden }) | Select-Object -First 1
    if ($arch) { return $arch.guid }
    return $null
}

# ---------------------------------------------------------------- the look
# Taskbar auto-hide, dark mode, palette accent and the La Danse wallpaper.
# Every value this changes is saved once under $BackupKey before the first
# change, so -Remove can put back exactly what was there.

$BackupKey = 'HKCU:\Software\dotfiles\windows-setup'
$PersonalizeKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
$DwmKey = 'HKCU:\Software\Microsoft\Windows\DWM'
$AccentKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'
$DesktopKey = 'HKCU:\Control Panel\Desktop'
# Accent: the palette's blue, #61afef. Windows derives Start and taskbar
# colours from AccentPalette (8 RGBX shades, light to dark), so all of it is
# written, not just the accent DWORD; Explorer otherwise recomputes the menu
# colour from whatever palette was there before.
$AccentRgb = @(0x61, 0xaf, 0xef)

function Get-Shade([int[]]$Rgb, [int]$Target, [double]$Amount) {
    return @($Rgb | ForEach-Object { [int][math]::Round($_ + ($Target - $_) * $Amount) })
}

function Get-AccentShades {
    return @(
        (Get-Shade $AccentRgb 255 0.6), (Get-Shade $AccentRgb 255 0.4), (Get-Shade $AccentRgb 255 0.2),
        $AccentRgb,
        (Get-Shade $AccentRgb 0 0.2), (Get-Shade $AccentRgb 0 0.4), (Get-Shade $AccentRgb 0 0.6),
        @(0x3e, 0x44, 0x51)   # palette surface, Windows' neutral last slot
    )
}

function ConvertTo-Abgr([int[]]$Rgb) {
    # 0xAABBGGRR with full alpha, as the unsigned value Windows reports.
    return [int64]4278190080 + ($Rgb[2] * 65536) + ($Rgb[1] * 256) + $Rgb[0]
}

function ConvertTo-DwordValue([int64]$Unsigned) {
    # Set-ItemProperty -Type DWord takes an Int32; values above 0x7FFFFFFF
    # go through their two's-complement form.
    if ($Unsigned -gt [int32]::MaxValue) { $Unsigned = $Unsigned - 4294967296 }
    return [int32]$Unsigned
}

$AccentAbgr = ConvertTo-Abgr $AccentRgb

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class DotfilesShell {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
    [StructLayout(LayoutKind.Sequential)] public struct APPBARDATA {
        public uint cbSize; public IntPtr hWnd; public uint uCallbackMessage; public uint uEdge; public RECT rc; public IntPtr lParam;
    }
    [DllImport("shell32.dll")] static extern UIntPtr SHAppBarMessage(uint msg, ref APPBARDATA data);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr FindWindow(string cls, string name);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern bool SystemParametersInfo(uint action, uint param, string value, uint flags);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, UIntPtr wParam, string lParam, uint flags, uint timeout, out UIntPtr result);
    const uint ABM_GETSTATE = 4, ABM_SETSTATE = 10;
    static APPBARDATA Bar() {
        APPBARDATA d = new APPBARDATA();
        d.cbSize = (uint)Marshal.SizeOf(typeof(APPBARDATA));
        d.hWnd = FindWindow("Shell_TrayWnd", null);
        return d;
    }
    public static bool GetTaskbarAutoHide() { APPBARDATA d = Bar(); return ((ulong)SHAppBarMessage(ABM_GETSTATE, ref d) & 1) != 0; }
    public static void SetTaskbarAutoHide(bool on) { APPBARDATA d = Bar(); d.lParam = (IntPtr)(on ? 1 : 0); SHAppBarMessage(ABM_SETSTATE, ref d); }
    // SPI_SETDESKWALLPAPER, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE
    public static bool SetWallpaper(string path) { return SystemParametersInfo(0x0014, 0, path, 0x01 | 0x02); }
    // Tell Explorer and apps that the colour set changed (WM_SETTINGCHANGE).
    public static void BroadcastColorChange() {
        UIntPtr r;
        SendMessageTimeout((IntPtr)0xffff, 0x001A, UIntPtr.Zero, "ImmersiveColorSet", 0x0002, 3000, out r);
    }
}
'@

function Get-SandboxPackage {
    # A shell started by an MSIX-packaged app (the Claude desktop app, for one)
    # can inherit its container without having a package identity itself, so
    # GetCurrentPackageFullName says "no package" while HKCU and new AppData
    # files still go to the app's private copy. Test it directly: create a
    # folder in LOCALAPPDATA and see whether it lands in some
    # Packages\<app>\LocalCache instead. Returns that package folder name, or
    # $null.
    $name = 'dotfiles-probe-' + [guid]::NewGuid().ToString('N')
    $probe = Join-Path $env:LOCALAPPDATA $name
    New-Item -ItemType Directory -Path $probe -Force | Out-Null
    try {
        $hit = Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA 'Packages') -Directory -ErrorAction SilentlyContinue |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "LocalCache\Local\$name") } |
            Select-Object -First 1
        if ($hit) { return $hit.Name }
        return $null
    } finally {
        Remove-Item -LiteralPath $probe -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Get-Reg([string]$Key, [string]$Name) {
    $p = Get-ItemProperty -Path $Key -Name $Name -ErrorAction SilentlyContinue
    if (-not $p) { return $null }
    $v = $p.$Name
    # A REG_BINARY comes back as byte[]; returning it bare would unroll it
    # into the pipeline and the caller would get loose bytes, not the array.
    if ($v -is [array]) { return , $v }
    return $v
}

function Save-Original([string]$Name, $Value) {
    # First write wins: a re-run must not overwrite what was there originally.
    if (-not (Test-Path $BackupKey)) { New-Item -Path $BackupKey -Force | Out-Null }
    if ($null -eq (Get-Reg $BackupKey $Name)) {
        $stored = if ($null -eq $Value) { '<absent>' }
                  elseif ($Value -is [byte[]]) { 'b64:' + [Convert]::ToBase64String($Value) }
                  else { [string]$Value }
        Set-ItemProperty -Path $BackupKey -Name $Name -Value $stored
    }
}

function Restore-Original([string]$Name, [string]$Key, [string]$ValueName, [string]$Kind) {
    $stored = Get-Reg $BackupKey $Name
    if ($null -eq $stored) { return }
    if ($stored -eq '<absent>') {
        Remove-ItemProperty -Path $Key -Name $ValueName -ErrorAction SilentlyContinue
    } elseif ($Kind -eq 'DWord') {
        # Windows PowerShell 5.1 returns some DWORDs unsigned (AccentColor came
        # back as 4285230683), so the saved text can exceed Int32.
        Set-ItemProperty -Path $Key -Name $ValueName -Value (ConvertTo-DwordValue ([int64]$stored)) -Type DWord
    } elseif ($Kind -eq 'Binary') {
        Set-ItemProperty -Path $Key -Name $ValueName -Value ([Convert]::FromBase64String($stored.Substring(4))) -Type Binary
    } else {
        Set-ItemProperty -Path $Key -Name $ValueName -Value $stored
    }
}

function Get-ScreenSize {
    # Win32_VideoController reports physical pixels, unlike Forms.Screen under DPI scaling.
    $v = Get-CimInstance Win32_VideoController | Where-Object { $_.CurrentHorizontalResolution } | Select-Object -First 1
    if ($v) { return @([int]$v.CurrentHorizontalResolution, [int]$v.CurrentVerticalResolution) }
    return @(2560, 1440)
}

function Build-Wallpaper {
    # bin/wallpaper composes La Danse onto the palette matte; it needs ImageMagick
    # (install/wingetfile), which a fresh install only put on the machine PATH.
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    $size = Get-ScreenSize
    $script = $Repo.Replace('\', '/') + '/bin/wallpaper'
    $out = & $Bash -c "WALLPAPER_WIDTH=$($size[0]) WALLPAPER_HEIGHT=$($size[1]) '$script' build" 2>&1
    if ($LASTEXITCODE -ne 0) { throw "bin/wallpaper build failed: $out" }
    $unix = @($out | Where-Object { $_ -match '\.png$' })[-1]
    $win = (& $Bash -c "cygpath -w '$unix'" | Select-Object -First 1)
    if (-not (Test-Path -LiteralPath $win)) { throw "bin/wallpaper reported $unix, but $win does not exist" }
    return $win
}

function Get-LookStatus {
    return [ordered]@{
        'taskbar auto-hide' = [DotfilesShell]::GetTaskbarAutoHide()
        'dark mode'         = ((Get-Reg $PersonalizeKey 'AppsUseLightTheme') -eq 0 -and (Get-Reg $PersonalizeKey 'SystemUsesLightTheme') -eq 0)
        'accent'            = (([int64](Get-Reg $DwmKey 'AccentColor') -band 4294967295) -eq $AccentAbgr)
        'wallpaper'         = (Get-Reg $DesktopKey 'WallPaper')
    }
}

function Apply-Look {
    Save-Original 'TaskbarAutoHide' ([int][DotfilesShell]::GetTaskbarAutoHide())
    [DotfilesShell]::SetTaskbarAutoHide($true)
    Say 'taskbar: auto-hide on'

    # Wallpaper first: a new wallpaper makes Windows (and Wallpaper Engine)
    # recompute the accent, which would overwrite colours set before it.
    $wallpaper = Build-Wallpaper
    Save-Original 'WallPaper' (Get-Reg $DesktopKey 'WallPaper')
    Save-Original 'WallpaperStyle' (Get-Reg $DesktopKey 'WallpaperStyle')
    Save-Original 'TileWallpaper' (Get-Reg $DesktopKey 'TileWallpaper')
    Set-ItemProperty -Path $DesktopKey -Name WallpaperStyle -Value '10'   # Fill
    Set-ItemProperty -Path $DesktopKey -Name TileWallpaper -Value '0'
    if (-not [DotfilesShell]::SetWallpaper($wallpaper)) { throw "could not set wallpaper $wallpaper" }
    Say "wallpaper: $wallpaper"
    foreach ($n in 'AppsUseLightTheme', 'SystemUsesLightTheme') {
        Save-Original $n (Get-Reg $PersonalizeKey $n)
        Set-ItemProperty -Path $PersonalizeKey -Name $n -Value 0 -Type DWord
    }
    Save-Original 'AccentColor' (Get-Reg $DwmKey 'AccentColor')
    Save-Original 'AccentColorMenu' (Get-Reg $AccentKey 'AccentColorMenu')
    Save-Original 'StartColorMenu' (Get-Reg $AccentKey 'StartColorMenu')
    Save-Original 'AccentPalette' (Get-Reg $AccentKey 'AccentPalette')
    Save-Original 'AutoColorization' (Get-Reg $DesktopKey 'AutoColorization')
    if (-not (Test-Path $AccentKey)) { New-Item -Path $AccentKey -Force | Out-Null }
    $shades = Get-AccentShades
    $bytes = New-Object byte[] 32
    for ($i = 0; $i -lt 8; $i++) { for ($c = 0; $c -lt 3; $c++) { $bytes[$i * 4 + $c] = [byte]$shades[$i][$c] } }
    Set-ItemProperty -Path $DesktopKey -Name AutoColorization -Value '0'
    Set-ItemProperty -Path $AccentKey -Name AccentPalette -Value $bytes -Type Binary
    Set-ItemProperty -Path $AccentKey -Name AccentColorMenu -Value (ConvertTo-DwordValue $AccentAbgr) -Type DWord
    Set-ItemProperty -Path $AccentKey -Name StartColorMenu -Value (ConvertTo-DwordValue (ConvertTo-Abgr $shades[5])) -Type DWord
    Set-ItemProperty -Path $DwmKey -Name AccentColor -Value (ConvertTo-DwordValue $AccentAbgr) -Type DWord
    [DotfilesShell]::BroadcastColorChange()
    Say 'colours: dark mode on, accent = palette blue (Start and taskbar pick it up fully after sign-out)'

    if (Get-Process wallpaper32, wallpaper64 -ErrorAction SilentlyContinue) {
        Write-Warning 'Wallpaper Engine is running and draws over the desktop; quit it to see this wallpaper.'
    }
}

function Remove-Look {
    if (-not (Test-Path $BackupKey)) { return }
    $hide = Get-Reg $BackupKey 'TaskbarAutoHide'
    if ($null -ne $hide) { [DotfilesShell]::SetTaskbarAutoHide($hide -eq '1') }
    Restore-Original 'AppsUseLightTheme' $PersonalizeKey 'AppsUseLightTheme' 'DWord'
    Restore-Original 'SystemUsesLightTheme' $PersonalizeKey 'SystemUsesLightTheme' 'DWord'
    Restore-Original 'AccentColor' $DwmKey 'AccentColor' 'DWord'
    Restore-Original 'AccentColorMenu' $AccentKey 'AccentColorMenu' 'DWord'
    Restore-Original 'StartColorMenu' $AccentKey 'StartColorMenu' 'DWord'
    Restore-Original 'AccentPalette' $AccentKey 'AccentPalette' 'Binary'
    Restore-Original 'AutoColorization' $DesktopKey 'AutoColorization' 'String'
    Restore-Original 'WallpaperStyle' $DesktopKey 'WallpaperStyle' 'String'
    Restore-Original 'TileWallpaper' $DesktopKey 'TileWallpaper' 'String'
    $wall = Get-Reg $BackupKey 'WallPaper'
    if ($null -ne $wall -and $wall -ne '<absent>') { [void][DotfilesShell]::SetWallpaper($wall) }
    [DotfilesShell]::BroadcastColorChange()
    Remove-Item -Path $BackupKey -Recurse -Force
    Say 'restored taskbar, colours and wallpaper'
}

function Show-Status {
    Say "Checkout: $Repo"
    foreach ($id in Get-WingetIds) {
        Say ('  package {0,-30} {1}' -f $id, $(if (Test-WingetInstalled $id) { 'installed' } else { 'MISSING' }))
    }
    $run = (Get-ItemProperty -Path $RunKey -Name GlazeWM -ErrorAction SilentlyContinue).GlazeWM
    Say ('  autostart GlazeWM           {0}' -f $(if ($run -eq $RunValue) { 'linked' } elseif ($run) { "set elsewhere: $run" } else { 'not set' }))
    $target = Get-JunctionTarget $ZebarPackLink
    Say ('  zebar pack danse            {0}' -f $(if ($target -eq $ZebarPackSource) { 'linked' } elseif (Test-Path -LiteralPath $ZebarPackLink) { "exists, not ours: $target" } else { 'not linked' }))
    $settingsState = 'missing'
    if (Test-Path -LiteralPath $ZebarSettings) {
        $settingsState = if ((Get-FileHash $ZebarSettings).Hash -eq (Get-FileHash $ZebarSettingsSource).Hash) { 'ours' } else { 'differs' }
    }
    Say ('  zebar settings.json         {0}' -f $settingsState)
    Say ('  terminal fragment           {0}' -f $(if (Test-Path -LiteralPath $WtFragment) { 'present' } else { 'not present' }))
    $guid = Get-ArchProfileGuid
    Say ('  terminal Arch profile       {0}' -f $(if ($guid) { $guid } else { 'NOT FOUND' }))
    Say ('  GlazeWM running             {0}' -f [bool](Get-Process glazewm -ErrorAction SilentlyContinue))
    $look = Get-LookStatus
    foreach ($k in $look.Keys) { Say ('  {0,-27} {1}' -f $k, $look[$k]) }
}

# Inside an MSIX container every registry write below would land in the
# app's private hive: the Run value, colours and backups would exist only for
# that app. Refuse instead of reporting success.
if ($Apply -or $Remove) {
    $package = Get-SandboxPackage
    if ($package) {
        throw "This shell runs inside the app package '$package', where registry writes are virtualized. Run setup.ps1 from a normal PowerShell or Windows Terminal window."
    }
}

# ------------------------------------------------------------------ remove
if ($Remove) {
    if (Get-Process glazewm -ErrorAction SilentlyContinue) {
        & (Join-Path $env:ProgramFiles 'glzr.io\GlazeWM\cli\glazewm.exe') command wm-exit 2>$null | Out-Null
        Say 'stopped GlazeWM'
    }
    if ((Get-ItemProperty -Path $RunKey -Name GlazeWM -ErrorAction SilentlyContinue).GlazeWM -eq $RunValue) {
        Remove-ItemProperty -Path $RunKey -Name GlazeWM
        Say 'removed GlazeWM autostart'
    }
    if ((Get-JunctionTarget $ZebarPackLink) -eq $ZebarPackSource) {
        # rmdir on a junction removes the link only; Remove-Item -Recurse in
        # Windows PowerShell 5.1 would walk into the checkout and delete it.
        cmd /c rmdir "$ZebarPackLink" | Out-Null
        Say "unlinked $ZebarPackLink"
    }
    $backup = Get-ChildItem -LiteralPath $ZebarDir -Filter 'settings.json.bak-*' -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1
    if ($backup) {
        Copy-Item -LiteralPath $backup.FullName -Destination $ZebarSettings -Force
        Say "restored zebar settings from $($backup.Name)"
    } elseif ((Test-Path -LiteralPath $ZebarSettings) -and (Get-FileHash $ZebarSettings).Hash -eq (Get-FileHash $ZebarSettingsSource).Hash) {
        Remove-Item -LiteralPath $ZebarSettings
        Say 'removed zebar settings.json (Zebar recreates its default)'
    }
    if (Test-Path -LiteralPath $WtFragmentDir) {
        Remove-Item -LiteralPath $WtFragmentDir -Recurse -Force
        Say 'removed terminal fragment'
    }
    Remove-Look
    exit 0
}

if (-not $Apply) {
    Show-Status
    Say ''
    Say 'Dry run - nothing changed. -Apply links everything; -Apply -Start also starts tiling now.'
    exit 0
}

# ------------------------------------------------------------------ apply
# 1. packages
foreach ($id in Get-WingetIds) {
    if (Test-WingetInstalled $id) { continue }
    Say "installing $id"
    & winget install -e --id $id --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "winget install $id failed ($LASTEXITCODE)" }
}

# 2. GlazeWM at sign-in, reading the config from this checkout
if (-not (Test-Path -LiteralPath $GlazeExe)) { throw "$GlazeExe not found after install" }
Set-ItemProperty -Path $RunKey -Name GlazeWM -Value $RunValue
Say "autostart: $RunValue"

# 3. Zebar widget pack + startup settings
New-Item -ItemType Directory -Path $ZebarDir -Force | Out-Null
$target = Get-JunctionTarget $ZebarPackLink
if ($target -ne $ZebarPackSource) {
    if (Test-Junction $ZebarPackLink) {
        # A junction from an earlier run against another checkout: re-point it.
        cmd /c rmdir "$ZebarPackLink" | Out-Null
    } elseif (Test-Path -LiteralPath $ZebarPackLink) {
        throw "$ZebarPackLink exists and is a real folder, not a junction; move it aside first."
    }
    cmd /c mklink /J "$ZebarPackLink" "$ZebarPackSource" | Out-Null
    if (-not (Test-Junction $ZebarPackLink)) { throw "could not create junction $ZebarPackLink" }
    Say "linked $ZebarPackLink -> $ZebarPackSource"
}
if (Test-Path -LiteralPath $ZebarSettings) {
    if ((Get-FileHash $ZebarSettings).Hash -ne (Get-FileHash $ZebarSettingsSource).Hash) {
        $bak = '{0}.bak-{1:yyyy-MM-dd}' -f $ZebarSettings, (Get-Date)
        Copy-Item -LiteralPath $ZebarSettings -Destination $bak -Force
        Copy-Item -LiteralPath $ZebarSettingsSource -Destination $ZebarSettings -Force
        Say "zebar settings.json replaced (previous kept as $(Split-Path $bak -Leaf))"
    }
} else {
    Copy-Item -LiteralPath $ZebarSettingsSource -Destination $ZebarSettings
    Say 'zebar settings.json written'
}

# 4. Windows Terminal fragment for the Arch profile
$guid = Get-ArchProfileGuid
if ($guid) {
    New-Item -ItemType Directory -Path $WtFragmentDir -Force | Out-Null
    $fragment = (Get-Content -LiteralPath $WtTemplate -Raw).Replace('{{ARCH_PROFILE_GUID}}', $guid)
    [IO.File]::WriteAllText($WtFragment, $fragment, (New-Object Text.UTF8Encoding $false))
    Say "terminal fragment written for Arch profile $guid"
} else {
    Write-Warning 'No visible "Arch" profile in Windows Terminal settings.json; terminal theme skipped.'
}

# 5. the look: taskbar, colours, wallpaper
Apply-Look

# 6. start now
if ($Start -and -not (Get-Process glazewm -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $GlazeExe -ArgumentList @('start', '--config', $GlazeConfig)
    Say 'started GlazeWM'
}

Say ''
Show-Status
