# ChatAssistant.psm1
# Ein PowerShell-Modul für einen Chat-Assistenten mit Tab-Autovervollständigung

# Modul-Abhängigkeiten überprüfen und laden
if (-not (Get-Module -Name PSReadLine -ListAvailable)) {
    Write-Warning "PSReadLine-Modul nicht gefunden. Bitte installieren Sie es mit 'Install-Module PSReadLine -Scope CurrentUser'"
}
else {
    Import-Module PSReadLine
}

# Konfiguration für den Chat-Assistenten
$script:ChatAssistantConfig = @{
    ApiKey = $null
    Model = "gpt-3.5-turbo"
    MaxTokens = 1000
    Temperature = 0.7
    Endpoint = "https://api.openai.com/v1/chat/completions"
    History = @()
    MaxHistoryLength = 10
}

# Funktion zum Speichern der API-Konfiguration
function Set-ChatAssistantConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ApiKey,
        
        [Parameter()]
        [string]$Model,
        
        [Parameter()]
        [int]$MaxTokens,
        
        [Parameter()]
        [double]$Temperature,
        
        [Parameter()]
        [string]$Endpoint,
        
        [Parameter()]
        [int]$MaxHistoryLength
    )
    
    if ($ApiKey) { $script:ChatAssistantConfig.ApiKey = $ApiKey }
    if ($Model) { $script:ChatAssistantConfig.Model = $Model }
    if ($MaxTokens) { $script:ChatAssistantConfig.MaxTokens = $MaxTokens }
    if ($Temperature) { $script:ChatAssistantConfig.Temperature = $Temperature }
    if ($Endpoint) { $script:ChatAssistantConfig.Endpoint = $Endpoint }
    if ($MaxHistoryLength) { $script:ChatAssistantConfig.MaxHistoryLength = $MaxHistoryLength }
    
    Write-Host "Chat-Assistent Konfiguration aktualisiert." -ForegroundColor Green
}

# Funktion zum Abrufen der aktuellen Konfiguration
function Get-ChatAssistantConfig {
    [CmdletBinding()]
    param()
    
    # API-Key aus Sicherheitsgründen maskieren
    $configCopy = $script:ChatAssistantConfig.Clone()
    if ($configCopy.ApiKey) {
        $configCopy.ApiKey = $configCopy.ApiKey.Substring(0, 3) + "..." + $configCopy.ApiKey.Substring($configCopy.ApiKey.Length - 3)
    }
    
    return $configCopy
}

# Funktion zum Senden einer Anfrage an den Chat-Assistenten
function Invoke-ChatAssistant {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Prompt,
        
        [Parameter()]
        [switch]$ClearHistory
    )
    
    # Überprüfen, ob API-Key konfiguriert ist
    if (-not $script:ChatAssistantConfig.ApiKey) {
        Write-Error "API-Key nicht konfiguriert. Bitte verwenden Sie Set-ChatAssistantConfig -ApiKey 'IHR_API_KEY'"
        return
    }
    
    # Verlauf löschen, wenn gewünscht
    if ($ClearHistory) {
        $script:ChatAssistantConfig.History = @()
    }
    
    # Benutzeranfrage zum Verlauf hinzufügen
    $script:ChatAssistantConfig.History += @{role = "user"; content = $Prompt}
    
    # Verlauf auf maximale Länge begrenzen
    if ($script:ChatAssistantConfig.History.Count -gt $script:ChatAssistantConfig.MaxHistoryLength * 2) {
        $script:ChatAssistantConfig.History = $script:ChatAssistantConfig.History | Select-Object -Skip 2
    }
    
    # Anfrage an API vorbereiten
    # Sicherstellen, dass der API-Key korrekt formatiert ist
    $apiKey = $script:ChatAssistantConfig.ApiKey.Trim()
    
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $apiKey"
    }
    
    $body = @{
        model = $script:ChatAssistantConfig.Model
        messages = $script:ChatAssistantConfig.History
        max_tokens = $script:ChatAssistantConfig.MaxTokens
        temperature = $script:ChatAssistantConfig.Temperature
    } | ConvertTo-Json -Depth 10
    
    try {
        # Anfrage senden
        $response = Invoke-RestMethod -Uri $script:ChatAssistantConfig.Endpoint -Method Post -Headers $headers -Body $body
        
        # Antwort extrahieren
        $assistantResponse = $response.choices[0].message.content
        
        # Antwort zum Verlauf hinzufügen
        $script:ChatAssistantConfig.History += @{role = "assistant"; content = $assistantResponse}
        
        # Antwort zurückgeben
        return $assistantResponse
    }
    catch {
        Write-Error "Fehler bei der Anfrage an den Chat-Assistenten: $_"
    }
}

# Funktion zum Löschen des Chat-Verlaufs
function Clear-ChatAssistantHistory {
    [CmdletBinding()]
    param()
    
    $script:ChatAssistantConfig.History = @()
    Write-Host "Chat-Verlauf gelöscht." -ForegroundColor Green
}

# Tab-Autovervollständigung für Chat-Befehle einrichten
$chatCommandCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    $chatCommands = @(
        "Hilfe"
        "Erkläre"
        "Übersetze"
        "Fasse zusammen"
        "Korrigiere"
        "Optimiere"
        "Analysiere"
        "Vergleiche"
        "Erstelle"
        "Konvertiere"
    )
    
    $chatCommands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Registriere die Tab-Autovervollständigung für den Chat-Assistenten
Register-ArgumentCompleter -CommandName Invoke-ChatAssistant -ParameterName Prompt -ScriptBlock $chatCommandCompleter

# Alias für einfacheren Zugriff
New-Alias -Name chat -Value Invoke-ChatAssistant

# Exportiere die Funktionen und Aliase
Export-ModuleMember -Function Set-ChatAssistantConfig, Get-ChatAssistantConfig, Invoke-ChatAssistant, Clear-ChatAssistantHistory -Alias chat