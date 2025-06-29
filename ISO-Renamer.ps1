Clear-Host
Write-Host "=== ISO Renamer Utility ===" -ForegroundColor Cyan
Write-Host "This script will scan a folder for .iso files and generate cleaner, standardized names." -ForegroundColor Gray
Write-Host "No files will be renamed until you confirm." -ForegroundColor Gray
Write-Host ""

# Prompt user for folder
do {
    $isoFolder = Read-Host "Please enter the full path to the folder containing ISO files"
    if (-not (Test-Path $isoFolder)) {
        Write-Host "âš ï¸  The path '$isoFolder' does not exist. Please try again." -ForegroundColor Red
    }
} until (Test-Path $isoFolder)

# Gather all .iso files
$isoFiles = Get-ChildItem -Path $isoFolder -Filter *.iso
if ($isoFiles.Count -eq 0) {
    Write-Host "âŒ No .iso files found in '$isoFolder'. Exiting." -ForegroundColor Yellow
    exit
}

$renamePlan = @()

# Brand casing map
$knownCasing = @{
    "pfsense"     = "pfSense"
    "opnsense"    = "OPNsense"
    "elementaryos"= "elementaryOS"
    "endeavouros" = "EndeavourOS"
    "proxmox"     = "Proxmox"
    "archlinux"   = "Arch Linux"
    "kali linux"  = "Kali Linux"
    "ubuntu"      = "Ubuntu"
    "debian"      = "Debian"
    "fedora"      = "Fedora"
    "windows"     = "Windows"
    "raspios"     = "Raspios"
    "freebsd"     = "FreeBSD"
    "macos"       = "macOS"
    "opensuse"    = "openSUSE"
    "nixos"       = "NixOS"
    "alpine"      = "Alpine"
    "parrot"      = "Parrot"
    "pop"         = "Pop"
    "os"          = "OS"
    "openbsd"     = "OpenBSD"
}

# Architecture detection and normalization
$archPatterns = 'x86_64|x86 64|amd64|x64v\d+|x64|i386|i686|arm64|aarch64'
$normalizedArchMap = @{
    "x86 64" = "x86_64"
    "x64"    = "x86_64"
    "x64v1"  = "x64v1"
}

foreach ($file in $isoFiles) {
    $originalName = $file.Name
    $baseName = $file.BaseName
    $extension = $file.Extension
    $newName = $baseName

    # Step 1: Replace dashes and underscores with spaces except inside version numbers
    $newName = $newName -replace '(?<!\d)[-_](?![\d\.])', ' '

    # Step 2: Remove any remaining dash if it appears next to letters (e.g. before 'linux')
    $newName = $newName -replace '\s*-\s*', ' '

    # Step 3: Collapse multiple spaces to a single space
    $newName = $newName -replace '\s+', ' '

    # Extract and normalize architecture (remove if found)
    $arch = ""
    $archMatches = [regex]::Matches($newName, $archPatterns, 'IgnoreCase')
    if ($archMatches.Count -gt 0) {
        $arch = $archMatches[0].Value.ToLower()
        if ($normalizedArchMap.ContainsKey($arch)) {
            $arch = $normalizedArchMap[$arch]
        }
        foreach ($match in $archMatches) {
            $escaped = [regex]::Escape($match.Value)
            $newName = [regex]::Replace($newName, "\b$escaped\b", "", 'IgnoreCase')
            $newName = [regex]::Replace($newName, "\(\s*$escaped\s*\)", "", 'IgnoreCase')
        }
    }

    # Clean up leftover characters/spaces
    $newName = $newName -replace '\(\s*\)', ''
    $newName = $newName -replace '\s{2,}', ' '
    $newName = $newName.Trim()

    # Apply known casing
    foreach ($key in $knownCasing.Keys) {
        $pattern = "\b$key\b"
        if ($newName -match $pattern) {
            $newName = $newName -replace $pattern, $knownCasing[$key]
        }
    }

    # Capitalize generic words unless known special
    $newName = (($newName -split ' ') | ForEach-Object {
        if ($_ -match '^\d') { $_ }
        elseif ($_ -match '^\d+\.\d+(\.\d+)?$') { $_ }
        elseif ($_ -match '^[A-Z]{2,}$') { $_ } # e.g. RELEASE
        elseif ($knownCasing.Values -contains $_) { $_ }
        else { $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() }
    }) -join ' '

    # Final cleanup before re-adding architecture
    $newName = $newName -replace '\(\s*\)', ''                 # Remove empty parentheses
    $newName = $newName -replace '\s{2,}', ' '                 # Collapse multiple spaces
    $newName = $newName -replace '[\-\._]+$', ''               # Remove trailing punctuation
    $newName = $newName -replace '\s+\)', ')'                  # Trim space before closing parens
    $newName = $newName -replace '\(\s+', '('                  # Trim space after opening parens
    $newName = $newName.Trim()

    # Append architecture if detected
    if ($arch -ne "") {
        $newName = "$newName ($arch)"
    }

    # Final filename
    $newFileName = "$newName$extension"

    # Flag potential issues
    $warnings = @()
    if (-not $arch) { $warnings += "missing architecture" }
    if ($newName -notmatch '\b\d+(\.\d+)+\b') { $warnings += "missing version" }
    if (($newName -split ' ').Count -lt 2) { $warnings += "suspiciously short name" }

    # Save plan
    $renamePlan += [PSCustomObject]@{
        Original = $originalName
        NewName  = $newFileName
        FullPath = $file.FullName
        Warnings = ($warnings -join ', ')
    }
}

# Dry Run Output
Write-Host "`n=== Dry Run: Preview of Renames ===" -ForegroundColor Cyan
$renamePlan | ForEach-Object {
    $msg = "`"$($_.Original)`" --> `"$($_.NewName)`""
    $color = if ($_.Original -eq $_.NewName) { 'DarkGray' } elseif ($_.Warnings) { 'Yellow' } else { 'White' }
    Write-Host $msg -ForegroundColor $color
    if ($_.Warnings) {
        Write-Host "  âš ï¸  $($_.Warnings)" -ForegroundColor Yellow
    }
}

# Confirm
$confirmation = Read-Host "`nProceed with renaming? (y/N)"
if ($confirmation -match '^[Yy]$') {
    foreach ($item in $renamePlan) {
        if ($item.Original -ne $item.NewName) {
            Rename-Item -Path $item.FullPath -NewName $item.NewName
            Write-Host "Renamed: '$($item.Original)' â†’ '$($item.NewName)'" -ForegroundColor Green
        } else {
            Write-Host "Skipped: '$($item.Original)' (no change)" -ForegroundColor DarkGray
        }
    }
    Write-Host "`nâœ… Rename complete." -ForegroundColor Green
} else {
    Write-Host "`nâŒ Aborted. No changes made." -ForegroundColor Yellow
}
