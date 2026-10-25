#Requires -Version 7.0
<#
.SYNOPSIS
    Installs WSL and imports a NixOS distro, then hands off.

.DESCRIPTION
    The last stage of bootstrap.ps1 -WithWsl, and the reason the Windows config
    is the outer ring rather than an afterthought.

    Windows cannot build this repo's own WSL image -- `nix build .#wsl` needs
    Nix, which needs a Linux box -- so the chain is: import an upstream
    NixOS-WSL image, clone this repo inside it, and let the distro rebuild
    itself from nix/images/wsl.nix. Pass -TarballPath to import an image built
    here instead, which skips the upstream hop.

    /home lives on its own VHDX, not on the distro's disk, so a distro can be
    replaced and keep its home. The image attaches that disk at every boot and
    will not boot without it. Importing this repo's image runs wsl-home-init,
    which creates the disk unless it exists already.

    This script stops at the handoff. It does not run nixos-rebuild: what
    happens inside the distro is nix/'s business, not Windows'.

.PARAMETER Name
    Distro name to import as.

.PARAMETER TarballPath
    A locally built image (`nix build .#wsl`). Without it, the latest upstream
    NixOS-WSL release is downloaded.

.PARAMETER Location
    Where the distro's virtual disk lives.

.PARAMETER Replace
    Unregister an existing distro of the same name first. It refuses unless
    that distro's /home is on the home disk, so nothing but the root disk goes.
#>
[CmdletBinding()]
param(
    [string] $Name = 'NixOS',
    [string] $TarballPath,
    [string] $Location = (Join-Path $env:LOCALAPPDATA 'WSL'),
    [switch] $Replace
)

$homeLabel = 'nixos-home'

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$existing = wsl.exe --list --quiet 2>$null | ForEach-Object { $_.Trim() } | Where-Object { $_ }
if ($existing -contains $Name) {
    if (-not $Replace) {
        Write-Host "  ok       distro '$Name' already exists; leaving it alone"
        Write-Host '  (a distro is somebody'' s running machine -- pass -Replace to swap its root disk)'
        return
    }
    $homeOn = (wsl.exe -d $Name -u root -- findmnt -no LABEL /home 2>$null | Out-String).Trim()
    if ($homeOn -ne $homeLabel) {
        throw "Distro '$Name' does not mount /home from the '$homeLabel' disk. Replacing it would delete its home."
    }
    if (-not $TarballPath) {
        throw '-Replace needs -TarballPath: the upstream image does not mount the home disk.'
    }
    Write-Host "  unregistering '$Name' (its home stays on the home disk)"
    wsl.exe --unregister $Name
}

# --no-distribution skips the default Ubuntu install.
Write-Host '  enabling WSL components'
wsl.exe --install --no-distribution

$downloaded = $null
try {
    if (-not $TarballPath) {
        Write-Host '  fetching the latest NixOS-WSL release'
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/nix-community/NixOS-WSL/releases/latest' -UseBasicParsing
        $asset = $release.assets | Where-Object { $_.name -eq 'nixos.wsl' } | Select-Object -First 1
        if (-not $asset) {
            throw 'No nixos.wsl asset in the latest NixOS-WSL release.'
        }

        $downloaded = Join-Path ([IO.Path]::GetTempPath()) 'nixos.wsl'
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $downloaded -UseBasicParsing
        $TarballPath = $downloaded

        Write-Host "  got $($release.tag_name)"
    }

    New-Item -ItemType Directory -Path $Location -Force | Out-Null

    Write-Host "  importing '$Name' into $Location"
    wsl.exe --install --from-file $TarballPath --name $Name --location (Join-Path $Location $Name) --no-launch
    wsl.exe --set-default $Name

    if (-not $downloaded) {
        # The first boot without a home disk stops short of /home; root still gets a shell.
        wsl.exe -d $Name -u root -- wsl-home-init
        if ($LASTEXITCODE -ne 0) {
            throw 'wsl-home-init failed; see its message above.'
        }
    }
    wsl.exe --terminate $Name
    # Without it the root disk only ever grows.
    wsl.exe --manage $Name --set-sparse true
}
finally {
    if ($downloaded) {
        Remove-Item -LiteralPath $downloaded -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host "Distro '$Name' is up. Finish inside it:" -ForegroundColor Green
if ($downloaded) {
    Write-Host @"
  # the upstream image does not mount the home disk yet; boot into this repo's config first
  wsl -d $Name -- sudo nixos-rebuild boot --flake github:jonpulsifer/infra#wsl
  wsl --terminate $Name
  wsl -d $Name -u root -- wsl-home-init
  wsl --terminate $Name

"@
}
Write-Host @"
  wsl -d $Name

  # the distro's own clone -- nothing is shared across the boundary
  git clone https://github.com/jonpulsifer/infra ~/src/github.com/jonpulsifer/infra
  cd ~/src/github.com/jonpulsifer/infra

  # the sops operator age key goes to ~/.config/age/keys.txt first;
  # see docs/runbooks/manage-sops-secrets.md
  sudo nixos-rebuild switch --flake .#wsl
"@
