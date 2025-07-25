# Setup-ChatAssistant-Autostart.ps1
# Dieses Skript richtet den automatischen Start des Chat-Assistenten für PowerShell Core (pwsh.exe) ein

[CmdletBinding()]
param (
    [switch]$Force
)

# Funktion zum Anzeigen farbiger Texte
function Write-ColorText {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [string]$Text,
        
        [Parameter(Position = 1)]
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White
    )
    
    Write-Host $Text -ForegroundColor $ForegroundColor
}

# Begrüßung anzeigen
Write-ColorText "Chat-Assistent Autostart-Konfiguration" -ForegroundColor Cyan
Write-ColorText "======================================" -ForegroundColor Cyan
Write-Host ""

# Prüfen, ob das ChatAssistant-Modul installiert ist
$modulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\ChatAssistant"
if (-not (Test-Path "$modulePath\ChatAssistant.psm1")) {
    Write-ColorText "Das ChatAssistant-Modul ist nicht installiert. Bitte führen Sie zuerst Setup-ChatAssistant-terminal.ps1 aus." -ForegroundColor Red
    exit 1
}

# Prüfen, ob die Tranzparent-SimpleUI.ps1 Datei existiert
if (-not (Test-Path "$modulePath\Tranzparent-SimpleUI.ps1")) {
    Write-ColorText "Kopiere Tranzparent-SimpleUI.ps1 in das Modulverzeichnis..." -ForegroundColor Yellow
    Copy-Item "$PSScriptRoot\Tranzparent-SimpleUI.ps1" "$modulePath\" -Force
}

# PowerShell-Profilverzeichnisse erstellen, falls sie nicht existieren
$profileDirs = @(
    [System.IO.Path]::GetDirectoryName($PROFILE.CurrentUserCurrentHost),
    [System.IO.Path]::GetDirectoryName($PROFILE.CurrentUserAllHosts),
    "$env:USERPROFILE\Documents\PowerShell"
)

foreach ($dir in $profileDirs) {
    if (-not (Test-Path $dir)) {
        Write-ColorText "Erstelle Verzeichnis: $dir" -ForegroundColor Yellow
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# Profil-Inhalt erstellen
$profileContent = @'
# PowerShell-Profil für Chat-Assistenten

# Importiere das ChatAssistant-Modul
Import-Module ChatAssistant -ErrorAction SilentlyContinue

# Funktion für den Willkommensbildschirm
function Show-ChatAssistantWelcome {
    Write-Host ""
    Write-Host "Willkommen beim PowerShell Chat-Assistenten!" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Verfügbare Funktionen:" -ForegroundColor Yellow
    Write-Host "  * chat <Ihre Frage>" -ForegroundColor Green
    Write-Host "    Stellen Sie eine Frage an den Chat-Assistenten"
    Write-Host ""
    Write-Host "  * Clear-ChatAssistantHistory" -ForegroundColor Green
    Write-Host "    Löscht den Chat-Verlauf"
    Write-Host ""
    Write-Host "Tab-Autovervollständigung:" -ForegroundColor Yellow
    Write-Host "  Drücken Sie die TAB-Taste nach 'chat ', um Vorschläge zu erhalten:" -ForegroundColor Green
    Write-Host "  - Hilfe" -ForegroundColor DarkGray
    Write-Host "  - Erkläre" -ForegroundColor DarkGray
    Write-Host "  - Übersetze" -ForegroundColor DarkGray
    Write-Host "  - Fasse zusammen" -ForegroundColor DarkGray
    Write-Host "  - Korrigiere" -ForegroundColor DarkGray
    Write-Host "  - Optimiere" -ForegroundColor DarkGray
    Write-Host "  - Analysiere" -ForegroundColor DarkGray
    Write-Host "  - Vergleiche" -ForegroundColor DarkGray
    Write-Host "  - Erstelle" -ForegroundColor DarkGray
    Write-Host "  - Konvertiere" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Grafische Benutzeroberfläche:" -ForegroundColor Yellow
    Write-Host "  * Start-ChatAssistantUI" -ForegroundColor Green
    Write-Host "    Startet die grafische Benutzeroberfläche des Chat-Assistenten"
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
}

# Funktion zum Starten der grafischen Benutzeroberfläche
function Start-ChatAssistantUI {
    $modulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\ChatAssistant"
    $uiScriptPath = "$modulePath\Tranzparent-SimpleUI.ps1"
    
    if (Test-Path $uiScriptPath) {
        & $uiScriptPath
    } else {
        Write-Host "Die UI-Skriptdatei wurde nicht gefunden: $uiScriptPath" -ForegroundColor Red
    }
}

# Zeige den Willkommensbildschirm beim Start an
Show-ChatAssistantWelcome

# Starte die grafische Benutzeroberfläche automatisch
# Auskommentiert, um sie nicht automatisch zu starten
# Start-ChatAssistantUI
'@

# Profildateien erstellen/aktualisieren
$profileFiles = @(
    "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
    "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
)

foreach ($profilePath in $profileFiles) {
    if ((Test-Path $profilePath) -and -not $Force) {
        $overwrite = Read-Host "Die Datei $profilePath existiert bereits. Ueberschreiben? (j/n)"
        if ($overwrite -ne "j") {
            Write-ColorText "Ueberspringe $profilePath" -ForegroundColor Yellow
            continue
        }
    }
    
    Write-ColorText "Erstelle/Aktualisiere Profil: $profilePath" -ForegroundColor Green
    Set-Content -Path $profilePath -Value $profileContent -Force
}

# Erstelle eine Verknüpfung für pwsh.exe mit dem Profil
$pwshPath = "c:\Users\ed\Webdesign\PowerShell\debug\pwsh.exe"
$shortcutPath = "$env:USERPROFILE\Desktop\PowerShell Chat-Assistent.lnk"

Write-ColorText "Erstelle Verknuepfung auf dem Desktop..." -ForegroundColor Yellow

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $pwshPath
$Shortcut.Description = "PowerShell mit Chat-Assistent"
$Shortcut.WorkingDirectory = "$env:USERPROFILE"
$Shortcut.Save()

Write-Host ""
Write-ColorText "Installation abgeschlossen!" -ForegroundColor Green
Write-Host ""
Write-ColorText "Sie koennen den PowerShell Chat-Assistenten jetzt ueber die Verknuepfung auf dem Desktop starten." -ForegroundColor Yellow
Write-ColorText "Der Chat-Assistent wird automatisch geladen und zeigt einen Willkommensbildschirm an." -ForegroundColor Yellow
Write-Host ""
Write-ColorText "Um die grafische Benutzeroberflaeche zu starten, geben Sie 'Start-ChatAssistantUI' ein." -ForegroundColor Cyan
Write-Host ""