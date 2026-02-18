# Installation manuelle

## PowerShell 7

```powershell
winget install --id Microsoft.PowerShell
```

Verification :
```powershell
pwsh --version
```

## Terminal-Icons

```powershell
Install-Module Terminal-Icons -Scope CurrentUser -Force
```

Verification :
```powershell
Get-Module -ListAvailable Terminal-Icons
```

## PSReadLine

```powershell
Install-Module PSReadLine -Scope CurrentUser -Force -AllowClobber
```

Verification :
```powershell
Get-Module -ListAvailable PSReadLine
```

## Zoxide

```powershell
winget install --id ajeetdsouza.zoxide
```

Verification :
```powershell
zoxide --version
```

## Yazi

```powershell
winget install --id sxyazi.yazi
```

Verification :
```powershell
yazi --version
```

## Vim

```powershell
winget install --id vim.vim
```

Verification :
```powershell
vim --version
```

## CascadiaCode Nerd Font

Telechargement manuel : https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip

Extraire et installer les fichiers .ttf dans `C:\Windows\Fonts` (droits admin requis).

Verification :
```powershell
Get-ChildItem "C:\Windows\Fonts" | Where-Object { $_.Name -like "*CaskaydiaCove*" }
```

## Profil PowerShell

```powershell
$profilePath = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
New-Item -Path (Split-Path $profilePath) -ItemType Directory -Force
irm 'https://raw.githubusercontent.com/aractuse/pwsh-setup/main/config/profile.ps1' -OutFile $profilePath
```

Verification :
```powershell
Test-Path $PROFILE
```

## Config Windows Terminal

```powershell
$wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
irm 'https://raw.githubusercontent.com/aractuse/pwsh-setup/main/config/settings.json' -OutFile $wtPath
```

Verification :
```powershell
Test-Path $wtPath
```
