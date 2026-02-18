# Desinstallation manuelle

## Vim

```powershell
winget uninstall --id vim.vim
```

Verification :
```powershell
Get-Command vim -ErrorAction SilentlyContinue
```

## Yazi

```powershell
winget uninstall --id sxyazi.yazi
```

Verification :
```powershell
Get-Command yazi -ErrorAction SilentlyContinue
```

## Zoxide

```powershell
winget uninstall --id ajeetdsouza.zoxide
```

Verification :
```powershell
Get-Command zoxide -ErrorAction SilentlyContinue
```

## Terminal-Icons

```powershell
Uninstall-Module Terminal-Icons -Force -AllVersions
```

Verification :
```powershell
Get-Module -ListAvailable Terminal-Icons
```

## PSReadLine

```powershell
Uninstall-Module PSReadLine -Force -AllVersions
```

Verification :
```powershell
Get-Module -ListAvailable PSReadLine
```

## CascadiaCode Nerd Font

Supprimer manuellement les fichiers CaskaydiaCove* dans `C:\Windows\Fonts` (droits admin requis).

Verification :
```powershell
Get-ChildItem "C:\Windows\Fonts" | Where-Object { $_.Name -like "*CaskaydiaCove*" }
```

## Profil PowerShell

```powershell
Remove-Item $PROFILE -Force
```

Verification :
```powershell
Test-Path $PROFILE
```

## Config Windows Terminal

Restaurer le backup ou supprimer :
```powershell
$wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Remove-Item $wtPath -Force
```

Verification :
```powershell
Test-Path $wtPath
```

## PowerShell 7

```powershell
winget uninstall --id Microsoft.PowerShell
```

Verification :
```powershell
Get-Command pwsh -ErrorAction SilentlyContinue
```
