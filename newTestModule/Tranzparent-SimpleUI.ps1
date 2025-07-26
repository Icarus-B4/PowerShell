# SimpleUI.ps1
# Ein einfaches Skript zum Starten der Chat-Benutzeroberfläche

# Module importieren - Erzwinge Neuladen
# Entferne alte Versionen
Remove-Module ChatAssistant -Force -ErrorAction SilentlyContinue

# Hauptmodul laden
if (Test-Path -Path "$PSScriptRoot\ChatAssistant.psm1") {
    Import-Module "$PSScriptRoot\ChatAssistant.psm1" -Force
    Write-Host "ChatAssistant-Modul geladen von: $PSScriptRoot\ChatAssistant.psm1" -ForegroundColor Green
} else {
    Write-Host 'ChatAssistant.psm1 nicht gefunden im aktuellen Verzeichnis.' -ForegroundColor Red
    exit
}

# Erweiterungsmodul laden
if (-not (Get-Module -Name ChatAssistant.Extension)) {
    if (Test-Path -Path "$PSScriptRoot\ChatAssistant.Extension.psm1") {
        Import-Module "$PSScriptRoot\ChatAssistant.Extension.psm1" -Force
    } else {
        Import-Module ChatAssistant.Extension -ErrorAction SilentlyContinue
        if (-not (Get-Module -Name ChatAssistant.Extension)) {
            Write-Host 'ChatAssistant.Extension-Modul nicht gefunden. Einige Funktionen werden nicht verfügbar sein.' -ForegroundColor Yellow
        }
    }
}

# Erweiterungsfunktionen aktivieren
if (Get-Module -Name ChatAssistant.Extension) {
    # Standardpfad für Artefakte festlegen
    $artifactsPath = Join-Path -Path $env:USERPROFILE -ChildPath "ChatAssistant_Artifacts"

    # Terminalbefehle und Canvas Preview aktivieren
    Set-ChatTerminalCommands -Enable $true
    Set-ChatCanvasPreview -Enable $true -ArtifactsPath $artifactsPath
}

# Pfad zur Konfigurationsdatei für den API-Schlüssel
$configFilePath = Join-Path -Path $env:USERPROFILE -ChildPath "ChatAssistant_ApiKey.txt"
$apiKey = $null
$keyJustEntered = $false # Hält fest, ob der Key gerade erst eingegeben wurde

# Versuchen, den API-Key aus der lokalen Datei zu laden
if (Test-Path $configFilePath) {
    $apiKey = Get-Content -Path $configFilePath | Out-String
    $apiKey = $apiKey.Trim()
}

# Wenn kein API-Key gefunden oder die Datei leer ist, den Benutzer fragen
if (-not $apiKey) {
    $keyJustEntered = $true
    Write-Host "Bitte wählen Sie eine Option:" -ForegroundColor Yellow
    Write-Host "1. OpenAI API-Key eingeben (wird gespeichert)" -ForegroundColor Cyan
    Write-Host "2. Beispiel-API-Key verwenden (nur für Tests, wird nicht gespeichert)" -ForegroundColor Cyan
    Write-Host "3. Abbrechen" -ForegroundColor Cyan

    $option = Read-Host "Bitte wählen Sie (1, 2 oder 3)"

    switch ($option) {
        "1" {
            $apiKey = Read-Host -Prompt "Bitte geben Sie Ihren OpenAI API-Key ein"
            if ($apiKey) {
                $apiKey = $apiKey.Trim()
                # Speichere den API-Key für zukünftige Sitzungen
                try {
                    Set-Content -Path $configFilePath -Value $apiKey -ErrorAction Stop
                    Write-Host "API-Key wurde in '$configFilePath' gespeichert." -ForegroundColor Green
                } catch {
                    Write-Host "Fehler beim Speichern des API-Keys: $($_.Exception.Message)" -ForegroundColor Red
                }
            } else {
                Write-Host "Kein API-Key angegeben. Beende Skript." -ForegroundColor Red
                exit
            }
        }
        "2" {
            $apiKey = "sk-example-api-key-for-testing-purposes-only"
        }
        "3" {
            Write-Host "Vorgang abgebrochen." -ForegroundColor Yellow
            exit
        }
        default {
            Write-Host "Ungültige Option. Beende Skript." -ForegroundColor Red
            exit
        }
    }
}

# Setze den API-Key für das Modul in der aktuellen Sitzung
if ($apiKey) {
    try {
        Set-ChatAssistantConfig -ApiKey $apiKey -ErrorAction Stop
        if ($keyJustEntered) {
            Write-Host "API-Key wurde für die aktuelle Sitzung festgelegt." -ForegroundColor Green
        }
    } catch {
        Write-Host "Fehler beim Festlegen des API-Keys für das Chat-Modul: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Es wurde kein API-Key festgelegt. Das Skript wird möglicherweise nicht wie erwartet funktionieren." -ForegroundColor Yellow
}

# Windows Forms laden
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# P/Invoke-Deklarationen für runde Ecken
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class RoundedWindow {
    [DllImport("gdi32.dll")]
    public static extern IntPtr CreateRoundRectRgn(int nLeftRect, int nTopRect, int nRightRect, int nBottomRect, int nWidthEllipse, int nHeightEllipse);

    [DllImport("user32.dll")]
    public static extern int SetWindowRgn(IntPtr hWnd, IntPtr hRgn, bool bRedraw);
}
"@

# Globale Variablen für Drag-Funktionalität
$script:isDragging = $false
$script:dragStartPoint = New-Object System.Drawing.Point(0, 0)

# Hauptfenster erstellen
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Omni PowerShell Chat-Assistent'
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = 'CenterScreen' # Zentrierte Positionierung
$form.BackColor = [System.Drawing.Color]::FromArgb(5, 5, 5) # Extrem dunkler Hintergrund für bessere Transparenz
$form.ForeColor = [System.Drawing.Color]::White
$form.Opacity = 0.85 # Erhöhte Transparenz
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None # Keine Fensterrahmen
$form.TopMost = $true # Fenster bleibt im Vordergrund
$form.ShowInTaskbar = $true # In der Taskleiste anzeigen

# Schriftart für das gesamte Formular festlegen
$defaultFont = New-Object System.Drawing.Font('Consolas', 10)
$form.Font = $defaultFont

# Titelleiste erstellen (zum Verschieben des Fensters)
$titleBar = New-Object System.Windows.Forms.Panel
$titleBar.Location = New-Object System.Drawing.Point(0, 0)
$titleBarWidth = [int]$form.ClientSize.Width
$titleBar.Size = New-Object System.Drawing.Size($titleBarWidth, 30)
$titleBar.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30) # Dunklerer Hintergrund für die Titelleiste
$form.Controls.Add($titleBar)

# Titel-Label hinzufügen
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = 'Omni PowerShell Chat-Assistent'
$titleLabel.Location = New-Object System.Drawing.Point(10, 5)
$titleLabel.Size = New-Object System.Drawing.Size(300, 20)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleBar.Controls.Add($titleLabel)

# Minimieren-Button hinzufügen
$minimizeButton = New-Object System.Windows.Forms.Button
$minimizeButton.Text = '_'
$minimizeButton.Size = New-Object System.Drawing.Size(30, 30)
$minimizeButtonX = [int]$form.ClientSize.Width - 60
$minimizeButton.Location = New-Object System.Drawing.Point($minimizeButtonX, 0)
$minimizeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$minimizeButton.FlatAppearance.BorderSize = 0
$minimizeButton.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$minimizeButton.ForeColor = [System.Drawing.Color]::White
$minimizeButton.Add_Click({ $form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized })
$titleBar.Controls.Add($minimizeButton)

# Schließen-Button hinzufügen
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = 'X'
$closeButton.Size = New-Object System.Drawing.Size(30, 30)
$closeButtonX = [int]$form.ClientSize.Width - 30
$closeButton.Location = New-Object System.Drawing.Point($closeButtonX, 0)
$closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.BackColor = [System.Drawing.Color]::FromArgb(192, 0, 0)
$closeButton.ForeColor = [System.Drawing.Color]::White
$closeButton.Add_Click({ $form.Close() })
$titleBar.Controls.Add($closeButton) # Wichtig: Button zur Titelleiste hinzufügen, nicht zum Formular

# Vereinfachte Drag-Funktionalität für die Titelleiste
$titleBar.Add_MouseDown({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:isDragging = $true
        $script:dragStartPoint = $e.Location
    }
})

$titleBar.Add_MouseMove({
    param($sender, $e)
    if ($script:isDragging) {
        $deltaX = $e.X - $script:dragStartPoint.X
        $deltaY = $e.Y - $script:dragStartPoint.Y
        $newX = $form.Location.X + $deltaX
        $newY = $form.Location.Y + $deltaY
        $form.Location = New-Object System.Drawing.Point($newX, $newY)
    }
})

$titleBar.Add_MouseUp({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:isDragging = $false
    }
})

# Button-Panel erstellen
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Location = New-Object System.Drawing.Point(10, 35)
$buttonPanel.Size = New-Object System.Drawing.Size(([int]$form.ClientSize.Width - 20), 40)
$form.Controls.Add($buttonPanel)

# Canvas Preview Button erstellen
$canvasButton = New-Object System.Windows.Forms.Button
$canvasButton.Location = New-Object System.Drawing.Point(0, 0)
$canvasButton.Size = New-Object System.Drawing.Size(90, 40)
$canvasButton.Text = 'Canvas'
$canvasButton.BackColor = [System.Drawing.Color]::FromArgb(255, 140, 0) # Orange für Canvas
$canvasButton.ForeColor = [System.Drawing.Color]::White
$canvasButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$canvasButton.FlatAppearance.BorderSize = 0
$buttonPanel.Controls.Add($canvasButton)

# Terminal Button erstellen
$terminalButton = New-Object System.Windows.Forms.Button
$terminalButton.Location = New-Object System.Drawing.Point(95, 0)
$terminalButton.Size = New-Object System.Drawing.Size(90, 40)
$terminalButton.Text = 'Terminal'
$terminalButton.BackColor = [System.Drawing.Color]::FromArgb(34, 139, 34) # Grün für Terminal
$terminalButton.ForeColor = [System.Drawing.Color]::White
$terminalButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$terminalButton.FlatAppearance.BorderSize = 0
$buttonPanel.Controls.Add($terminalButton)

# Chat-Bereich erstellen
$chatBox = New-Object System.Windows.Forms.RichTextBox
$chatBox.Location = New-Object System.Drawing.Point(10, 80) # Unter dem neuen Button-Panel
$chatBoxWidth = [int]$form.ClientSize.Width - 20
$chatBoxHeight = [int]$form.ClientSize.Height - 140 # Höhe angepasst
$chatBox.Size = New-Object System.Drawing.Size($chatBoxWidth, $chatBoxHeight)
$chatBox.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 15)
$chatBox.ForeColor = [System.Drawing.Color]::White
$chatBox.ReadOnly = $true
$chatBox.Multiline = $true
$chatBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$form.Controls.Add($chatBox)

# Eingabefeld erstellen
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBoxY = [int]$form.ClientSize.Height - 50
$inputBox.Location = New-Object System.Drawing.Point(10, $inputBoxY)
$inputBoxWidth = [int]$form.ClientSize.Width - 120
$inputBox.Size = New-Object System.Drawing.Size($inputBoxWidth, 40)
$inputBox.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)
$inputBox.ForeColor = [System.Drawing.Color]::White
$inputBox.Multiline = $true
$inputBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$form.Controls.Add($inputBox)

# Blinkender Cursor-Timer
$script:cursorVisible = $true
$cursorTimer = New-Object System.Windows.Forms.Timer
$cursorTimer.Interval = 500 # 500ms Intervall
$cursorTimer.Add_Tick({
    # Nur blinken wenn das Eingabefeld leer ist und den Fokus hat
    if ($inputBox.Text.Length -eq 0 -and $inputBox.Focused) {
        if ($script:cursorVisible) {
            $inputBox.Text = "|"
            $inputBox.ForeColor = [System.Drawing.Color]::Gray
            $script:cursorVisible = $false
        } else {
            $inputBox.Text = ""
            $script:cursorVisible = $true
        }
    }
})
$cursorTimer.Start()

# Senden-Button erstellen
$sendButton = New-Object System.Windows.Forms.Button
$sendButtonX = [int]$form.ClientSize.Width - 100
$sendButtonY = [int]$form.ClientSize.Height - 50
$sendButton.Location = New-Object System.Drawing.Point($sendButtonX, $sendButtonY)
$sendButton.Size = New-Object System.Drawing.Size(90, 40)
$sendButton.Text = 'Senden'
$sendButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$sendButton.ForeColor = [System.Drawing.Color]::White
$sendButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$sendButton.FlatAppearance.BorderSize = 0
$form.Controls.Add($sendButton)

# Globale Variable für letzten generierten Code
$script:lastGeneratedCode = $null
$script:lastCodeLanguage = $null

# Event-Handler für den Canvas Button
$canvasButton.Add_Click({
    # Prüfe, ob Code im Chat vorhanden ist
    $chatText = $chatBox.Text
    $codeMatches = [regex]::Matches($chatText, '```(\w+)\r?\n(.+?)\r?\n```', [System.Text.RegularExpressions.RegexOptions]::Singleline)

    if ($codeMatches.Count -gt 0) {
        # Verwende den letzten gefundenen Code-Block
        $lastMatch = $codeMatches[$codeMatches.Count - 1]
        $language = $lastMatch.Groups[1].Value.Trim()
        $code = $lastMatch.Groups[2].Value.Trim()

        $script:lastGeneratedCode = $code
        $script:lastCodeLanguage = $language

        try {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $fileName = "artifact_${language}_${timestamp}"

            $result = New-ChatCanvasPreview -Code $code -Language $language -FileName $fileName -OpenPreview

            $chatBox.SelectionColor = [System.Drawing.Color]::Orange
            $chatBox.AppendText("Canvas Preview erstellt: $($result.Message)`r`n`r`n")

            # Scroll to end
            $chatBox.SelectionStart = $chatBox.Text.Length
            $chatBox.ScrollToCaret()
        } catch {
            $chatBox.SelectionColor = [System.Drawing.Color]::Red
            $chatBox.AppendText("Fehler beim Erstellen der Canvas Preview: $($_.Exception.Message)`r`n`r`n")
        }
    } else {
        $chatBox.SelectionColor = [System.Drawing.Color]::Yellow
        $chatBox.AppendText("System: Kein Code-Block im Chat gefunden. Bitten Sie den Assistenten zuerst, Code zu generieren.`r`n`r`n")
        $chatBox.SelectionStart = $chatBox.Text.Length
        $chatBox.ScrollToCaret()
    }
})

# Event-Handler für den Terminal Button
$terminalButton.Add_Click({
    # Prüfe, ob PowerShell-Code im Chat vorhanden ist
    $chatText = $chatBox.Text
    $psMatches = [regex]::Matches($chatText, '```(?:powershell|ps1)\r?\n(.+?)\r?\n```', [System.Text.RegularExpressions.RegexOptions]::Singleline)

    if ($psMatches.Count -gt 0) {
        # Verwende den letzten PowerShell Code-Block
        $lastMatch = $psMatches[$psMatches.Count - 1]
        $command = $lastMatch.Groups[1].Value.Trim()

        $chatBox.SelectionColor = [System.Drawing.Color]::Yellow
        $chatBox.AppendText("System: Gefundener PowerShell-Befehl wird ausgeführt...`r`n")
        $chatBox.AppendText("$command`r`n`r`n")

        try {
            $result = Invoke-ChatTerminalCommand -Command $command
            $chatBox.SelectionColor = [System.Drawing.Color]::Green
            $chatBox.AppendText("Terminal-Ausgabe:`r`n$result`r`n`r`n")
        } catch {
            $chatBox.SelectionColor = [System.Drawing.Color]::Red
            $chatBox.AppendText("Terminal-Fehler: $($_.Exception.Message)`r`n`r`n")
        }

        # Scroll to end
        $chatBox.SelectionStart = $chatBox.Text.Length
        $chatBox.ScrollToCaret()
    } else {
        $chatBox.SelectionColor = [System.Drawing.Color]::Yellow
        $chatBox.AppendText("System: Kein PowerShell-Code im Chat gefunden. Bitten Sie den Assistenten, PowerShell-Code zu generieren.`r`n`r`n")
        $chatBox.SelectionStart = $chatBox.Text.Length
        $chatBox.ScrollToCaret()
    }
})

# Event-Handler für den Senden-Button
$sendButton.Add_Click({
    $message = $inputBox.Text.Trim()
    if ($message) {
        # Nachricht zum Chat-Bereich hinzufügen
        $chatBox.SelectionColor = [System.Drawing.Color]::LightGray
        $chatBox.AppendText("Sie: ${message}`r`n`r`n")
        $inputBox.Clear()

        # Intelligente Antwort vom Assistenten abrufen (PowerShellGPT-Style)
        try {
            # Prüfe, ob es sich um einen einfachen PowerShell-Befehl handelt
            if ($message -match '^\s*([a-zA-Z0-9-_]+)\s*(.*)?$') {
                $commandName = $matches[1]
                $commandArgs = if ($matches[2]) { $matches[2].Trim() } else { "" }

                # Prüfe, ob es ein bekannter PowerShell-Befehl ist
                $cmdletInfo = Get-Command $commandName -ErrorAction SilentlyContinue
                if ($cmdletInfo) {
                    # Es ist ein PowerShell-Befehl - führe ihn aus
                    $fullCommand = if ($commandArgs) { "$commandName $commandArgs" } else { $commandName }

                    try {
                        $result = Invoke-SafePowerShellCommand -Command $fullCommand -ErrorAction Stop
                        $chatBox.SelectionColor = [System.Drawing.Color]::Cyan
                        $chatBox.AppendText("Terminal: ${result}`r`n`r`n")
                    } catch {
                        $chatBox.SelectionColor = [System.Drawing.Color]::Red
                        $chatBox.AppendText("Terminal-Fehler: $($_.Exception.Message)`r`n`r`n")
                    }
                } else {
                    # Kein PowerShell-Befehl - verwende AI-Chat
                    $response = Invoke-ChatAssistant -Prompt $message -ErrorAction Stop
                    $chatBox.SelectionColor = [System.Drawing.Color]::LightGreen
                    $chatBox.AppendText("Assistent: ${response}`r`n`r`n")
                }
            } else {
                # Komplexere Eingabe - verwende AI-Chat
                $response = Invoke-ChatAssistant -Prompt $message -ErrorAction Stop
                $chatBox.SelectionColor = [System.Drawing.Color]::LightGreen
                $chatBox.AppendText("Assistent: ${response}`r`n`r`n")
            }
        } catch {
            $chatBox.SelectionColor = [System.Drawing.Color]::Red
            $chatBox.AppendText("Fehler: $($_.Exception.Message)`r`n`r`n")
        }

        # Zum Ende des Chat-Bereichs scrollen
        $chatBox.SelectionStart = $chatBox.Text.Length
        $chatBox.ScrollToCaret()
    }
})

# Event-Handler für das Eingabefeld (Enter-Taste und Textänderungen)
$inputBox.Add_KeyDown({
    if ($_.KeyCode -eq 'Enter' -and $_.Modifiers -eq 'None') {
        $sendButton.PerformClick()
        $_.SuppressKeyPress = $true
    }
})

# Event-Handler für Fokus-Änderungen
$inputBox.Add_GotFocus({
    # Cursor-Text entfernen wenn Fokus erhalten
    if ($inputBox.Text -eq "|") {
        $inputBox.Text = ""
        $inputBox.ForeColor = [System.Drawing.Color]::White
    }
})

$inputBox.Add_LostFocus({
    # Cursor wieder aktivieren wenn kein Text vorhanden
    if ($inputBox.Text.Length -eq 0) {
        $script:cursorVisible = $true
    }
})

# Event-Handler für Textänderungen
$inputBox.Add_TextChanged({
    # Cursor-Timer stoppen wenn der Benutzer tippt
    if ($inputBox.Text.Length -gt 0 -and $inputBox.Text -ne "|") {
        $cursorTimer.Stop()
        $inputBox.ForeColor = [System.Drawing.Color]::White
        $script:cursorVisible = $false
    }
    elseif ($inputBox.Text.Length -eq 0) {
        # Cursor-Timer wieder starten wenn leer
        $script:cursorVisible = $true
        $cursorTimer.Start()
    }
})

# Event-Handler für Tastatur-Eingaben
$inputBox.Add_KeyPress({
    # Bei jeder Tasteneingabe Cursor entfernen
    if ($inputBox.Text -eq "|") {
        $inputBox.Text = ""
        $inputBox.ForeColor = [System.Drawing.Color]::White
        $cursorTimer.Stop()
        $script:cursorVisible = $false
    }
})

# Willkommensnachricht anzeigen
$chatBox.SelectionColor = [System.Drawing.Color]::LightGreen
$chatBox.AppendText("Assistent: Hallo! Wie kann ich Ihnen heute helfen?`r`n`r`n")

# Event-Handler für Größenänderung des Formulars
$form.Add_Resize({
    # Titelleiste anpassen
    $titleBar.Width = [int]$form.ClientSize.Width
    $closeButton.Location = New-Object System.Drawing.Point(([int]$form.ClientSize.Width - 30), 0)

    # Button-Panel anpassen
    $buttonPanel.Width = ([int]$form.ClientSize.Width - 20)

    # Chat-Bereich anpassen
    $chatBox.Width = ([int]$form.ClientSize.Width - 20)
    $chatBox.Height = ([int]$form.ClientSize.Height - 140)

    # Eingabefeld und Senden-Button anpassen
    $inputBox.Location = New-Object System.Drawing.Point(10, ([int]$form.ClientSize.Height - 50))
    $inputBox.Width = ([int]$form.ClientSize.Width - 120)

    $sendButton.Location = New-Object System.Drawing.Point(([int]$form.ClientSize.Width - 100), ([int]$form.ClientSize.Height - 50))
})

# Runde Ecken anwenden
$form.Add_Shown({
    # Runde Ecken für das Hauptfenster erstellen
    $roundedRegion = [RoundedWindow]::CreateRoundRectRgn(0, 0, $form.Width, $form.Height, 20, 20)
    [RoundedWindow]::SetWindowRgn($form.Handle, $roundedRegion, $true)

    # Fokus auf das Eingabefeld setzen
    $inputBox.Focus()
})

# Event-Handler für Größenänderung des Formulars - mit runden Ecken
$form.Add_Resize({
    # Titelleiste anpassen
    $titleBar.Width = [int]$form.ClientSize.Width
    $minimizeButton.Location = New-Object System.Drawing.Point(([int]$form.ClientSize.Width - 60), 0)
    $closeButton.Location = New-Object System.Drawing.Point(([int]$form.ClientSize.Width - 30), 0)

    # Button-Panel anpassen
    $buttonPanel.Width = ([int]$form.ClientSize.Width - 20)

    # Chat-Bereich anpassen
    $chatBox.Width = ([int]$form.ClientSize.Width - 20)
    $chatBox.Height = ([int]$form.ClientSize.Height - 140)

    # Eingabefeld und Senden-Button anpassen
    $inputBox.Location = New-Object System.Drawing.Point(10, ([int]$form.ClientSize.Height - 50))
    $inputBox.Width = ([int]$form.ClientSize.Width - 120)

    $sendButton.Location = New-Object System.Drawing.Point(([int]$form.ClientSize.Width - 100), ([int]$form.ClientSize.Height - 50))

    # Runde Ecken nach Größenänderung neu anwenden
    $roundedRegion = [RoundedWindow]::CreateRoundRectRgn(0, 0, $form.Width, $form.Height, 20, 20)
    [RoundedWindow]::SetWindowRgn($form.Handle, $roundedRegion, $true)
})

# Formular anzeigen
$form.ShowDialog()
