# Test-ChatAssistant.ps1
# Testet die Funktionalität des Chat-Assistenten

[CmdletBinding()]
param()

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

# Funktion zum Ausführen eines Tests
function Test-Feature {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Test
    )
    
    Write-ColorText "Test: $Name" -ForegroundColor Cyan
    try {
        & $Test
        Write-ColorText "Ergebnis: Erfolgreich" -ForegroundColor Green
        return $true
    }
    catch {
        Write-ColorText "Ergebnis: Fehlgeschlagen - $_" -ForegroundColor Red
        return $false
    }
    finally {
        Write-Host ""
    }
}

# Banner anzeigen
Write-ColorText "===================================" -ForegroundColor Yellow
Write-ColorText "PowerShell Chat-Assistent Testskript" -ForegroundColor Yellow
Write-ColorText "===================================" -ForegroundColor Yellow
Write-Host ""

# Modul importieren
Write-ColorText "Importiere Chat-Assistent Modul..." -ForegroundColor Cyan
try {
    # Versuche, das Modul aus dem aktuellen Verzeichnis zu importieren
    if (Test-Path -Path "$PSScriptRoot\ChatAssistant.psm1") {
        Import-Module "$PSScriptRoot\ChatAssistant.psm1" -Force
        Write-ColorText "Modul aus lokalem Verzeichnis importiert." -ForegroundColor Green
    }
    else {
        # Versuche, das installierte Modul zu importieren
        Import-Module ChatAssistant -Force
        Write-ColorText "Installiertes Modul importiert." -ForegroundColor Green
    }
}
catch {
    Write-ColorText "Fehler beim Importieren des Moduls: $_" -ForegroundColor Red
    Write-ColorText "Bitte stellen Sie sicher, dass das Modul installiert ist oder sich im aktuellen Verzeichnis befindet." -ForegroundColor Yellow
    exit 1
}

# Testfälle
$testsPassed = 0
$totalTests = 0

# Test 1: Konfiguration
$totalTests++
if (Test-Feature -Name "Konfiguration" -Test {
    $config = Get-ChatAssistantConfig
    if (-not $config) { throw "Keine Konfiguration zurückgegeben" }
    
    # Testweise Konfiguration setzen
    Set-ChatAssistantConfig -Model "test-model" -MaxTokens 500 -Temperature 0.5
    
    # Überprüfen, ob die Änderungen übernommen wurden
    $newConfig = Get-ChatAssistantConfig
    if ($newConfig.Model -ne "test-model") { throw "Model wurde nicht korrekt gesetzt" }
    if ($newConfig.MaxTokens -ne 500) { throw "MaxTokens wurde nicht korrekt gesetzt" }
    if ($newConfig.Temperature -ne 0.5) { throw "Temperature wurde nicht korrekt gesetzt" }
    
    # Zurücksetzen auf Standardwerte
    Set-ChatAssistantConfig -Model "gpt-3.5-turbo" -MaxTokens 1000 -Temperature 0.7
}) {
    $testsPassed++
}

# Test 2: Chat-Verlauf
$totalTests++
if (Test-Feature -Name "Chat-Verlauf" -Test {
    # Verlauf löschen
    Clear-ChatAssistantHistory
    
    # Überprüfen, ob der Verlauf leer ist
    $config = Get-ChatAssistantConfig
    $historyField = $config.GetType().GetField("History", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
    $history = $historyField.GetValue($config)
    
    if ($history -and $history.Count -gt 0) { throw "Verlauf wurde nicht korrekt gelöscht" }
}) {
    $testsPassed++
}

# Test 3: Tab-Autovervollständigung
$totalTests++
if (Test-Feature -Name "Tab-Autovervollständigung" -Test {
    # Überprüfen, ob die ArgumentCompleter für Invoke-ChatAssistant registriert ist
    $completer = Get-ArgumentCompleter | Where-Object { $_.CommandName -eq "Invoke-ChatAssistant" -and $_.ParameterName -eq "Prompt" }
    
    if (-not $completer) { throw "Keine ArgumentCompleter für Invoke-ChatAssistant gefunden" }
}) {
    $testsPassed++
}

# Test 4: Alias
$totalTests++
if (Test-Feature -Name "Alias" -Test {
    # Überprüfen, ob der Alias 'chat' existiert und auf Invoke-ChatAssistant verweist
    $alias = Get-Alias -Name chat -ErrorAction SilentlyContinue
    
    if (-not $alias) { throw "Alias 'chat' nicht gefunden" }
    if ($alias.Definition -ne "Invoke-ChatAssistant") { throw "Alias 'chat' verweist nicht auf Invoke-ChatAssistant" }
}) {
    $testsPassed++
}

# Test 5: API-Anfrage (Mock)
$totalTests++
if (Test-Feature -Name "API-Anfrage (Mock)" -Test {
    # Original-Funktion sichern
    $originalInvokeRestMethod = Get-Item function:Invoke-RestMethod -ErrorAction SilentlyContinue
    
    # Mock für Invoke-RestMethod erstellen
    function Invoke-RestMethod {
        param($Uri, $Method, $Headers, $Body)
        
        # Einfache Überprüfung der Parameter
        if ($Uri -notlike "*api.openai.com*") { throw "Unerwartete API-URL: $Uri" }
        if ($Method -ne "Post") { throw "Unerwartete HTTP-Methode: $Method" }
        if (-not $Headers.Authorization) { throw "Keine Autorisierung in den Headers gefunden" }
        
        # Überprüfen des Request-Body
        $requestObj = $Body | ConvertFrom-Json
        if (-not $requestObj.model) { throw "Kein Modell im Request-Body gefunden" }
        if (-not $requestObj.messages) { throw "Keine Nachrichten im Request-Body gefunden" }
        
        # Mock-Antwort zurückgeben
        return @{
            choices = @(
                @{
                    message = @{
                        content = "Dies ist eine Test-Antwort vom Mock-API-Endpunkt."
                    }
                }
            )
        }
    }
    
    try {
        # API-Key für den Test setzen (wird nicht wirklich verwendet)
        Set-ChatAssistantConfig -ApiKey "test-api-key"
        
        # Test-Anfrage senden
        $response = Invoke-ChatAssistant -Prompt "Dies ist ein Test" -ErrorAction Stop
        
        # Überprüfen der Antwort
        if (-not $response) { throw "Keine Antwort erhalten" }
        if ($response -notlike "*Test-Antwort*") { throw "Unerwartete Antwort: $response" }
    }
    finally {
        # Original-Funktion wiederherstellen
        if ($originalInvokeRestMethod) {
            New-Item -Path function:Invoke-RestMethod -Value $originalInvokeRestMethod.ScriptBlock -Force | Out-Null
        }
        else {
            Remove-Item function:Invoke-RestMethod -Force -ErrorAction SilentlyContinue
        }
    }
}) {
    $testsPassed++
}

# Zusammenfassung anzeigen
Write-Host ""
Write-ColorText "Testzusammenfassung:" -ForegroundColor Yellow
Write-ColorText "$testsPassed von $totalTests Tests erfolgreich" -ForegroundColor $(if ($testsPassed -eq $totalTests) { "Green" } else { "Red" })

if ($testsPassed -eq $totalTests) {
    Write-ColorText "Alle Tests bestanden! Der Chat-Assistent funktioniert wie erwartet." -ForegroundColor Green
    exit 0
}
else {
    Write-ColorText "Einige Tests sind fehlgeschlagen. Bitte überprüfen Sie die Fehler und beheben Sie die Probleme." -ForegroundColor Red
    exit 1
}