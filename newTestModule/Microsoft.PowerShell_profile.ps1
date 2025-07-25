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