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
      5. -Start also launches GlazeWM now (it re-tiles every open window)

    -Remove: undo 2-4 (the junction is unlinked, never recursed into; a
    backed-up settings.json is restored) and stop GlazeWM. Packages stay
    installed: `winget uninstall --id <id>` if wanted.

    Run it from the checkout that should stay: links point at this copy.

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

# 5. start now
if ($Start -and -not (Get-Process glazewm -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $GlazeExe -ArgumentList @('start', '--config', $GlazeConfig)
    Say 'started GlazeWM'
}

Say ''
Show-Status
