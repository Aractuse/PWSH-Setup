<#
.SYNOPSIS
    Script de desinstallation du Kit PowerShell 7

.DESCRIPTION
    Desinstalle et nettoie tous les composants installes par Install.ps1 :
    - Oh-My-Posh
    - Terminal-Icons
    - PSReadLine
    - Zoxide
    - Vim
    - Yazi
    - CascadiaCode Nerd Font
    - Profil PowerShell
    - Configuration Windows Terminal

.PARAMETER KeepPowerShell
    Conserver PowerShell 7 sans demander

.PARAMETER RemovePowerShell
    Supprimer PowerShell 7 sans demander

.PARAMETER Force
    Supprimer sans confirmation

.EXAMPLE
    .\Uninstall.ps1
    Desinstallation interactive

.EXAMPLE
    .\Uninstall.ps1 -KeepPowerShell -Force
    Desinstallation automatique en gardant PowerShell 7
#>

param(
    [switch]$KeepPowerShell,
    [switch]$RemovePowerShell,
    [switch]$Force
)

$ErrorActionPreference = "Continue"

# Couleurs pour les messages
function Write-Step { param($Message) Write-Host "`n>> $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "   [OK] $Message" -ForegroundColor Green }
function Write-Skip { param($Message) Write-Host "   [SKIP] $Message" -ForegroundColor Yellow }
function Write-Fail { param($Message) Write-Host "   [FAIL] $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "   [INFO] $Message" -ForegroundColor Gray }

# ============================================
# Confirmation initiale
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Red
Write-Host "    DESINSTALLATION DU KIT POWERSHELL      " -ForegroundColor Red
Write-Host "============================================" -ForegroundColor Red
Write-Host ""
Write-Host "Ce script va supprimer :" -ForegroundColor Yellow
Write-Host "  - Oh-My-Posh"
Write-Host "  - Modules PowerShell (Terminal-Icons, PSReadLine)"
Write-Host "  - Zoxide, Vim, Yazi"
Write-Host "  - CascadiaCode Nerd Font"
Write-Host "  - Profil PowerShell personnalise"
Write-Host "  - Theme Oh-My-Posh personnalise"
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Continuer la desinstallation? (o/N)"
    if ($confirm -ne "o" -and $confirm -ne "O") {
        Write-Host "Desinstallation annulee." -ForegroundColor Yellow
        exit 0
    }
}

# ============================================
# 1. Desinstallation de Oh-My-Posh
# ============================================
Write-Step "Desinstallation de Oh-My-Posh"

$ompInstalled = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($ompInstalled) {
    try {
        winget uninstall --id JanDeDobbeleer.OhMyPosh --silent
        Write-Success "Oh-My-Posh desinstalle"
    } catch {
        Write-Fail "Erreur lors de la desinstallation de Oh-My-Posh: $_"
    }
} else {
    Write-Skip "Oh-My-Posh non installe"
}

# Supprimer le theme personnalise
$ompThemesPath = $env:POSH_THEMES_PATH
if (-not $ompThemesPath) {
    $ompThemesPath = Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\themes"
}
$customTheme = Join-Path $ompThemesPath "mytheme.omp.json"
if (Test-Path $customTheme) {
    Remove-Item $customTheme -Force -ErrorAction SilentlyContinue
    Write-Success "Theme personnalise supprime"
}

# Supprimer la variable d'environnement POSH_THEMES_PATH
$currentPoshPath = [Environment]::GetEnvironmentVariable("POSH_THEMES_PATH", "User")
if ($currentPoshPath) {
    [Environment]::SetEnvironmentVariable("POSH_THEMES_PATH", $null, "User")
    Write-Success "Variable POSH_THEMES_PATH supprimee"
}

# ============================================
# 2. Desinstallation des modules PowerShell
# ============================================
Write-Step "Desinstallation des modules PowerShell"

$modules = @("Terminal-Icons", "PSReadLine")
$pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue

foreach ($moduleName in $modules) {
    try {
        # Desinstaller via PowerShell 7 si disponible
        if ($pwshPath) {
            $checkCmd = "if (Get-Module -ListAvailable -Name '$moduleName') { 'true' } else { 'false' }"
            $result = pwsh -NoProfile -Command $checkCmd 2>$null

            if ($result -eq 'true') {
                $uninstallCmd = "Uninstall-Module -Name '$moduleName' -AllVersions -Force -ErrorAction SilentlyContinue"
                pwsh -NoProfile -Command $uninstallCmd 2>$null
                Write-Success "$moduleName desinstalle"
            } else {
                Write-Skip "$moduleName non installe"
            }
        } else {
            # Fallback PowerShell actuel
            if (Get-Module -ListAvailable -Name $moduleName) {
                Uninstall-Module -Name $moduleName -AllVersions -Force -ErrorAction SilentlyContinue
                Write-Success "$moduleName desinstalle"
            } else {
                Write-Skip "$moduleName non installe"
            }
        }
    } catch {
        Write-Fail "Erreur lors de la desinstallation de $moduleName"
    }
}

# ============================================
# 3. Desinstallation de Zoxide
# ============================================
Write-Step "Desinstallation de Zoxide"

$zoxideInstalled = Get-Command zoxide -ErrorAction SilentlyContinue
if ($zoxideInstalled) {
    try {
        winget uninstall --id ajeetdsouza.zoxide --silent
        Write-Success "Zoxide desinstalle"
    } catch {
        Write-Fail "Erreur lors de la desinstallation de Zoxide"
    }
} else {
    Write-Skip "Zoxide non installe"
}

# Nettoyer la base de donnees Zoxide
$zoxideDb = Join-Path $env:LOCALAPPDATA "zoxide"
if (Test-Path $zoxideDb) {
    Remove-Item $zoxideDb -Recurse -Force -ErrorAction SilentlyContinue
    Write-Success "Base de donnees Zoxide supprimee"
}

# ============================================
# 4. Desinstallation de Vim
# ============================================
Write-Step "Desinstallation de Vim"

$vimInstalled = Get-Command vim -ErrorAction SilentlyContinue
if ($vimInstalled) {
    try {
        winget uninstall --id vim.vim --silent
        Write-Success "Vim desinstalle"

        # Nettoyer le PATH
        $vimPaths = @(
            "C:\Program Files\Vim\vim91",
            "C:\Program Files\Vim\vim90",
            "C:\Program Files (x86)\Vim\vim91",
            "C:\Program Files (x86)\Vim\vim90"
        )

        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $pathModified = $false

        foreach ($vimPath in $vimPaths) {
            if ($currentPath -like "*$vimPath*") {
                $currentPath = ($currentPath.Split(';') | Where-Object { $_ -ne $vimPath }) -join ';'
                $pathModified = $true
            }
        }

        if ($pathModified) {
            [Environment]::SetEnvironmentVariable("Path", $currentPath, "User")
            Write-Success "PATH nettoye (Vim)"
        }
    } catch {
        Write-Fail "Erreur lors de la desinstallation de Vim"
    }
} else {
    Write-Skip "Vim non installe"
}

# ============================================
# 5. Desinstallation de Yazi
# ============================================
Write-Step "Desinstallation de Yazi"

$yaziInstalled = Get-Command yazi -ErrorAction SilentlyContinue
if ($yaziInstalled) {
    try {
        winget uninstall --id sxyazi.yazi --silent
        Write-Success "Yazi desinstalle"
    } catch {
        Write-Fail "Erreur lors de la desinstallation de Yazi"
    }
} else {
    Write-Skip "Yazi non installe"
}

# Nettoyer la configuration Yazi
$yaziConfig = Join-Path $env:APPDATA "yazi"
if (Test-Path $yaziConfig) {
    Remove-Item $yaziConfig -Recurse -Force -ErrorAction SilentlyContinue
    Write-Success "Configuration Yazi supprimee"
}

# ============================================
# 6. Desinstallation des polices Nerd Font
# ============================================
Write-Step "Desinstallation de CascadiaCode Nerd Font"

$installedFonts = Get-ChildItem "C:\Windows\Fonts" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*CaskaydiaCove*" -or $_.Name -like "*CascadiaCode*" }

if ($installedFonts) {
    try {
        foreach ($font in $installedFonts) {
            $fontPath = "C:\Windows\Fonts\$($font.Name)"

            # Supprimer le fichier de police
            Remove-Item $fontPath -Force -ErrorAction SilentlyContinue

            # Supprimer l'entree du registre
            $fontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            $fontEntries = Get-ItemProperty -Path $fontRegistryPath -ErrorAction SilentlyContinue

            foreach ($prop in $fontEntries.PSObject.Properties) {
                if ($prop.Value -eq $font.Name) {
                    Remove-ItemProperty -Path $fontRegistryPath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                }
            }
        }
        Write-Success "CascadiaCode Nerd Font desinstallee ($($installedFonts.Count) fichiers)"
        Write-Info "Note: Un redemarrage peut etre necessaire pour liberer les polices"
    } catch {
        Write-Fail "Erreur lors de la desinstallation des polices: $_"
    }
} else {
    Write-Skip "CascadiaCode Nerd Font non installee"
}

# ============================================
# 7. Suppression du profil PowerShell
# ============================================
Write-Step "Suppression du profil PowerShell"

$pwsh7Profile = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1"

if (Test-Path $pwsh7Profile) {
    if (-not $Force) {
        $response = Read-Host "   Supprimer le profil PowerShell 7? (o/N)"
        if ($response -eq "o" -or $response -eq "O") {
            Remove-Item $pwsh7Profile -Force
            Write-Success "Profil PowerShell 7 supprime"
        } else {
            Write-Skip "Profil conserve"
        }
    } else {
        Remove-Item $pwsh7Profile -Force
        Write-Success "Profil PowerShell 7 supprime"
    }
} else {
    Write-Skip "Profil PowerShell 7 non trouve"
}

# ============================================
# 8. Restauration de Windows Terminal
# ============================================
Write-Step "Restauration de Windows Terminal"

$wtSettingsPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$wtBackupPath = "$wtSettingsPath.backup"

if (Test-Path $wtBackupPath) {
    if (-not $Force) {
        $response = Read-Host "   Restaurer la configuration Windows Terminal d'origine? (o/N)"
        if ($response -eq "o" -or $response -eq "O") {
            Copy-Item $wtBackupPath $wtSettingsPath -Force
            Remove-Item $wtBackupPath -Force
            Write-Success "Configuration Windows Terminal restauree"
        } else {
            Write-Skip "Configuration conservee"
        }
    } else {
        Copy-Item $wtBackupPath $wtSettingsPath -Force
        Remove-Item $wtBackupPath -Force
        Write-Success "Configuration Windows Terminal restauree"
    }
} else {
    Write-Info "Aucune sauvegarde Windows Terminal trouvee"
}

# ============================================
# 9. Desinstallation de PowerShell 7 (optionnel)
# ============================================
Write-Step "Desinstallation de PowerShell 7"

$pwshInstalled = Get-Command pwsh -ErrorAction SilentlyContinue

if ($pwshInstalled) {
    $removePwsh = $false

    if ($RemovePowerShell) {
        $removePwsh = $true
    } elseif ($KeepPowerShell) {
        $removePwsh = $false
        Write-Skip "PowerShell 7 conserve (parametre -KeepPowerShell)"
    } else {
        Write-Host ""
        Write-Host "   PowerShell 7 est installe." -ForegroundColor Yellow
        Write-Host "   Voulez-vous le conserver? (Recommande: oui)" -ForegroundColor Yellow
        Write-Host ""
        $response = Read-Host "   Garder PowerShell 7? (O/n)"

        if ($response -eq "n" -or $response -eq "N") {
            $removePwsh = $true
        }
    }

    if ($removePwsh) {
        try {
            winget uninstall --id Microsoft.PowerShell --silent
            Write-Success "PowerShell 7 desinstalle"

            # Supprimer le dossier de configuration PowerShell 7
            $pwshConfigDir = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell"
            if (Test-Path $pwshConfigDir) {
                $dirContent = Get-ChildItem $pwshConfigDir -ErrorAction SilentlyContinue
                if (-not $dirContent -or $dirContent.Count -eq 0) {
                    Remove-Item $pwshConfigDir -Force -ErrorAction SilentlyContinue
                    Write-Success "Dossier PowerShell vide supprime"
                }
            }
        } catch {
            Write-Fail "Erreur lors de la desinstallation de PowerShell 7"
        }
    } else {
        Write-Skip "PowerShell 7 conserve"
    }
} else {
    Write-Skip "PowerShell 7 non installe"
}

# ============================================
# 10. Nettoyage final
# ============================================
Write-Step "Nettoyage final"

# Rafraichir les variables d'environnement
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
Write-Success "Variables d'environnement rafraichies"

# ============================================
# Resume de la desinstallation
# ============================================
Write-Host "`n" -NoNewline
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "       Desinstallation terminee!           " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Actions recommandees:" -ForegroundColor Yellow
Write-Host "  1. Fermez et rouvrez votre terminal"
Write-Host "  2. Redemarrez si les polices ne sont pas liberees"
Write-Host ""
Write-Host "Pour reinstaller:" -ForegroundColor Gray
Write-Host "  .\Install.ps1"
Write-Host ""
