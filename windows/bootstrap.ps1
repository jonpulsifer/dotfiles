<#
.SYNOPSIS
    Takes a bare Windows box to a working desk.

.DESCRIPTION
    Run it with:

        irm https://raw.githubusercontent.com/jonpulsifer/dotfiles/main/windows/bootstrap.ps1 | iex

    Stages, each idempotent and safe to re-run:

      0. Re-exec under PowerShell 7 with the same switches -- the one-liner
         above may well land in Windows PowerShell 5.1, so everything in this
         file has to parse there.
         No ternaries, no ?? and no && in this script for that reason.
      1. Check winget is present.
      2. winget configure the DSC file: applications and OS settings, including
         the Developer Mode that lets the deploy create symlinks unelevated.
      3. Clone the repo.
      4. mise run bootstrap, which routes to bootstrap:windows.
      5. Optionally install WSL and hand off to the Linux bootstrap inside it.

    Windows is the outer ring here: it installs WSL, not the other way round.
    Nothing in this bootstrap reads anything from inside the distro.

.PARAMETER WithWsl
    Also install WSL and run the Linux dotfiles bootstrap inside the default
    distro. Left out of a routine re-run so that reshaping the shell config
    never touches the distro.

.PARAMETER SkipConfiguration
    Skip the winget configure pass. Useful when only the dotfiles changed.
#>
[CmdletBinding()]
param(
    [switch] $WithWsl,
    [switch] $SkipConfiguration
)

$ErrorActionPreference = 'Stop'

$RepoSlug = 'jonpulsifer/dotfiles'
$RawBase = "https://raw.githubusercontent.com/$RepoSlug/main/windows"
$BootstrapUrl = "$RawBase/bootstrap.ps1"
$CheckoutPath = Join-Path $env:USERPROFILE 'src\github.com\jonpulsifer\dotfiles'

function Write-Stage {
    param([string] $Message)
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-Command {
    param([string] $Name)
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    return $null -ne $command
}

# Only reloads this process's PATH, so ShouldProcess does not apply.
function Update-SessionPath {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param()

    # winget writes PATH to the registry only, so tools it just installed need this.
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:PATH = "$machine;$user"
}

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Stage 'Windows PowerShell 5.1 detected, moving to PowerShell 7'

    if (-not (Test-Command 'winget')) {
        throw 'winget (App Installer) is missing. Install it from the Microsoft Store, then run this again.'
    }

    if (-not (Test-Command 'pwsh')) {
        winget install --id Microsoft.PowerShell --source winget `
            --accept-package-agreements --accept-source-agreements
        Update-SessionPath
    }

    if (-not (Test-Command 'pwsh')) {
        throw 'PowerShell 7 still is not on PATH. Open a new terminal and run this again.'
    }

    $switches = @()
    if ($WithWsl) { $switches += '-WithWsl' }
    if ($SkipConfiguration) { $switches += '-SkipConfiguration' }

    # Under `irm | iex` there is no file on disk to hand to pwsh.
    & pwsh -NoProfile -Command "& ([scriptblock]::Create((irm $BootstrapUrl))) $($switches -join ' ')"
    return
}

if (-not (Test-Command 'winget')) {
    throw 'winget (App Installer) is missing. Install it from the Microsoft Store, then run this again.'
}

if (-not $SkipConfiguration) {
    Write-Stage 'Applying the winget configuration (applications and OS settings)'

    $localConfiguration = Join-Path $CheckoutPath 'dotfiles\windows\configuration.winget'
    $temporaryConfiguration = $null

    if (Test-Path -LiteralPath $localConfiguration) {
        $configuration = $localConfiguration
    }
    else {
        # First run: there is no checkout yet, and this configuration installs git.
        $temporaryConfiguration = Join-Path ([IO.Path]::GetTempPath()) 'configuration.winget'
        Invoke-WebRequest -Uri "$RawBase/configuration.winget" -OutFile $temporaryConfiguration -UseBasicParsing
        $configuration = $temporaryConfiguration
    }

    winget configure --file $configuration `
        --accept-configuration-agreements --disable-interactivity

    if ($temporaryConfiguration) {
        Remove-Item -LiteralPath $temporaryConfiguration -Force -ErrorAction SilentlyContinue
    }

    Update-SessionPath
}

Write-Stage "Checking out $RepoSlug to $CheckoutPath"

if (-not (Test-Command 'git')) {
    throw 'git is missing. Run without -SkipConfiguration so the configuration pass installs it.'
}

if (Test-Path -LiteralPath (Join-Path $CheckoutPath '.git')) {
    git -C $CheckoutPath pull --ff-only
}
else {
    New-Item -ItemType Directory -Path (Split-Path -Parent $CheckoutPath) -Force | Out-Null

    # Git for Windows defaults core.autocrlf to true, which rewrites the checkout.
    git clone -c core.autocrlf=false "https://github.com/$RepoSlug.git" $CheckoutPath
}

Write-Stage 'Running the dotfiles bootstrap'

if (-not (Test-Command 'mise')) {
    throw 'mise is missing. Run without -SkipConfiguration so the configuration pass installs it.'
}

$dotfiles = $CheckoutPath
mise trust --yes (Join-Path $dotfiles 'mise.toml')
mise run --cd $dotfiles bootstrap

Write-Stage 'Installing the terminal font'
& (Join-Path $dotfiles 'windows\Install-NerdFont.ps1')

# -AutoStart adds the login entry. The tray app does nothing until it runs.
Write-Stage 'Installing vibranceGUI'
& (Join-Path $dotfiles 'windows\Install-VibranceGui.ps1') -AutoStart

if ($WithWsl) {
    Write-Stage 'Installing WSL and handing off to the Linux bootstrap'
    & (Join-Path $dotfiles 'windows\Install-Wsl.ps1')
}

Write-Host ''
Write-Host 'Done. Open a new PowerShell 7 tab to pick up the profile.' -ForegroundColor Green
