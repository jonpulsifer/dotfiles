# Shims select tool versions when invoked, without a process or prompt hook at startup.
# Use mise run/exec for project environment variables.
$miseData = if ($env:MISE_DATA_DIR) { $env:MISE_DATA_DIR } else { Join-Path $env:LOCALAPPDATA 'mise' }
$miseShims = if ($env:MISE_SHIMS_DIR) { $env:MISE_SHIMS_DIR } else { Join-Path $miseData 'shims' }
$env:PATH = "$HOME\.local\bin;$miseShims;$env:PATH"
