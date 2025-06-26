# 📀 ISO Renamer Utility

A cross-platform shell script that scans a folder for `.iso` files and suggests cleaner, more standardized names. Supports a dry run preview and only renames files after your confirmation.

---

## ✨ Features

- Automatically detects and normalizes:
  - Common OS/brand names (e.g., `ubuntu`, `archlinux`, `windows`)
  - Architecture labels (e.g., `x86_64`, `arm64`, `i386`)
  - Version formats (e.g., `20.04`, `2023.09.1`)
- Fixes messy separators like dashes, underscores, and excess spacing
- Adds proper casing (e.g., `elementaryos` → `elementaryOS`)
- Shows warnings for suspicious names (e.g., missing version or architecture)
- Displays a dry-run preview before renaming
- Safe and interactive

---

## 🚀 How to Use

### 🔧 Requirements

- **Linux/macOS**: Bash shell (default on most systems)
- **Windows**:
  - Option 1: Use [WSL](https://learn.microsoft.com/en-us/windows/wsl/) (Windows Subsystem for Linux)
  - Option 2: Use [Git Bash](https://gitforwindows.org/) or another Unix-like shell
  - Option 3: Run the original PowerShell version instead

---

### 🐧 Linux/macOS Instructions

```bash
# Step 1: Download the script
https://github.com/Dark-Avenger-Reborn/ISO-Renamer.git
cd ISO-Renamer

# Step 2: Make it executable
chmod +x ISO-Renamer.sh

# Step 3: Run the script
./ISO-Renamer.sh
```

---

### 🪟 Windows Instructions

#### Option 1: Using Git Bash or WSL

1. Open **Git Bash** or **WSL terminal**
2. Navigate to the folder containing `ISO-Renamer.sh`
3. Run the script:

```bash
bash ISO-Renamer.sh
```

#### Option 2: Use the PowerShell Version

Download and run `ISO-Renamer.ps1` using PowerShell. Run from terminal with:

```powershell
.\ISO-Renamer.ps1
```

> ⚠️ You may need to allow script execution first:
> 
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

---

## 🧪 Example

Suppose your folder has these files:

```
ubuntu-20.04.6-live-server-amd64.iso
archlinux_2023.05.01_x86_64.iso
elementaryos_7.0-20230205.iso
```

The script will suggest:

```
"ubuntu-20.04.6-live-server-amd64.iso" --> "Ubuntu 20.04.6 Live Server (x86_64)"
"archlinux_2023.05.01_x86_64.iso" --> "Arch Linux 2023.05.01 (x86_64)"
"elementaryos_7.0-20230205.iso" --> "elementaryOS 7.0 20230205"
```

And warn if version/architecture is missing or unclear.

---

## ❓ FAQ

### Can I undo the renaming?
No built-in undo currently. You may want to:
- Manually verify the dry run output
- Back up filenames beforehand
- Use Git or `rsnapshot` for versioned backups

### Does it support `.ISO` uppercase extensions?
Yes, file matching is case-insensitive.

---

## 🛠️ Customization

You can extend the script by editing:

- `knownCasing` — to add more known brand formats
- `archMap` — to normalize more architecture labels
- Regex rules — for fine-tuning version or platform patterns

Commits to this repo are welcome and encouraged!
---

## 📁 File Structure

```
ISO-Renamer.sh      # Bash version of the utility
ISO-Renamer.ps1     # PowerShell version (for native Windows use)
README.md           # This file
```

---

## 📝 License

MIT License. Use freely, improve, and share!
