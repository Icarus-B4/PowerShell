# Setup-ChatAssistant.ps1
# Automatisierte Installation und Konfiguration des Chat-Assistenten und seiner Erweiterung

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ApiKey,
    
    [Parameter()]
    [switch]$InstallExtension,
    
    [Parameter()]
    [switch]$AddToProfile,
    
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
Write-ColorText "PowerShell Chat-Assistent Setup" -ForegroundColor Cyan
Write-ColorText "===================================" -ForegroundColor Cyan
Write-Host ""

# Ueberpruefen, ob PSReadLine installiert ist
Write-ColorText "Ueberpruefe PSReadLine-Modul..." -ForegroundColor Yellow
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

# Ueberpruefen, ob das Modul bereits installiert ist
if (Test-Path -Path $chatAssistantPath) {
    if (-not $Force) {
        Write-ColorText "Chat-Assistent ist bereits installiert in: $chatAssistantPath" -ForegroundColor Yellow
        $confirmation = Read-Host "Moechten Sie das Modul ueberschreiben? (j/n)"
        if ($confirmation -ne "j") {
            Write-ColorText "Installation abgebrochen." -ForegroundColor Red
            exit
        }
    }
    
    Write-ColorText "Bestehende Installation wird überschrieben..." -ForegroundColor Yellow
}

# Modulverzeichnis erstellen
Write-ColorText "Erstelle Modulverzeichnis: $chatAssistantPath" -ForegroundColor Yellow
New-Item -Path $chatAssistantPath -ItemType Directory -Force | Out-Null

# Kopieren der Moduldateien
Write-ColorText "Kopiere Moduldateien..." -ForegroundColor Yellow

# Hauptmodul
Copy-Item -Path "$PSScriptRoot\ChatAssistant.psm1" -Destination "$chatAssistantPath\ChatAssistant.psm1" -Force

# Dokumentation
if (Test-Path -Path "$PSScriptRoot\ChatAssistant.md") {
    Copy-Item -Path "$PSScriptRoot\ChatAssistant.md" -Destination "$chatAssistantPath\README.md" -Force
}

# Demo-Skript
if (Test-Path -Path "$PSScriptRoot\ChatAssistantDemo.ps1") {
    Copy-Item -Path "$PSScriptRoot\ChatAssistantDemo.ps1" -Destination "$chatAssistantPath\Demo.ps1" -Force
}

# Erstellen des Modulmanifests
Write-ColorText "Erstelle Modulmanifest..." -ForegroundColor Yellow
New-ModuleManifest -Path "$chatAssistantPath\ChatAssistant.psd1" `
    -RootModule "ChatAssistant.psm1" `
    -ModuleVersion "1.0.0" `
    -Author "PowerShell-Benutzer" `
    -Description "Ein Chat-Assistent mit Tab-Autovervollstaendigung fuer PowerShell" `
    -PowerShellVersion "5.1" `
    -FunctionsToExport @("Set-ChatAssistantConfig", "Get-ChatAssistantConfig", "Invoke-ChatAssistant", "Clear-ChatAssistantHistory") `
    -CmdletsToExport @() `
    -VariablesToExport @() `
    -AliasesToExport @("chat") `
    -RequiredModules @("PSReadLine")

# Erweiterung installieren, falls gewuenscht
if ($InstallExtension) {
    Write-Host ""
    Write-ColorText "Installiere Chat-Assistent Erweiterung..." -ForegroundColor Yellow
    
    # Erweiterungsmodul
    if (Test-Path -Path "$PSScriptRoot\ChatAssistant.Extension.psm1") {
        Copy-Item -Path "$PSScriptRoot\ChatAssistant.Extension.psm1" -Destination "$chatAssistantPath\ChatAssistant.Extension.psm1" -Force
        Write-ColorText "Erweiterungsmodul kopiert." -ForegroundColor Green
    }
    else {
        Write-ColorText "Erweiterungsmodul nicht gefunden." -ForegroundColor Red
    }
    
    # Erweiterungsdokumentation
    if (Test-Path -Path "$PSScriptRoot\ChatAssistant.Extension.md") {
        Copy-Item -Path "$PSScriptRoot\ChatAssistant.Extension.md" -Destination "$chatAssistantPath\Extension.md" -Force
        Write-ColorText "Erweiterungsdokumentation kopiert." -ForegroundColor Green
    }
    
    # Erstellen des Erweiterungsmanifests
    Write-ColorText "Erstelle Erweiterungsmanifest..." -ForegroundColor Yellow
    New-ModuleManifest -Path "$chatAssistantPath\ChatAssistant.Extension.psd1" `
        -RootModule "ChatAssistant.Extension.psm1" `
        -ModuleVersion "1.0.0" `
        -Author "PowerShell-Benutzer" `
        -Description "Erweiterung fuer den PowerShell Chat-Assistenten" `
        -PowerShellVersion "5.1" `
        -FunctionsToExport @("Set-ChatPrompt", "Get-ChatPrompt", "Remove-ChatPrompt", "Set-ChatVoice", "Set-ChatLogging", "Invoke-ChatAssistantExtended", "Export-ChatHistory") `
        -CmdletsToExport @() `
        -VariablesToExport @() `
        -AliasesToExport @("chatx", "chatp", "chatv") `
        -RequiredModules @("ChatAssistant")
}

# Module laden und API-Key konfigurieren
Write-Host ""
Write-ColorText "Lade Module..." -ForegroundColor Yellow
Import-Module "$chatAssistantPath\ChatAssistant.psd1" -Force

if ($InstallExtension -and (Test-Path -Path "$chatAssistantPath\ChatAssistant.Extension.psd1")) {
    Import-Module "$chatAssistantPath\ChatAssistant.Extension.psd1" -Force
    Write-ColorText "Chat-Assistent und Erweiterung geladen." -ForegroundColor Green
}
else {
    Write-ColorText "Chat-Assistent geladen." -ForegroundColor Green
}

# API-Key konfigurieren, wenn angegeben
if ($ApiKey) {
    Write-ColorText "Konfiguriere API-Key..." -ForegroundColor Yellow
    Set-ChatAssistantConfig -ApiKey $ApiKey
    Write-ColorText "API-Key konfiguriert." -ForegroundColor Green
}
elseif (-not (Get-ChatAssistantConfig).ApiKey) {
    Write-Host ""
    Write-ColorText "Kein API-Key angegeben." -ForegroundColor Yellow
    $configureNow = Read-Host "Moechten Sie jetzt einen API-Key konfigurieren? (j/n)"
    
    if ($configureNow -eq "j") {
        Write-ColorText "Bitte geben Sie Ihren API-Key ein:" -ForegroundColor Yellow
        $apiKeyPlain = Read-Host
        Set-ChatAssistantConfig -ApiKey $apiKeyPlain
        Write-ColorText "API-Key konfiguriert." -ForegroundColor Green
    }
    else {
        Write-ColorText "Sie koennen den API-Key spaeter mit 'Set-ChatAssistantConfig -ApiKey 'Ihr-API-Schluessel'' konfigurieren." -ForegroundColor Yellow
    }
}

# Zum PowerShell-Profil hinzufügen, falls gewünscht
if ($AddToProfile) {
    Write-Host ""
    Write-ColorText "Fuege Module zum PowerShell-Profil hinzu..." -ForegroundColor Yellow
    
    # Ueberpruefen, ob das Profil existiert
    if (-not (Test-Path -Path $PROFILE)) {
        Write-ColorText "PowerShell-Profil existiert nicht. Erstelle neues Profil..." -ForegroundColor Yellow
        New-Item -Path $PROFILE -ItemType File -Force | Out-Null
    }
    
    # Profilinhalt vorbereiten
    $profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
    if (-not $profileContent) { $profileContent = "" }
    
    $moduleImport = @"

# Chat-Assistent laden
if (Get-Module -Name ChatAssistant -ListAvailable) {
    Import-Module ChatAssistant
    Write-Host "Chat-Assistent geladen. Verwenden Sie 'chat' gefolgt von Ihrer Anfrage." -ForegroundColor Cyan
"@
    
    if ($InstallExtension) {
        $moduleImport += @"
    
    # Chat-Assistent Erweiterung laden
    if (Get-Module -Name ChatAssistant.Extension -ListAvailable) {
        Import-Module ChatAssistant.Extension
        Write-Host "Chat-Assistent Erweiterung geladen. Verwenden Sie 'chatx' für erweiterte Funktionen." -ForegroundColor Cyan
    }
"@
    }
    
    $moduleImport += @"

    # Tastenkombination für den Chat-Assistenten (Alt+C)
    Set-PSReadLineKeyHandler -Chord Alt+C -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("chat ")
    }
}
"@
    
    # Überprüfen, ob der Code bereits im Profil vorhanden ist
    if ($profileContent -notlike "*Chat-Assistent laden*") {
        Add-Content -Path $PROFILE -Value $moduleImport
        Write-ColorText "Module wurden zum PowerShell-Profil hinzugefügt." -ForegroundColor Green
    }
    else {
        Write-ColorText "Module sind bereits im PowerShell-Profil vorhanden." -ForegroundColor Yellow
    }
}

# Abschluss
Write-Host ""
Write-ColorText "Installation abgeschlossen!" -ForegroundColor Green
Write-ColorText "Der Chat-Assistent wurde installiert in: $chatAssistantPath" -ForegroundColor Green

Write-Host ""
Write-ColorText "Verwendung:" -ForegroundColor Cyan
Write-ColorText "1. Verwenden Sie den Assistenten: chat 'Ihre Frage'" -ForegroundColor White
Write-ColorText "2. Nutzen Sie die Tab-Taste fuer Befehlsvorschlaege" -ForegroundColor White

if ($InstallExtension) {
    Write-ColorText "3. Fuer erweiterte Funktionen: chatx 'Ihre Frage'" -ForegroundColor White
    Write-ColorText "4. Speichern Sie Prompts mit: chatp 'Name' 'Prompt'" -ForegroundColor White
    Write-ColorText "5. Verwenden Sie gespeicherte Prompts mit: chatx '#Name'" -ForegroundColor White
}

Write-Host ""
Write-ColorText "Fuer weitere Informationen, lesen Sie die Dokumentation: $chatAssistantPath\README.md" -ForegroundColor Cyan

if ($InstallExtension) {
    Write-ColorText "Dokumentation zur Erweiterung: $chatAssistantPath\Extension.md" -ForegroundColor Cyan
}

Write-Host ""
Write-ColorText "Starten Sie eine neue PowerShell-Sitzung, um die Aenderungen zu uebernehmen." -ForegroundColor Yellow