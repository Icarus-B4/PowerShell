# ChatAssistant.psm1
# Ein PowerShell-Modul für einen Chat-Assistenten mit erweiterten Features (PowerShellGPT-Style)

# Modul-Abhängigkeiten überprüfen und laden
if (-not (Get-Module -Name PSReadLine -ListAvailable)) {
    Write-Warning "PSReadLine-Modul nicht gefunden. Bitte installieren Sie es mit 'Install-Module PSReadLine -Scope CurrentUser'"
}
else {
    Import-Module PSReadLine
}

# Lade Windows Forms für GUI-Features
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

# Lade System.Speech für TTS
try {
    Add-Type -AssemblyName System.Speech
    $script:TTSAvailable = $true
} catch {
    $script:TTSAvailable = $false
    Write-Warning "System.Speech nicht verfügbar. Text-to-Speech Features deaktiviert."
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
    EnableCommandExecution = $true
    SafeMode = $true
}

# Liste der sicheren PowerShell-Befehle
$script:SafeCommands = @(
    'Get-*', 'Show-*', 'Find-*', 'Search-*', 'Test-*', 'Measure-*',
    'ls', 'dir', 'pwd', 'whoami', 'hostname', 'date', 'cat', 'type',
    'Select-*', 'Where-*', 'Sort-*', 'Group-*', 'ForEach-*',
    'Out-*', 'Format-*', 'ConvertTo-*', 'ConvertFrom-*'
)

# Liste der gefährlichen Befehle (werden blockiert im SafeMode)
$script:DangerousCommands = @(
    'Remove-*', 'Delete-*', 'Clear-*', 'Stop-*', 'Kill-*', 'Restart-*',
    'Set-*', 'New-*', 'Add-*', 'Install-*', 'Uninstall-*', 'Update-*',
    'Invoke-Expression', 'Invoke-Command', 'Start-Process', 'rm', 'del',
    'format', 'diskpart', 'reg', 'netsh'
)

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

# Funktion zum Überprüfen, ob ein Befehl sicher ist
function Test-CommandSafety {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    if (-not $script:ChatAssistantConfig.SafeMode) {
        return $true
    }
    
    # Prüfe auf gefährliche Befehle
    foreach ($dangerousPattern in $script:DangerousCommands) {
        if ($Command -like $dangerousPattern) {
            return $false
        }
    }
    
    # Prüfe auf sichere Befehle
    foreach ($safePattern in $script:SafeCommands) {
        if ($Command -like $safePattern) {
            return $true
        }
    }
    
    # Standardmäßig unsicher, wenn nicht explizit als sicher markiert
    return $false
}

# Funktion zum Erkennen von PowerShell-Befehlen im Text
function Get-PowerShellCommands {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    $commands = @()
    
    # Erkenne direkte Befehle (ein Wort am Anfang der Zeile)
    if ($Text -match '^\s*([a-zA-Z0-9-_]+)\s*(.*)?$') {
        $commandName = $matches[1]
        $commandArgs = if ($matches[2]) { $matches[2].Trim() } else { "" }
        
        # Prüfe, ob es ein bekannter PowerShell-Befehl ist
        try {
            $cmdletInfo = Get-Command $commandName -ErrorAction SilentlyContinue
            if ($cmdletInfo) {
                $fullCommand = if ($commandArgs) {
                    "$commandName $commandArgs"
                } else {
                    $commandName
                }
                
                $commands += @{
                    Name = $commandName
                    Arguments = $commandArgs
                    FullCommand = $fullCommand
                    Type = $cmdletInfo.CommandType
                }
            }
        }
        catch {
            # Ignoriere Fehler bei der Befehlserkennung
        }
    }
    
    return $commands
}

# Funktion zum Ausführen eines PowerShell-Befehls
function Invoke-SafePowerShellCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    Write-Host "Führe Befehl aus: $Command" -ForegroundColor Cyan
    
    # Sicherheitsprüfung
    $commandName = ($Command -split '\s+')[0]
    if (-not (Test-CommandSafety -Command $commandName)) {
        if ($script:ChatAssistantConfig.SafeMode) {
            Write-Warning "Befehl '$commandName' ist im SafeMode nicht erlaubt. Verwenden Sie 'Set-ChatAssistantSafeMode -Disabled' um den SafeMode zu deaktivieren."
            return "Befehl wurde aus Sicherheitsgründen blockiert."
        }
        else {
            Write-Warning "Achtung: Dieser Befehl könnte gefährlich sein!"
        }
    }
    
    try {
        # Führe den Befehl aus und erfasse die Ausgabe
        $result = Invoke-Expression $Command 2>&1
        
        if ($result) {
            # Begrenze die Ausgabe auf 2000 Zeichen
            $output = $result | Out-String
            if ($output.Length -gt 2000) {
                $output = $output.Substring(0, 2000) + "\n... (Ausgabe gekürzt)"
            }
            return $output
        }
        else {
            return "Befehl erfolgreich ausgeführt (keine Ausgabe)."
        }
    }
    catch {
        $errorMessage = "Fehler bei der Ausführung: $($_.Exception.Message)"
        Write-Error $errorMessage
        return $errorMessage
    }
}

# Erweiterte Chat-Funktion mit Befehlsausführung
function Invoke-SmartChatAssistant {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Input,
        
        [Parameter()]
        [switch]$ClearHistory,
        
        [Parameter()]
        [switch]$ForceAI
    )
    
    # Prüfe, ob Befehlsausführung aktiviert ist und es sich um einen Befehl handelt
    if ($script:ChatAssistantConfig.EnableCommandExecution -and -not $ForceAI) {
        $detectedCommands = Get-PowerShellCommands -Text $Input
        
        if ($detectedCommands.Count -gt 0) {
            $command = $detectedCommands[0]
            $result = Invoke-SafePowerShellCommand -Command $command.FullCommand
            
            # Füge das Ergebnis zum Verlauf hinzu (für Kontext)
            $script:ChatAssistantConfig.History += @{role = "user"; content = "Befehl: $($command.FullCommand)"}
            $script:ChatAssistantConfig.History += @{role = "assistant"; content = "Ausgabe:\n$result"}
            
            return $result
        }
    }
    
    # Falls kein Befehl erkannt wurde oder ForceAI gesetzt ist, verwende den AI-Chat
    return Invoke-ChatAssistant -Prompt $Input -ClearHistory:$ClearHistory
}

# Funktion zum Ein-/Ausschalten des SafeMode
function Set-ChatAssistantSafeMode {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Enabled,
        
        [Parameter()]
        [switch]$Disabled
    )
    
    if ($Enabled) {
        $script:ChatAssistantConfig.SafeMode = $true
        Write-Host "SafeMode aktiviert. Nur sichere Befehle werden ausgeführt." -ForegroundColor Green
    }
    elseif ($Disabled) {
        $script:ChatAssistantConfig.SafeMode = $false
        Write-Host "SafeMode deaktiviert. ACHTUNG: Alle Befehle können ausgeführt werden!" -ForegroundColor Red
    }
    else {
        Write-Host "SafeMode ist aktuell: $($script:ChatAssistantConfig.SafeMode)" -ForegroundColor Yellow
    }
}

# Funktion zum Ein-/Ausschalten der Befehlsausführung
function Set-ChatAssistantCommandExecution {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Enabled,
        
        [Parameter()]
        [switch]$Disabled
    )
    
    if ($Enabled) {
        $script:ChatAssistantConfig.EnableCommandExecution = $true
        Write-Host "Befehlsausführung aktiviert." -ForegroundColor Green
    }
    elseif ($Disabled) {
        $script:ChatAssistantConfig.EnableCommandExecution = $false
        Write-Host "Befehlsausführung deaktiviert. Nur AI-Chat verfügbar." -ForegroundColor Yellow
    }
    else {
        Write-Host "Befehlsausführung ist aktuell: $($script:ChatAssistantConfig.EnableCommandExecution)" -ForegroundColor Yellow
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

# Aliase für einfacheren Zugriff
New-Alias -Name chat -Value Invoke-SmartChatAssistant
New-Alias -Name ai -Value Invoke-ChatAssistant
New-Alias -Name exec -Value Invoke-SafePowerShellCommand

# Exportiere die Funktionen und Aliase
Export-ModuleMember -Function Set-ChatAssistantConfig, Get-ChatAssistantConfig, Invoke-ChatAssistant, Clear-ChatAssistantHistory, `
                              Invoke-SmartChatAssistant, Invoke-SafePowerShellCommand, Test-CommandSafety, `
                              Set-ChatAssistantSafeMode, Set-ChatAssistantCommandExecution, Get-PowerShellCommands `
                    -Alias chat, ai, exec
