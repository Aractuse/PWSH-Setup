# Guide de desinstallation manuelle

Desinstallation pas a pas de chaque composant. Choisissez uniquement ce que vous souhaitez supprimer.

---

## 1. Modules PowerShell

Executez dans **PowerShell 7** (`pwsh`) :

### Terminal-Icons
```powershell
Uninstall-Module -Name Terminal-Icons -AllVersions -Force
```

### PSReadLine
```powershell
Uninstall-Module -Name PSReadLine -AllVersions -Force
```

**Verification :**
```powershell
Get-Module -ListAvailable Terminal-Icons, PSReadLine
# Doit retourner vide
```

---

## 2. Zoxide

```powershell
# Desinstaller l'application
winget uninstall --id ajeetdsouza.zoxide

# Supprimer la base de donnees
Remove-Item "$env:LOCALAPPDATA\zoxide" -Recurse -Force -ErrorAction SilentlyContinue
```

---

## 3. Vim

```powershell
# Desinstaller l'application
winget uninstall --id vim.vim

# Nettoyer le PATH (si ajoute manuellement)
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$newPath = ($currentPath -split ';' | Where-Object { $_ -notlike "*Vim*" }) -join ';'
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")
```

---

## 4. Yazi

```powershell
# Desinstaller l'application
winget uninstall --id sxyazi.yazi

# Supprimer la configuration
Remove-Item "$env:APPDATA\yazi" -Recurse -Force -ErrorAction SilentlyContinue
```

---

## 5. Police CascadiaCode Nerd Font

### Option A : Commande PowerShell (admin requis)

```powershell
# Lister les polices installees
Get-ChildItem "C:\Windows\Fonts" | Where-Object { $_.Name -like "*Caskaydia*" -or $_.Name -like "*CascadiaCode*" }

# Supprimer les fichiers
Get-ChildItem "C:\Windows\Fonts" | Where-Object { $_.Name -like "*Caskaydia*" } | ForEach-Object {
    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
}
```

### Option B : Manuellement

1. Ouvrir `C:\Windows\Fonts`
2. Rechercher "Caskaydia" ou "CascadiaCode"
3. Selectionner > Supprimer

**Note :** Un redemarrage peut etre necessaire si les polices sont en cours d'utilisation.

---

## 6. Profil PowerShell

```powershell
# Supprimer le profil PowerShell 7
Remove-Item "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Force

# Supprimer le dossier s'il est vide
$profileDir = "$HOME\Documents\PowerShell"
if ((Get-ChildItem $profileDir -ErrorAction SilentlyContinue).Count -eq 0) {
    Remove-Item $profileDir -Force
}
```

---

## 7. Windows Terminal

### Restaurer la configuration d'origine

```powershell
$wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"

# Si un backup existe
if (Test-Path "$wtPath\settings.json.backup") {
    Copy-Item "$wtPath\settings.json.backup" "$wtPath\settings.json" -Force
    Remove-Item "$wtPath\settings.json.backup" -Force
    Write-Host "Configuration restauree depuis le backup"
}
```

### Ou remettre les parametres par defaut

```powershell
$wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
Remove-Item "$wtPath\settings.json" -Force
# Windows Terminal recree un fichier par defaut au prochain lancement
```

---

## 8. PowerShell 7 (optionnel)

```powershell
winget uninstall --id Microsoft.PowerShell
```

**Attention :** Si vous utilisez PowerShell 7 pour d'autres projets, gardez-le.

---

## Desinstallation rapide (tout en une fois)

Copiez-collez ce bloc pour tout supprimer :

```powershell
# Applications
winget uninstall --id JanDeDobbeleer.OhMyPosh --silent
winget uninstall --id ajeetdsouza.zoxide --silent
winget uninstall --id vim.vim --silent
winget uninstall --id sxyazi.yazi --silent

# Modules (dans pwsh)
pwsh -NoProfile -Command "Uninstall-Module Terminal-Icons -AllVersions -Force -ErrorAction SilentlyContinue"
pwsh -NoProfile -Command "Uninstall-Module PSReadLine -AllVersions -Force -ErrorAction SilentlyContinue"

# Fichiers de config
Remove-Item "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\zoxide" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\yazi" -Recurse -Force -ErrorAction SilentlyContinue

# Variables d'environnement
[Environment]::SetEnvironmentVariable("POSH_THEMES_PATH", $null, "User")

# Nettoyer PATH (Vim)
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$newPath = ($currentPath -split ';' | Where-Object { $_ -notlike "*Vim*" }) -join ';'
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")

Write-Host "Desinstallation terminee. Redemarrez le terminal." -ForegroundColor Green
```

---

## Nettoyage du PATH

Si des chemins residuels restent dans le PATH :

```powershell
# Voir le PATH actuel
$env:Path -split ';' | ForEach-Object { Write-Host $_ }

# Supprimer une entree specifique
$pathToRemove = "C:\chemin\a\supprimer"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$newPath = ($currentPath -split ';' | Where-Object { $_ -ne $pathToRemove }) -join ';'
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")
```

---

## Verification finale

```powershell
# Verifier que tout est supprime
@(
    @{ Name = "Oh-My-Posh"; Check = { Get-Command oh-my-posh -ErrorAction SilentlyContinue } }
    @{ Name = "Zoxide"; Check = { Get-Command zoxide -ErrorAction SilentlyContinue } }
    @{ Name = "Vim"; Check = { Get-Command vim -ErrorAction SilentlyContinue } }
    @{ Name = "Yazi"; Check = { Get-Command yazi -ErrorAction SilentlyContinue } }
    @{ Name = "Terminal-Icons"; Check = { Get-Module -ListAvailable Terminal-Icons } }
    @{ Name = "Profil PS7"; Check = { Test-Path "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" } }
) | ForEach-Object {
    $result = & $_.Check
    if ($result) {
        Write-Host "$($_.Name): Encore present" -ForegroundColor Yellow
    } else {
        Write-Host "$($_.Name): Supprime" -ForegroundColor Green
    }
}
```

---

## Reinstaller

Pour reinstaller, utilisez :
- Le script automatique : `.\Install.ps1`
- Ou le guide manuel : `Install.md`
