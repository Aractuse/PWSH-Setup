<#
.SYNOPSIS
    Script d'installation du Kit PowerShell 7

.DESCRIPTION
    Installe et configure un environnement PowerShell 7 moderne avec :
    - PowerShell 7
    - Oh-My-Posh
    - Terminal-Icons
    - PSReadLine
    - Zoxide
    - Vim
    - Yazi (gestionnaire de fichiers TUI)
    - CascadiaCode Nerd Font

.PARAMETER SkipFonts
    Ignore l'installation des polices Nerd Font

.PARAMETER SkipVim
    Ignore l'installation de Vim

.PARAMETER SkipYazi
    Ignore l'installation de Yazi (gestionnaire de fichiers TUI)

.PARAMETER Force
    Ecrase les fichiers existants sans confirmation

.EXAMPLE
    .\Install.ps1
    Installation complete

.EXAMPLE
    .\Install.ps1 -SkipVim -SkipFonts
    Installation sans Vim ni polices
#>

param(
    [switch]$SkipFonts,
    [switch]$SkipVim,
    [switch]$SkipYazi,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$KitRoot = $PSScriptRoot
$ConfigPath = Join-Path $KitRoot "config"

# Couleurs pour les messages
function Write-Step { param($Message) Write-Host "`n>> $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "   [OK] $Message" -ForegroundColor Green }
function Write-Skip { param($Message) Write-Host "   [SKIP] $Message" -ForegroundColor Yellow }
function Write-Fail { param($Message) Write-Host "   [FAIL] $Message" -ForegroundColor Red }

# ============================================
# Verification des prerequis
# ============================================
Write-Step "Verification des prerequis"

# Verifier winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Fail "winget n'est pas installe. Installez 'App Installer' depuis le Microsoft Store."
    exit 1
}
Write-Success "winget disponible"

# Verifier les fichiers de configuration
$RequiredFiles = @(
    "profile.ps1",
    "settings.json",
    "mytheme.omp.json"
)

foreach ($file in $RequiredFiles) {
    $filePath = Join-Path $ConfigPath $file
    if (-not (Test-Path $filePath)) {
        Write-Fail "Fichier manquant: config\$file"
        exit 1
    }
}
Write-Success "Fichiers de configuration presents"

# ============================================
# 1. Installation de PowerShell 7
# ============================================
Write-Step "Installation de PowerShell 7"

$pwshInstalled = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwshInstalled) {
    $version = (pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null)
    Write-Skip "PowerShell 7 deja installe (v$version)"
} else {
    try {
        winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements
        Write-Success "PowerShell 7 installe"
    } catch {
        Write-Fail "Erreur lors de l'installation de PowerShell 7: $_"
    }
}

# ============================================
# 2. Installation de Oh-My-Posh
# ============================================
Write-Step "Installation de Oh-My-Posh"

$ompInstalled = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($ompInstalled -and -not $Force) {
    Write-Skip "Oh-My-Posh deja installe"
} else {
    try {
        winget install --id JanDeDobbeleer.OhMyPosh --source winget --accept-package-agreements --accept-source-agreements
        Write-Success "Oh-My-Posh installe"

        # Rafraichir le PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    } catch {
        Write-Fail "Erreur lors de l'installation de Oh-My-Posh: $_"
    }
}

# ============================================
# 3. Installation des modules PowerShell
# ============================================
Write-Step "Installation des modules PowerShell"

# S'assurer que le fournisseur NuGet est installe
$nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
if (-not $nugetProvider -or $nugetProvider.Version -lt [version]"2.8.5.201") {
    Write-Host "   Installation du fournisseur NuGet..." -ForegroundColor Gray
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
}

# Configurer PSGallery comme source de confiance
$psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if ($psGallery.InstallationPolicy -ne "Trusted") {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

$modules = @(
    @{ Name = "Terminal-Icons"; Description = "Icones pour le terminal" },
    @{ Name = "PSReadLine"; Description = "Autocompletion amelioree" }
)

# Installer les modules via pwsh si disponible (pour PowerShell 7)
$pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue

foreach ($module in $modules) {
    # Verifier si le module est deja installe dans PowerShell 7
    $installedInPwsh = $false
    if ($pwshPath) {
        $checkCmd = "if (Get-Module -ListAvailable -Name '$($module.Name)') { 'true' } else { 'false' }"
        $result = pwsh -NoProfile -Command $checkCmd 2>$null
        $installedInPwsh = $result -eq 'true'
    }

    if ($installedInPwsh -and -not $Force) {
        Write-Skip "$($module.Name) deja installe"
    } else {
        try {
            if ($pwshPath) {
                # Installer via PowerShell 7 pour s'assurer que le module est dans le bon chemin
                $installCmd = "Install-Module -Name '$($module.Name)' -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck -AllowPrerelease:(`$false)"
                pwsh -NoProfile -Command $installCmd 2>$null
                Write-Success "$($module.Name) installe pour PowerShell 7 - $($module.Description)"
            } else {
                # Fallback: installer via le PowerShell actuel
                Install-Module -Name $module.Name -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
                Write-Success "$($module.Name) installe - $($module.Description)"
            }
        } catch {
            Write-Fail "Erreur lors de l'installation de $($module.Name): $_"
        }
    }
}

# ============================================
# 4. Installation de Zoxide
# ============================================
Write-Step "Installation de Zoxide"

$zoxideInstalled = Get-Command zoxide -ErrorAction SilentlyContinue
if ($zoxideInstalled -and -not $Force) {
    Write-Skip "Zoxide deja installe"
} else {
    try {
        winget install --id ajeetdsouza.zoxide --source winget --accept-package-agreements --accept-source-agreements
        Write-Success "Zoxide installe"

        # Rafraichir le PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    } catch {
        Write-Fail "Erreur lors de l'installation de Zoxide: $_"
    }
}

# ============================================
# 5. Installation de Vim
# ============================================
if (-not $SkipVim) {
    Write-Step "Installation de Vim"

    $vimInstalled = Get-Command vim -ErrorAction SilentlyContinue
    if ($vimInstalled -and -not $Force) {
        Write-Skip "Vim deja installe"
    } else {
        try {
            winget install --id vim.vim --source winget --accept-package-agreements --accept-source-agreements

            # Ajouter Vim au PATH utilisateur
            $vimPaths = @(
                "C:\Program Files\Vim\vim91",
                "C:\Program Files\Vim\vim90",
                "C:\Program Files (x86)\Vim\vim91",
                "C:\Program Files (x86)\Vim\vim90"
            )

            $vimPath = $vimPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

            if ($vimPath) {
                $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
                if ($currentPath -notlike "*$vimPath*") {
                    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$vimPath", "User")
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                    Write-Success "Vim installe et ajoute au PATH: $vimPath"
                } else {
                    Write-Success "Vim installe (deja dans le PATH)"
                }
            } else {
                Write-Success "Vim installe (ajoutez manuellement le chemin au PATH si necessaire)"
            }
        } catch {
            Write-Fail "Erreur lors de l'installation de Vim: $_"
        }
    }
} else {
    Write-Step "Installation de Vim"
    Write-Skip "Ignore (parametre -SkipVim)"
}

# ============================================
# 6. Installation de Yazi (gestionnaire de fichiers TUI)
# ============================================
if (-not $SkipYazi) {
    Write-Step "Installation de Yazi"

    $yaziInstalled = Get-Command yazi -ErrorAction SilentlyContinue
    if ($yaziInstalled -and -not $Force) {
        Write-Skip "Yazi deja installe"
    } else {
        try {
            winget install --id sxyazi.yazi --source winget --accept-package-agreements --accept-source-agreements
            Write-Success "Yazi installe"

            # Rafraichir le PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        } catch {
            Write-Fail "Erreur lors de l'installation de Yazi: $_"
        }
    }
} else {
    Write-Step "Installation de Yazi"
    Write-Skip "Ignore (parametre -SkipYazi)"
}

# ============================================
# 8. Installation des polices Nerd Font
# ============================================
if (-not $SkipFonts) {
    Write-Step "Installation de CascadiaCode Nerd Font"

    $fontName = "CaskaydiaCove Nerd Font"
    $fontsFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
    $installedFonts = (Get-ChildItem "C:\Windows\Fonts" | Where-Object { $_.Name -like "*CaskaydiaCove*" })

    if ($installedFonts -and -not $Force) {
        Write-Skip "CascadiaCode Nerd Font deja installee"
    } else {
        try {
            # Utiliser le fichier local CascadiaCode.zip
            $localZip = Join-Path $ConfigPath "CascadiaCode.zip"
            $tempExtract = Join-Path $env:TEMP "CascadiaCode"

            if (-not (Test-Path $localZip)) {
                Write-Fail "Fichier manquant: config\CascadiaCode.zip"
                Write-Host "   Telechargez-le depuis: https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip" -ForegroundColor Gray
            } else {
                Write-Host "   Extraction de la police locale..." -ForegroundColor Gray

                # Extraire
                if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
                Expand-Archive -Path $localZip -DestinationPath $tempExtract -Force

                # Installer les polices
                $fontFiles = Get-ChildItem -Path $tempExtract -Filter "*.ttf" -Recurse
                foreach ($font in $fontFiles) {
                    $fontPath = $font.FullName
                    $fontDestination = "C:\Windows\Fonts\$($font.Name)"

                    if (-not (Test-Path $fontDestination)) {
                        Copy-Item $fontPath $fontDestination -Force

                        # Enregistrer la police dans le registre
                        $fontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
                        $fontDisplayName = $font.BaseName
                        New-ItemProperty -Path $fontRegistryPath -Name "$fontDisplayName (TrueType)" -Value $font.Name -PropertyType String -Force | Out-Null
                    }
                }

                # Nettoyage du dossier temporaire
                Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue

                Write-Success "CascadiaCode Nerd Font installee (depuis fichier local)"
            }
        } catch {
            Write-Fail "Erreur lors de l'installation des polices: $_"
        }
    }
} else {
    Write-Step "Installation des polices"
    Write-Skip "Ignore (parametre -SkipFonts)"
}

# ============================================
# 9. Configuration du profil PowerShell
# ============================================
Write-Step "Configuration du profil PowerShell"

# Determiner le chemin du profil pour PowerShell 7
$pwsh7Profile = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1"
$pwsh7ProfileDir = Split-Path $pwsh7Profile -Parent

# Creer le dossier si necessaire
if (-not (Test-Path $pwsh7ProfileDir)) {
    New-Item -ItemType Directory -Path $pwsh7ProfileDir -Force | Out-Null
}

# Verifier si le profil existe deja
if ((Test-Path $pwsh7Profile) -and -not $Force) {
    $response = Read-Host "   Le profil existe deja. Ecraser? (o/N)"
    if ($response -ne "o" -and $response -ne "O") {
        Write-Skip "Profil non modifie"
    } else {
        Copy-Item (Join-Path $ConfigPath "profile.ps1") $pwsh7Profile -Force
        Write-Success "Profil PowerShell 7 configure: $pwsh7Profile"
    }
} else {
    Copy-Item (Join-Path $ConfigPath "profile.ps1") $pwsh7Profile -Force
    Write-Success "Profil PowerShell 7 configure: $pwsh7Profile"
}

# ============================================
# 10. Copie du theme Oh-My-Posh
# ============================================
Write-Step "Configuration du theme Oh-My-Posh"

# Obtenir le chemin des themes Oh-My-Posh
$ompThemesPath = $env:POSH_THEMES_PATH
if (-not $ompThemesPath) {
    # Chemin par defaut si la variable n'est pas definie
    $ompThemesPath = Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\themes"
}

if (-not (Test-Path $ompThemesPath)) {
    # Essayer un autre chemin commun
    $ompThemesPath = Join-Path $env:USERPROFILE ".poshthemes"
    if (-not (Test-Path $ompThemesPath)) {
        New-Item -ItemType Directory -Path $ompThemesPath -Force | Out-Null
    }
}

$themeSource = Join-Path $ConfigPath "mytheme.omp.json"
$themeDestination = Join-Path $ompThemesPath "mytheme.omp.json"

# Definir la variable d'environnement si necessaire
if (-not $env:POSH_THEMES_PATH) {
    [Environment]::SetEnvironmentVariable("POSH_THEMES_PATH", $ompThemesPath, "User")
    $env:POSH_THEMES_PATH = $ompThemesPath
}

if ((Test-Path $themeDestination) -and -not $Force) {
    $response = Read-Host "   Le theme existe deja. Ecraser? (o/N)"
    if ($response -ne "o" -and $response -ne "O") {
        Write-Skip "Theme non modifie"
    } else {
        Copy-Item $themeSource $themeDestination -Force
        Write-Success "Theme copie: $themeDestination"
    }
} else {
    Copy-Item $themeSource $themeDestination -Force
    Write-Success "Theme copie: $themeDestination"
}

# ============================================
# 11. Configuration de Windows Terminal
# ============================================
Write-Step "Configuration de Windows Terminal"

$wtSettingsPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path (Split-Path $wtSettingsPath -Parent)) {
    if ((Test-Path $wtSettingsPath) -and -not $Force) {
        $response = Read-Host "   Les parametres Windows Terminal existent. Ecraser? (o/N)"
        if ($response -ne "o" -and $response -ne "O") {
            Write-Skip "Parametres Windows Terminal non modifies"
        } else {
            # Sauvegarder l'ancien fichier
            $backupPath = "$wtSettingsPath.backup"
            Copy-Item $wtSettingsPath $backupPath -Force
            Write-Host "   Sauvegarde creee: $backupPath" -ForegroundColor Gray

            Copy-Item (Join-Path $ConfigPath "settings.json") $wtSettingsPath -Force
            Write-Success "Parametres Windows Terminal configures"
        }
    } else {
        Copy-Item (Join-Path $ConfigPath "settings.json") $wtSettingsPath -Force
        Write-Success "Parametres Windows Terminal configures"
    }
} else {
    Write-Skip "Windows Terminal non installe"
}

# ============================================
# Resume de l'installation
# ============================================
Write-Host "`n" -NoNewline
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "        Installation terminee!             " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Prochaines etapes:" -ForegroundColor Yellow
Write-Host "  1. Fermez et rouvrez votre terminal"
Write-Host "  2. Lancez PowerShell 7 (pwsh)"
Write-Host "  3. Verifiez que le prompt Oh-My-Posh s'affiche"
Write-Host ""
Write-Host "Si les icones ne s'affichent pas:" -ForegroundColor Yellow
Write-Host "  - Verifiez que la police 'CaskaydiaCove Nerd Font' est selectionnee"
Write-Host "  - Windows Terminal > Parametres > Profil > Apparence > Police"
Write-Host ""
Write-Host "Fichiers configures:" -ForegroundColor Gray
Write-Host "  - Profil: $pwsh7Profile"
Write-Host "  - Theme:  $themeDestination"
if (Test-Path (Split-Path $wtSettingsPath -Parent)) {
    Write-Host "  - Terminal: $wtSettingsPath"
}
Write-Host ""
