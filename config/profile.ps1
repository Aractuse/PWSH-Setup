# PowerShell 7 Profile
# =====================

# ------------------------------------------
# Terminal-Icons - Icônes dans le terminal
# ------------------------------------------
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

# ------------------------------------------
# PSReadLine - Autocomplétion et historique
# ------------------------------------------
$psReadLineModule = Get-Module -Name PSReadLine -ErrorAction SilentlyContinue
if (-not $psReadLineModule) {
    $psReadLineModule = Get-Module -ListAvailable -Name PSReadLine | Sort-Object Version -Descending | Select-Object -First 1
    if ($psReadLineModule) {
        Import-Module PSReadLine -ErrorAction SilentlyContinue
    }
}

if ($psReadLineModule -and $psReadLineModule.Version -ge [version]"2.2.0") {
    try {
        # Options d'historique (requiert PSReadLine 2.2.0+)
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
        Set-PSReadLineOption -HistoryNoDuplicates:$true
        Set-PSReadLineOption -HistorySearchCursorMovesToEnd:$true

        # Raccourcis clavier
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    } catch {
        # Silencieusement ignorer les erreurs PSReadLine
    }
} elseif ($psReadLineModule) {
    # Version ancienne de PSReadLine - configuration basique
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# ------------------------------------------
# Zoxide - Navigation intelligente
# ------------------------------------------
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# ------------------------------------------
# Yazi - Gestionnaire de fichiers TUI
# ------------------------------------------
if (Get-Command yazi -ErrorAction SilentlyContinue) {
    # Fonction wrapper pour changer de repertoire a la sortie de yazi
    function y {
        $tmp = [System.IO.Path]::GetTempFileName()
        yazi $args --cwd-file="$tmp"
        $cwd = Get-Content -Path $tmp -ErrorAction SilentlyContinue
        if ($cwd -and $cwd -ne $PWD.Path) {
            Set-Location -Path $cwd
        }
        Remove-Item -Path $tmp -ErrorAction SilentlyContinue
    }
}

# ------------------------------------------
# Alias utiles
# ------------------------------------------
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name la -Value Get-ChildItem
Set-Alias -Name touch -Value New-Item
Set-Alias -Name which -Value Get-Command
Set-Alias -Name grep -Value Select-String

# Alias Git (si Git est installé)
if (Get-Command git -ErrorAction SilentlyContinue) {
    function gs { git status }
    function ga { git add $args }
    function gc { git commit -m $args }
    function gp { git push }
    function gl { git pull }
    function gd { git diff $args }
    function gco { git checkout $args }
    function gb { git branch $args }
    function glog { git log --oneline --graph --decorate -20 }
}

# ------------------------------------------
# Fonctions utilitaires
# ------------------------------------------

# Créer un dossier et y accéder
function mkcd {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location -Path $Path
}

# Ouvrir l'explorateur dans le dossier courant
function explorer {
    param([string]$Path = ".")
    Start-Process explorer.exe -ArgumentList $Path
}

# Afficher l'arborescence du dossier courant
function tree {
    param(
        [string]$Path = ".",
        [int]$Depth = 2
    )
    Get-ChildItem -Path $Path -Recurse -Depth $Depth |
        ForEach-Object {
            $indent = "  " * ($_.FullName.Split([IO.Path]::DirectorySeparatorChar).Count - (Get-Location).Path.Split([IO.Path]::DirectorySeparatorChar).Count)
            "$indent$($_.Name)"
        }
}

# Obtenir l'IP publique
function Get-PublicIP {
    (Invoke-RestMethod -Uri "https://api.ipify.org?format=json").ip
}

# Supprime / Désactive / Active l'historique d'autocomplétion (PSReadLine) - ne fonctionne que pour la session en cours
function Rm-History {
    Remove-Item -Path (Get-PSReadLineOption).HistorySavePath
}
function No-History {
    Set-PSReadLineOption -HistorySaveStyle SaveNothing
}
function Sv-History {
    Set-PSReadLineOption -HistorySaveStyle SaveHistory
}

# Recharger le profil
function Reload-Profile {
    . $PROFILE
    Write-Host "Profil rechargé!" -ForegroundColor Green
}

# ------------------------------------------
# Message de bienvenue
# ------------------------------------------
Write-Host "PowerShell $($PSVersionTable.PSVersion)"