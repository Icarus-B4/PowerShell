# IntegrateModernUI.ps1
# Dieses Skript hilft bei der Integration der modernen Chat-Benutzeroberfläche in Ihr Projekt

# Überprüfen, ob die erforderlichen Dateien vorhanden sind
$simpleUIPath = "$PSScriptRoot\SimpleUI.ps1"
$modernUIPath = "$PSScriptRoot\ModernChatUI.ps1"
$modernUIAdvancedPath = "$PSScriptRoot\ModernChatUI-Advanced.ps1"
$chatAssistantPath = "$PSScriptRoot\ChatAssistant.psm1"

# Überprüfen, ob SimpleUI.ps1 vorhanden ist (da wir diese als Fallback verwenden)
if (-not (Test-Path -Path $simpleUIPath)) {
    Write-Host "SimpleUI.ps1 nicht gefunden. Bitte stellen Sie sicher, dass die Datei im selben Verzeichnis wie dieses Skript liegt." -ForegroundColor Red
    exit
}

# Überprüfen, ob ChatAssistant.psm1 vorhanden ist
if (-not (Test-Path -Path $chatAssistantPath)) {
    Write-Host "ChatAssistant.psm1 nicht gefunden. Bitte stellen Sie sicher, dass die Datei im selben Verzeichnis wie dieses Skript liegt." -ForegroundColor Red
    exit
}

# Benutzeroberfläche auswählen
Write-Host "=== Integration der modernen Chat-Benutzeroberfläche ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Welche Benutzeroberfläche möchten Sie verwenden?" -ForegroundColor Yellow
Write-Host "1. Standard-UI (ModernChatUI.ps1)" -ForegroundColor White
Write-Host "2. Erweiterte UI (ModernChatUI-Advanced.ps1)" -ForegroundColor White
Write-Host "3. Einfache UI (SimpleUI.ps1) - Empfohlen für bessere Kompatibilität" -ForegroundColor Green
Write-Host ""

$choice = Read-Host "Bitte wählen Sie (1, 2 oder 3)"

$selectedUI = ""
switch ($choice) {
    "1" { 
        if (Test-Path -Path $modernUIPath) {
            $selectedUI = $modernUIPath 
        } else {
            Write-Host "ModernChatUI.ps1 nicht gefunden. Verwende SimpleUI.ps1 als Fallback." -ForegroundColor Yellow
            $selectedUI = $simpleUIPath
        }
    }
    "2" { 
        if (Test-Path -Path $modernUIAdvancedPath) {
            $selectedUI = $modernUIAdvancedPath 
        } else {
            Write-Host "ModernChatUI-Advanced.ps1 nicht gefunden. Verwende SimpleUI.ps1 als Fallback." -ForegroundColor Yellow
            $selectedUI = $simpleUIPath
        }
    }
    "3" { 
        Write-Host "Einfache UI (SimpleUI.ps1) ausgewählt." -ForegroundColor Green
        $selectedUI = $simpleUIPath 
    }
    default {
        Write-Host "Ungültige Auswahl. Standardmäßig wird die einfache UI verwendet." -ForegroundColor Yellow
        $selectedUI = $simpleUIPath
    }
}

# Erstellen einer Verknüpfung auf dem Desktop
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutName = "PowerShell Chat-Assistent.lnk"
$shortcutPath = Join-Path -Path $desktopPath -ChildPath $shortcutName

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$selectedUI`""
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.IconLocation = "powershell.exe,0"
$Shortcut.Description = "Startet den PowerShell Chat-Assistenten mit moderner Benutzeroberfläche"
$Shortcut.Save()

Write-Host ""
Write-Host "Eine Verknüpfung wurde auf Ihrem Desktop erstellt: '$shortcutName'" -ForegroundColor Green
Write-Host "Sie können den Chat-Assistenten jetzt durch Doppelklick auf diese Verknüpfung starten." -ForegroundColor Green

# Erstellen einer Batch-Datei zum direkten Starten
$batchPath = "$PSScriptRoot\StartChatAssistant.bat"
$batchContent = @"
@echo off
powershell.exe -ExecutionPolicy Bypass -File "$selectedUI"
"@

$batchContent | Out-File -FilePath $batchPath -Encoding ASCII

Write-Host ""
Write-Host "Eine Batch-Datei wurde erstellt: 'StartChatAssistant.bat'" -ForegroundColor Green
Write-Host "Sie können den Chat-Assistenten auch durch Doppelklick auf diese Datei starten." -ForegroundColor Green

# Anleitung zur manuellen Integration
Write-Host ""
Write-Host "=== Manuelle Integration ===" -ForegroundColor Cyan
Write-Host "Wenn Sie die Benutzeroberfläche in Ihr eigenes Projekt integrieren möchten, fügen Sie folgende Zeile in Ihr Skript ein:" -ForegroundColor Yellow
Write-Host ""
Write-Host "& '$selectedUI'" -ForegroundColor White
Write-Host ""
Write-Host "Oder starten Sie die Benutzeroberfläche direkt aus der PowerShell mit:" -ForegroundColor Yellow
Write-Host ""
Write-Host "cd $PSScriptRoot" -ForegroundColor White
Write-Host "& '$selectedUI'" -ForegroundColor White
Write-Host ""

# Fragen, ob die Benutzeroberfläche sofort gestartet werden soll
Write-Host "Möchten Sie die Benutzeroberfläche jetzt starten? (j/n)" -ForegroundColor Yellow
$startNow = Read-Host

if ($startNow.ToLower() -eq "j") {
    Write-Host "Starting the user interface..." -ForegroundColor Green
    try {
        & $selectedUI
    }
    catch {
        Write-Host "Error starting the UI: $_" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "Sie können die Benutzeroberfläche später über die erstellte Verknüpfung oder Batch-Datei starten." -ForegroundColor Yellow
}
