# Install-ChatAssistant.ps1
# Installiert den PowerShell Chat-Assistenten

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ApiKey,
    
    [Parameter()]
    [switch]$Force
)

# Funktion zur Anzeige von farbigem Text
function Write-ColorText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter()]
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White
    )
    
    Write-Host $Text -ForegroundColor $ForegroundColor
}

# Banner anzeigen
Write-ColorText "===================================" -ForegroundColor Cyan
Write-ColorText "PowerShell Chat-Assistent Installer" -ForegroundColor Cyan
Write-ColorText "===================================" -ForegroundColor Cyan
Write-Host ""

# Überprüfen, ob PSReadLine installiert ist
Write-ColorText "Überprüfe PSReadLine-Modul..." -ForegroundColor Yellow
if (-not (Get-Module -Name PSReadLine -ListAvailable)) {
    Write-ColorText "PSReadLine-Modul nicht gefunden. Installation wird gestartet..." -ForegroundColor Yellow
    try {
        Install-Module PSReadLine -Scope CurrentUser -Force
        Write-ColorText "PSReadLine-Modul erfolgreich installiert." -ForegroundColor Green
    }
    catch {
        Write-ColorText "Fehler bei der Installation des PSReadLine-Moduls: $_" -ForegroundColor Red
        Write-ColorText "Bitte installieren Sie das Modul manuell mit 'Install-Module PSReadLine -Scope CurrentUser'" -ForegroundColor Yellow
    }
}
else {
    Write-ColorText "PSReadLine-Modul ist bereits installiert." -ForegroundColor Green
}

# Bestimmen des Modulpfads
$modulesPath = $env:PSModulePath -split ';' | Select-Object -First 1
$personalModulesPath = Join-Path -Path $HOME -ChildPath "Documents\PowerShell\Modules"

if (Test-Path -Path $personalModulesPath) {
    $modulesPath = $personalModulesPath
}

$chatAssistantPath = Join-Path -Path $modulesPath -ChildPath "ChatAssistant"
$moduleFilePath = Join-Path -Path $chatAssistantPath -ChildPath "ChatAssistant.psm1"
$manifestFilePath = Join-Path -Path $chatAssistantPath -ChildPath "ChatAssistant.psd1"

# Überprüfen, ob das Modul bereits installiert ist
if (Test-Path -Path $chatAssistantPath) {
    if (-not $Force) {
        Write-ColorText "Chat-Assistent ist bereits installiert in: $chatAssistantPath" -ForegroundColor Yellow
        $confirmation = Read-Host "Möchten Sie das Modul überschreiben? (j/n)"
        if ($confirmation -ne "j") {
            Write-ColorText "Installation abgebrochen." -ForegroundColor Red
            exit
        }
    }
    
    Write-ColorText "Bestehende Installation wird überschrieben..." -ForegroundColor Yellow
}
else {
    # Modulverzeichnis erstellen
    Write-ColorText "Erstelle Modulverzeichnis: $chatAssistantPath" -ForegroundColor Yellow
    New-Item -Path $chatAssistantPath -ItemType Directory -Force | Out-Null
}

# Kopieren der Moduldatei
Write-ColorText "Kopiere Moduldateien..." -ForegroundColor Yellow
Copy-Item -Path "$PSScriptRoot\ChatAssistant.psm1" -Destination $moduleFilePath -Force

# Erstellen des Modulmanifests
Write-ColorText "Erstelle Modulmanifest..." -ForegroundColor Yellow
New-ModuleManifest -Path $manifestFilePath `
    -RootModule "ChatAssistant.psm1" `
    -ModuleVersion "1.0.0" `
    -Author "PowerShell-Benutzer" `
    -Description "Ein Chat-Assistent mit Tab-Autovervollständigung für PowerShell" `
    -PowerShellVersion "5.1" `
    -FunctionsToExport @("Set-ChatAssistantConfig", "Get-ChatAssistantConfig", "Invoke-ChatAssistant", "Clear-ChatAssistantHistory") `
    -CmdletsToExport @() `
    -VariablesToExport @() `
    -AliasesToExport @("chat") `
    -RequiredModules @("PSReadLine")

# Kopieren der Dokumentation
if (Test-Path -Path "$PSScriptRoot\ChatAssistant.md") {
    Copy-Item -Path "$PSScriptRoot\ChatAssistant.md" -Destination "$chatAssistantPath\README.md" -Force
    Write-ColorText "Dokumentation kopiert." -ForegroundColor Green
}

# Kopieren des Demo-Skripts
if (Test-Path -Path "$PSScriptRoot\ChatAssistantDemo.ps1") {
    Copy-Item -Path "$PSScriptRoot\ChatAssistantDemo.ps1" -Destination "$chatAssistantPath\Demo.ps1" -Force
    Write-ColorText "Demo-Skript kopiert." -ForegroundColor Green
}

# API-Key konfigurieren, wenn angegeben
if ($ApiKey) {
    Write-ColorText "Konfiguriere API-Key..." -ForegroundColor Yellow
    Import-Module $manifestFilePath -Force
    Set-ChatAssistantConfig -ApiKey $ApiKey
    Write-ColorText "API-Key konfiguriert." -ForegroundColor Green
}

# Abschluss
Write-Host ""
Write-ColorText "Installation abgeschlossen!" -ForegroundColor Green
Write-ColorText "Der Chat-Assistent wurde installiert in: $chatAssistantPath" -ForegroundColor Green
Write-Host ""
Write-ColorText "Verwendung:" -ForegroundColor Cyan
Write-ColorText "1. Starten Sie eine neue PowerShell-Sitzung" -ForegroundColor White
Write-ColorText "2. Importieren Sie das Modul: Import-Module ChatAssistant" -ForegroundColor White
Write-ColorText "3. Wenn Sie noch keinen API-Key konfiguriert haben: Set-ChatAssistantConfig -ApiKey 'Ihr-API-Schlüssel'" -ForegroundColor White
Write-ColorText "4. Verwenden Sie den Assistenten: chat 'Ihre Frage'" -ForegroundColor White
Write-ColorText "5. Nutzen Sie die Tab-Taste für Befehlsvorschläge" -ForegroundColor White
Write-Host ""
Write-ColorText "Für weitere Informationen, lesen Sie die Dokumentation: $chatAssistantPath\README.md" -ForegroundColor Cyan