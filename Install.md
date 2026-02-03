# Guide d'installation manuelle

Installation pas a pas de chaque composant. Choisissez uniquement ce dont vous avez besoin.

---

## Prerequis

```powershell
# Autoriser l'execution de scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verifier winget
winget --version
```

Si winget ne fonctionne pas, voir [Reparer winget](#reparer-winget) en bas de page.

---

## 1. PowerShell 7

```powershell
winget install --id Microsoft.PowerShell --source winget
```

**Verification :**
```powershell
pwsh --version
```

---

## 2. Oh-My-Posh

```powershell
winget install --id JanDeDobbeleer.OhMyPosh --source winget
```

**Verification :**
```powershell
oh-my-posh --version
```

**Configurer le theme :**
```powershell
# Copier le theme personnalise
$themesPath = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
Copy-Item ".\config\mytheme.omp.json" "$themesPath\mytheme.omp.json"

# Definir la variable d'environnement
[Environment]::SetEnvironmentVariable("POSH_THEMES_PATH", $themesPath, "User")
```

---

## 3. Modules PowerShell

Executez ces commandes dans **PowerShell 7** (`pwsh`) :

### Terminal-Icons
```powershell
Install-Module -Name Terminal-Icons -Scope CurrentUser -Force
```

### PSReadLine
```powershell
Install-Module -Name PSReadLine -Scope CurrentUser -Force -AllowPrerelease
```

**Verification :**
```powershell
Get-Module -ListAvailable Terminal-Icons, PSReadLine
```

---

## 4. Zoxide

```powershell
winget install --id ajeetdsouza.zoxide --source winget
```

**Verification :**
```powershell
zoxide --version
```

---

## 5. Vim (optionnel)

```powershell
winget install --id vim.vim --source winget
```

**Ajouter au PATH si necessaire :**
```powershell
$vimPath = "C:\Program Files\Vim\vim91"  # Ajuster selon version
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
[Environment]::SetEnvironmentVariable("Path", "$currentPath;$vimPath", "User")
```

**Verification :**
```powershell
vim --version
```

---

## 6. Yazi (optionnel)

```powershell
winget install --id sxyazi.yazi --source winget
```

**Verification :**
```powershell
yazi --version
```

---

## 7. Police CascadiaCode Nerd Font

### Option A : Depuis le zip local

```powershell
# Extraire
Expand-Archive -Path ".\config\CascadiaCode.zip" -DestinationPath "$env:TEMP\CascadiaCode" -Force

# Copier les polices (admin requis)
Get-ChildItem "$env:TEMP\CascadiaCode" -Filter "*.ttf" -Recurse | ForEach-Object {
    Copy-Item $_.FullName "C:\Windows\Fonts\" -Force
}

# Nettoyer
Remove-Item "$env:TEMP\CascadiaCode" -Recurse -Force
```

### Option B : Installation manuelle

1. Telecharger : https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip
2. Extraire le zip
3. Selectionner tous les fichiers `.ttf`
4. Clic droit > **Installer**

**Verification :**
```powershell
Get-ChildItem "C:\Windows\Fonts" | Where-Object { $_.Name -like "*Caskaydia*" }
```

---

## 8. Profil PowerShell

```powershell
# Creer le dossier si necessaire
$profileDir = "$HOME\Documents\PowerShell"
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force }

# Copier le profil
Copy-Item ".\config\profile.ps1" "$profileDir\Microsoft.PowerShell_profile.ps1" -Force
```

**Verification :**
```powershell
# Recharger
. $PROFILE

# Ou redemarrer PowerShell
```

---

## 9. Windows Terminal

```powershell
# Sauvegarder l'ancienne config
$wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
Copy-Item "$wtPath\settings.json" "$wtPath\settings.json.backup" -Force

# Copier la nouvelle config
Copy-Item ".\config\settings.json" "$wtPath\settings.json" -Force
```

---

## Installation rapide (tout en une fois)

Si winget fonctionne, copiez-collez ce bloc :

```powershell
# Applications
winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements
winget install --id JanDeDobbeleer.OhMyPosh --source winget --accept-package-agreements --accept-source-agreements
winget install --id ajeetdsouza.zoxide --source winget --accept-package-agreements --accept-source-agreements
winget install --id vim.vim --source winget --accept-package-agreements --accept-source-agreements
winget install --id sxyazi.yazi --source winget --accept-package-agreements --accept-source-agreements

# Modules (dans pwsh)
pwsh -NoProfile -Command "Install-Module Terminal-Icons -Scope CurrentUser -Force"
pwsh -NoProfile -Command "Install-Module PSReadLine -Scope CurrentUser -Force"
```

---

## Reparer winget

Si winget ne fonctionne pas (commandes sans resultat, spinner bloque) :

### Solution 1 : Re-enregistrer App Installer

```powershell
Get-AppxPackage *Microsoft.DesktopAppInstaller* | Reset-AppxPackage
```

### Solution 2 : Reinstaller App Installer

```powershell
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
```

### Solution 3 : Installer manuellement

1. Telecharger depuis : https://github.com/microsoft/winget-cli/releases/latest
2. Installer le fichier `.msixbundle`

### Solution 4 : Installer les dependances

```powershell
Add-AppxPackage -Path "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
```

---

## Verification finale

```powershell
# Tout verifier d'un coup
@{
    "PowerShell 7" = { pwsh --version }
    "Oh-My-Posh" = { oh-my-posh --version }
    "Zoxide" = { zoxide --version }
    "Vim" = { vim --version | Select-Object -First 1 }
    "Yazi" = { yazi --version }
    "Terminal-Icons" = { if (Get-Module -ListAvailable Terminal-Icons) { "OK" } else { "Non installe" } }
    "PSReadLine" = { (Get-Module -ListAvailable PSReadLine).Version.ToString() }
}.GetEnumerator() | ForEach-Object {
    try {
        $result = & $_.Value 2>$null
        Write-Host "$($_.Key): $result" -ForegroundColor Green
    } catch {
        Write-Host "$($_.Key): Non installe" -ForegroundColor Yellow
    }
}
```
