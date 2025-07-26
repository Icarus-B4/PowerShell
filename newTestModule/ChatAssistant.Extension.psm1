# ChatAssistant.Extension.psm1
# Erweiterungsmodul für den PowerShell Chat-Assistenten

# Überprüfen, ob das Hauptmodul geladen ist
if (-not (Get-Module -Name ChatAssistant)) {
    Write-Warning "Das ChatAssistant-Modul ist nicht geladen. Bitte laden Sie es zuerst mit 'Import-Module ChatAssistant'."
    return
}

# Zusätzliche Konfigurationsoptionen
$script:ExtensionConfig = @{
    EnableVoice = $false
    VoiceRate = 0
    VoiceVolume = 100
    EnableLogging = $false
    LogPath = Join-Path -Path $HOME -ChildPath "ChatAssistant_Logs"
    CustomPrompts = @{}
    EnableTerminalCommands = $false
    EnableCanvasPreview = $false
    ArtifactsPath = Join-Path -Path $HOME -ChildPath "ChatAssistant_Artifacts"
}

# Funktion zum Speichern und Laden von benutzerdefinierten Prompts
function Set-ChatPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Prompt
    )

    $script:ExtensionConfig.CustomPrompts[$Name] = $Prompt
    Write-Host "Prompt '$Name' gespeichert." -ForegroundColor Green
}

# Funktion zum Abrufen gespeicherter Prompts
function Get-ChatPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Name
    )

    if ($Name) {
        if ($script:ExtensionConfig.CustomPrompts.ContainsKey($Name)) {
            return $script:ExtensionConfig.CustomPrompts[$Name]
        }
        else {
            Write-Warning "Prompt '$Name' nicht gefunden."
            return $null
        }
    }
    else {
        return $script:ExtensionConfig.CustomPrompts
    }
}

# Funktion zum Löschen gespeicherter Prompts
function Remove-ChatPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    if ($script:ExtensionConfig.CustomPrompts.ContainsKey($Name)) {
        $script:ExtensionConfig.CustomPrompts.Remove($Name)
        Write-Host "Prompt '$Name' gelöscht." -ForegroundColor Green
    }
    else {
        Write-Warning "Prompt '$Name' nicht gefunden."
    }
}

# Funktion zum Aktivieren/Deaktivieren der Sprachausgabe
function Set-ChatVoice {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$Enable,

        [Parameter()]
        [ValidateRange(-10, 10)]
        [int]$Rate,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$Volume
    )

    if ($PSBoundParameters.ContainsKey('Enable')) {
        $script:ExtensionConfig.EnableVoice = $Enable
    }

    if ($PSBoundParameters.ContainsKey('Rate')) {
        $script:ExtensionConfig.VoiceRate = $Rate
    }

    if ($PSBoundParameters.ContainsKey('Volume')) {
        $script:ExtensionConfig.VoiceVolume = $Volume
    }

    Write-Host "Sprachausgabe-Einstellungen aktualisiert." -ForegroundColor Green
    Write-Host "Aktiviert: $($script:ExtensionConfig.EnableVoice)" -ForegroundColor Cyan
    Write-Host "Geschwindigkeit: $($script:ExtensionConfig.VoiceRate)" -ForegroundColor Cyan
    Write-Host "Lautstärke: $($script:ExtensionConfig.VoiceVolume)%" -ForegroundColor Cyan
}

# Funktion zum Aktivieren/Deaktivieren der Protokollierung
function Set-ChatLogging {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$Enable,

        [Parameter()]
        [string]$LogPath
    )

    if ($PSBoundParameters.ContainsKey('Enable')) {
        $script:ExtensionConfig.EnableLogging = $Enable
    }

    if ($PSBoundParameters.ContainsKey('LogPath')) {
        $script:ExtensionConfig.LogPath = $LogPath
    }

    # Verzeichnis erstellen, falls es nicht existiert
    if ($script:ExtensionConfig.EnableLogging -and -not (Test-Path -Path $script:ExtensionConfig.LogPath)) {
        New-Item -Path $script:ExtensionConfig.LogPath -ItemType Directory -Force | Out-Null
    }

    Write-Host "Protokollierungs-Einstellungen aktualisiert." -ForegroundColor Green
    Write-Host "Aktiviert: $($script:ExtensionConfig.EnableLogging)" -ForegroundColor Cyan
    Write-Host "Pfad: $($script:ExtensionConfig.LogPath)" -ForegroundColor Cyan
}

# Funktion zum Ausführen von Terminalbefehlen
function Invoke-ChatTerminalCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    if (-not $script:ExtensionConfig.EnableTerminalCommands) {
        Write-Warning "Terminalbefehle sind deaktiviert. Aktivieren Sie sie mit 'Set-ChatTerminalCommands -Enable $true'."
        return "Terminalbefehle sind deaktiviert. Bitte aktivieren Sie diese Funktion zuerst."
    }

    try {
        # Befehl ausführen und Ausgabe erfassen
        $output = Invoke-Expression -Command $Command -ErrorAction Stop | Out-String
        return "Befehl erfolgreich ausgeführt:`r`n$output"
    }
    catch {
        return "Fehler bei der Ausführung des Befehls: $_"
    }
}

# Funktion zum Erstellen einer Canvas Preview für generierten Code
function New-ChatCanvasPreview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Code,

        [Parameter(Mandatory = $true)]
        [string]$Language,

        [Parameter()]
        [string]$FileName,

        [Parameter()]
        [switch]$OpenPreview
    )

    if (-not $script:ExtensionConfig.EnableCanvasPreview) {
        Write-Warning "Canvas Preview ist deaktiviert. Aktivieren Sie sie mit 'Set-ChatCanvasPreview -Enable $true'."
        return "Canvas Preview ist deaktiviert. Bitte aktivieren Sie diese Funktion zuerst."
    }

    # Dateinamen generieren, falls nicht angegeben
    if (-not $FileName) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $FileName = "code_${Language}_${timestamp}"
    }

    # Dateierweiterung basierend auf der Sprache hinzufügen
    $extension = switch ($Language.ToLower()) {
        "powershell" { ".ps1" }
        "javascript" { ".js" }
        "html" { ".html" }
        "css" { ".css" }
        "csharp" { ".cs" }
        "python" { ".py" }
        default { ".txt" }
    }

    $filePath = Join-Path -Path $script:ExtensionConfig.ArtifactsPath -ChildPath "$FileName$extension"

    try {
        # Verzeichnis erstellen, falls es nicht existiert
        if (-not (Test-Path -Path $script:ExtensionConfig.ArtifactsPath)) {
            New-Item -Path $script:ExtensionConfig.ArtifactsPath -ItemType Directory -Force | Out-Null
        }

        # Code in Datei speichern
        $Code | Out-File -FilePath $filePath -Encoding utf8

        # HTML-Vorschau erstellen für bestimmte Sprachen
        $previewPath = $null
        if ($Language.ToLower() -eq "html") {
            $previewPath = $filePath
        }
        elseif ($Language.ToLower() -in @("javascript", "css")) {
            $previewFileName = "${FileName}_preview.html"
            $previewPath = Join-Path -Path $script:ExtensionConfig.ArtifactsPath -ChildPath $previewFileName
            
            $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$FileName Preview</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        pre { background-color: #f5f5f5; padding: 10px; border-radius: 5px; overflow: auto; }
    </style>
"@

            if ($Language.ToLower() -eq "css") {
                $htmlContent += "<style>$Code</style>"
            }

            $htmlContent += @"
</head>
<body>
    <h1>$FileName Preview</h1>
    <pre><code>$($Code -replace '<', '&lt;' -replace '>', '&gt;')</code></pre>
"@

            if ($Language.ToLower() -eq "javascript") {
                $htmlContent += "<script>$Code</script>"
            }

            $htmlContent += @"
</body>
</html>
"@

            $htmlContent | Out-File -FilePath $previewPath -Encoding utf8
        }

        # Vorschau öffnen, falls gewünscht
        if ($OpenPreview -and $previewPath) {
            Start-Process $previewPath
        }

        return @{
            FilePath = $filePath
            PreviewPath = $previewPath
            Message = "Code wurde als '$filePath' gespeichert."
        }
    }
    catch {
        return "Fehler beim Erstellen der Canvas Preview: $_"
    }
}

# Erweiterte Chat-Funktion mit Sprachausgabe, Protokollierung, Terminalbefehlen und Canvas Preview
function Invoke-ChatAssistantExtended {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Prompt,

        [Parameter()]
        [switch]$UseVoice,

        [Parameter()]
        [switch]$ClearHistory,

        [Parameter()]
        [switch]$ExecuteCommands,

        [Parameter()]
        [switch]$CreatePreview
    )

    # Überprüfen, ob es sich um einen gespeicherten Prompt handelt
    if ($Prompt.StartsWith("#")) {
        $promptName = $Prompt.Substring(1).Trim()
        $savedPrompt = Get-ChatPrompt -Name $promptName

        if ($savedPrompt) {
            Write-Host "Verwende gespeicherten Prompt: $promptName" -ForegroundColor Cyan
            $Prompt = $savedPrompt
        }
    }

    # Anfrage an den Chat-Assistenten senden
    $response = Invoke-ChatAssistant -Prompt $Prompt -ClearHistory:$ClearHistory

    # Protokollierung, falls aktiviert
    if ($script:ExtensionConfig.EnableLogging) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path -Path $script:ExtensionConfig.LogPath -ChildPath "ChatLog_$(Get-Date -Format 'yyyy-MM-dd').txt"

        "[$timestamp] USER: $Prompt" | Out-File -FilePath $logFile -Append
        "[$timestamp] ASSISTANT: $response" | Out-File -FilePath $logFile -Append
        "" | Out-File -FilePath $logFile -Append
    }

    # Sprachausgabe, falls aktiviert
    if (($UseVoice -or $script:ExtensionConfig.EnableVoice) -and $response) {
        try {
            Add-Type -AssemblyName System.Speech
            $synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
            $synthesizer.Rate = $script:ExtensionConfig.VoiceRate
            $synthesizer.Volume = $script:ExtensionConfig.VoiceVolume
            $synthesizer.Speak($response)
        }
        catch {
            Write-Warning "Fehler bei der Sprachausgabe: $_"
        }
    }

    # Terminalbefehle ausführen, falls aktiviert und angefordert
    if (($ExecuteCommands -or $script:ExtensionConfig.EnableTerminalCommands) -and $response -match '```powershell\r?\n(.+?)\r?\n```') {
        $command = $matches[1].Trim()
        Write-Host "Gefundener PowerShell-Befehl:" -ForegroundColor Yellow
        Write-Host $command -ForegroundColor Cyan
        
        $executeConfirmation = Read-Host "Möchten Sie diesen Befehl ausführen? (j/n)"
        if ($executeConfirmation.ToLower() -eq 'j') {
            $commandResult = Invoke-ChatTerminalCommand -Command $command
            Write-Host $commandResult -ForegroundColor Green
        }
    }

    # Canvas Preview erstellen, falls aktiviert und angefordert
    if (($CreatePreview -or $script:ExtensionConfig.EnableCanvasPreview) -and $response -match '```(\w+)\r?\n(.+?)\r?\n```') {
        $language = $matches[1].Trim()
        $code = $matches[2].Trim()
        
        Write-Host "Gefundener Code ($language):" -ForegroundColor Yellow
        Write-Host $code.Substring(0, [Math]::Min(100, $code.Length)) -ForegroundColor Cyan
        if ($code.Length > 100) { Write-Host "..." -ForegroundColor Cyan }
        
        $previewConfirmation = Read-Host "Möchten Sie eine Canvas Preview erstellen? (j/n)"
        if ($previewConfirmation.ToLower() -eq 'j') {
            $fileName = Read-Host "Geben Sie einen Dateinamen ein (oder leer lassen für automatische Generierung)"
            $previewResult = New-ChatCanvasPreview -Code $code -Language $language -FileName $fileName -OpenPreview
            Write-Host $previewResult.Message -ForegroundColor Green
        }
    }

    return $response
}

# Funktion zum Exportieren des Chat-Verlaufs
function Export-ChatHistory {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path,

        [Parameter()]
        [ValidateSet("Text", "JSON", "HTML", "Markdown")]
        [string]$Format = "Text"
    )

    if (-not $Path) {
        $Path = Join-Path -Path $HOME -ChildPath "ChatHistory_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').$($Format.ToLower())"
    }

    # Chat-Verlauf abrufen
    $config = Get-ChatAssistantConfig
    $historyField = [Microsoft.PowerShell.Commands.ModuleInfo].Assembly.GetType("System.Management.Automation.PSModuleInfo").GetField("exportedCommands", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
    $commands = $historyField.GetValue((Get-Module ChatAssistant))
    $chatAssistantType = $commands["Invoke-ChatAssistant"].CommandInfo.ScriptBlock.Module.GetType()
    $historyField = $chatAssistantType.GetField("ChatAssistantConfig", [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::NonPublic)
    $fullConfig = $historyField.GetValue($null)
    $history = $fullConfig.History

    if (-not $history -or $history.Count -eq 0) {
        Write-Warning "Kein Chat-Verlauf vorhanden."
        return
    }

    # Verlauf im gewünschten Format exportieren
    switch ($Format) {
        "Text" {
            $output = ""
            foreach ($entry in $history) {
                $role = $entry.role.ToUpper()
                $content = $entry.content
                $output += "[$role]:\n$content\n\n"
            }
            $output | Out-File -FilePath $Path -Encoding utf8
        }
        "JSON" {
            $history | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding utf8
        }
        "HTML" {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chat-Verlauf</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        .message { margin-bottom: 20px; padding: 10px; border-radius: 5px; }
        .user { background-color: #e6f7ff; border-left: 4px solid #1890ff; }
        .assistant { background-color: #f6ffed; border-left: 4px solid #52c41a; }
        .role { font-weight: bold; margin-bottom: 5px; }
        .content { white-space: pre-wrap; }
    </style>
</head>
<body>
    <h1>Chat-Verlauf</h1>
    <div class="chat-history">
"@

            foreach ($entry in $history) {
                $role = $entry.role
                $content = $entry.content
                $html += @"
        <div class="message $role">
            <div class="role">$($role.ToUpper()):</div>
            <div class="content">$content</div>
        </div>
"@
            }

            $html += @"
    </div>
    <footer>
        <p>Exportiert am $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </footer>
</body>
</html>
"@

            $html | Out-File -FilePath $Path -Encoding utf8
        }
        "Markdown" {
            $markdown = "# Chat-Verlauf\n\nExportiert am $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")\n\n"

            foreach ($entry in $history) {
                $role = $entry.role.ToUpper()
                $content = $entry.content
                $markdown += "## $role\n\n$content\n\n"
            }

            $markdown | Out-File -FilePath $Path -Encoding utf8
        }
    }

    Write-Host "Chat-Verlauf wurde exportiert nach: $Path" -ForegroundColor Green
    return $Path
}

# Tab-Autovervollständigung für gespeicherte Prompts
$promptCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $promptNames = $script:ExtensionConfig.CustomPrompts.Keys | ForEach-Object { "#$_" }

    $promptNames | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Registriere die Tab-Autovervollständigung für gespeicherte Prompts
Register-ArgumentCompleter -CommandName Invoke-ChatAssistantExtended -ParameterName Prompt -ScriptBlock $promptCompleter

# Aliase für einfacheren Zugriff
New-Alias -Name chatx -Value Invoke-ChatAssistantExtended
New-Alias -Name chatp -Value Set-ChatPrompt
New-Alias -Name chatv -Value Set-ChatVoice

# Funktion zum Aktivieren/Deaktivieren der Terminalbefehle
function Set-ChatTerminalCommands {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$Enable
    )

    if ($PSBoundParameters.ContainsKey('Enable')) {
        $script:ExtensionConfig.EnableTerminalCommands = $Enable
    }

    Write-Host "Terminalbefehle-Einstellungen aktualisiert." -ForegroundColor Green
    Write-Host "Aktiviert: $($script:ExtensionConfig.EnableTerminalCommands)" -ForegroundColor Cyan
}

# Funktion zum Aktivieren/Deaktivieren der Canvas Preview
function Set-ChatCanvasPreview {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$Enable,

        [Parameter()]
        [string]$ArtifactsPath
    )

    if ($PSBoundParameters.ContainsKey('Enable')) {
        $script:ExtensionConfig.EnableCanvasPreview = $Enable
    }

    if ($PSBoundParameters.ContainsKey('ArtifactsPath')) {
        $script:ExtensionConfig.ArtifactsPath = $ArtifactsPath
    }

    # Verzeichnis erstellen, falls es nicht existiert
    if ($script:ExtensionConfig.EnableCanvasPreview -and -not (Test-Path -Path $script:ExtensionConfig.ArtifactsPath)) {
        New-Item -Path $script:ExtensionConfig.ArtifactsPath -ItemType Directory -Force | Out-Null
    }

    Write-Host "Canvas Preview-Einstellungen aktualisiert." -ForegroundColor Green
    Write-Host "Aktiviert: $($script:ExtensionConfig.EnableCanvasPreview)" -ForegroundColor Cyan
    Write-Host "Artifacts-Pfad: $($script:ExtensionConfig.ArtifactsPath)" -ForegroundColor Cyan
}

# Exportiere die Funktionen und Aliase
Export-ModuleMember -Function Set-ChatPrompt, Get-ChatPrompt, Remove-ChatPrompt, Set-ChatVoice, Set-ChatLogging, Invoke-ChatAssistantExtended, Export-ChatHistory, Set-ChatTerminalCommands, Set-ChatCanvasPreview, Invoke-ChatTerminalCommand, New-ChatCanvasPreview -Alias chatx, chatp, chatv
