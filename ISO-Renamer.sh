#!/bin/bash

clear
echo -e "\033[1;36m=== ISO Renamer Utility ===\033[0m"
echo -e "\033[0;37mThis script will scan a folder for .iso files and generate cleaner, standardized names.\033[0m"
echo -e "\033[0;37mNo files will be renamed until you confirm.\033[0m"
echo ""

# Prompt for folder
while true; do
    read -rp "Please enter the full path to the folder containing ISO files: " isoFolder
    if [[ -d "$isoFolder" ]]; then
        break
    else
        echo -e "\033[0;31m⚠️  The path '$isoFolder' does not exist. Please try again.\033[0m"
    fi
done

cd "$isoFolder" || exit 1

isoFiles=(*.iso)
if [[ ${#isoFiles[@]} -eq 0 ]]; then
    echo -e "\033[0;33m❌ No .iso files found in '$isoFolder'. Exiting.\033[0m"
    exit 1
fi

# Known casing map
declare -A knownCasing=(
    [pfsense]="pfSense" [opnsense]="OPNsense" [elementaryos]="elementaryOS" [endeavouros]="EndeavourOS"
    [proxmox]="Proxmox" [archlinux]="Arch Linux" [kali]="Kali Linux" [ubuntu]="Ubuntu" [debian]="Debian"
    [fedora]="Fedora" [windows]="Windows" [raspios]="Raspios" [freebsd]="FreeBSD" [macos]="macOS"
    [opensuse]="openSUSE" [nixos]="NixOS" [alpine]="Alpine" [parrot]="Parrot" [pop]="Pop" [os]="OS"
    [openbsd]="OpenBSD"
)

declare -A archMap=(
    ["x86 64"]="x86_64" ["x64"]="x86_64"
)

archRegex="x86_64|x86 64|amd64|x64v[0-9]+|x64|i386|i686|arm64|aarch64"

declare -a renamePlan

# Function to apply known casing
apply_known_casing() {
    local text="$1"
    for key in "${!knownCasing[@]}"; do
        text=$(echo "$text" | sed -E "s/\b${key}\b/${knownCasing[$key]}/Ig")
    done
    echo "$text"
}

# Begin processing
for file in *.iso; do
    base="${file%.iso}"
    newName="$base"

    # Normalize separators
    newName=$(echo "$newName" | sed -E 's/[-_]+/ /g' | sed -E 's/\s+/ /g')

    # Extract architecture
    arch=$(echo "$newName" | grep -Eo "$archRegex" | head -n1 | tr '[:upper:]' '[:lower:]')
    if [[ -n "$arch" && -n "${archMap[$arch]}" ]]; then
        arch="${archMap[$arch]}"
    fi
    [[ -n "$arch" ]] && newName=$(echo "$newName" | sed -E "s/(\(| )?$arch(\)| )?//Ig")

    # Cleanup
    newName=$(echo "$newName" | sed -E 's/\s+/ /g; s/^\s+|\s+$//g')

    # Apply known casing
    newName=$(apply_known_casing "$newName")

    # Capitalize generic words
    newName=$(echo "$newName" | awk '{for (i=1; i<=NF; i++) {if ($i ~ /^[0-9]+(\.[0-9]+)*$/) {out=out $i} else {out=out toupper(substr($i,1,1)) tolower(substr($i,2))} out=out " "} print out}')

    newName=$(echo "$newName" | sed -E 's/\s+/ /g; s/\s+$//')

    # Re-add architecture
    [[ -n "$arch" ]] && newName="$newName ($arch)"

    newFile="${newName}.iso"

    # Check warnings
    warnings=""
    [[ -z "$arch" ]] && warnings+="missing architecture, "
    [[ ! "$newName" =~ [0-9]+\.[0-9]+ ]] && warnings+="missing version, "
    wordCount=$(echo "$newName" | wc -w)
    (( wordCount < 2 )) && warnings+="suspiciously short name, "
    warnings="${warnings%, }"

    renamePlan+=("$file|$newFile|$warnings")
done

# Dry run output
echo -e "\n\033[1;36m=== Dry Run: Preview of Renames ===\033[0m"
for entry in "${renamePlan[@]}"; do
    IFS="|" read -r original new warning <<< "$entry"
    if [[ "$original" == "$new" ]]; then
        color="\033[1;90m"
    elif [[ -n "$warning" ]]; then
        color="\033[1;33m"
    else
        color="\033[1;37m"
    fi
    echo -e "${color}\"$original\" --> \"$new\"\033[0m"
    [[ -n "$warning" ]] && echo -e "  \033[1;33m⚠️  $warning\033[0m"
done

# Confirm
read -rp $'\nProceed with renaming? (y/N): ' confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    for entry in "${renamePlan[@]}"; do
        IFS="|" read -r original new warning <<< "$entry"
        if [[ "$original" != "$new" ]]; then
            mv -i -- "$original" "$new"
            echo -e "\033[1;32mRenamed: '$original' → '$new'\033[0m"
        else
            echo -e "\033[1;90mSkipped: '$original' (no change)\033[0m"
        fi
    done
    echo -e "\n\033[1;32m✅ Rename complete.\033[0m"
else
    echo -e "\n\033[1;33m❌ Aborted. No changes made.\033[0m"
fi
