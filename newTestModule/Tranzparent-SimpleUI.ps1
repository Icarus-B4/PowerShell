# SimpleUI.ps1
# Ein einfaches Skript zum Starten der Chat-Benutzeroberfläche

# Modul importieren (falls noch nicht geladen)
if (-not (Get-Module -Name ChatAssistant)) {
    if (Test-Path -Path "$PSScriptRoot\ChatAssistant.psm1") {
        Import-Module "$PSScriptRoot\ChatAssistant.psm1" -Force
    } else {
        Import-Module ChatAssistant -ErrorAction SilentlyContinue
        if (-not (Get-Module -Name ChatAssistant)) {
            Write-Host 'ChatAssistant-Modul nicht gefunden. Bitte installieren Sie es zuerst.' -ForegroundColor Red
            exit
        }
    }
}

# API-Key überprüfen und ggf. abfragen
try {
    $config = Get-ChatAssistantConfig -ErrorAction Stop
    if (-not $config.ApiKey) { throw }
} catch {
    # Zeige Optionen für API-Key-Eingabe
    Write-Host "Bitte wählen Sie eine Option:" -ForegroundColor Yellow
    Write-Host "1. OpenAI API-Key eingeben" -ForegroundColor Cyan
    Write-Host "2. Beispiel-API-Key verwenden (nur für Tests)" -ForegroundColor Cyan
    Write-Host "3. Abbrechen" -ForegroundColor Cyan
    
    $option = Read-Host "Bitte wählen Sie (1, 2 oder 3)"
    
    switch ($option) {
        "1" {
            $apiKey = Read-Host -Prompt "Bitte geben Sie Ihren OpenAI API-Key ein"
            if (-not $apiKey) {
                Write-Host "Kein API-Key angegeben. Beende Skript." -ForegroundColor Red
                exit
            }
            # Entferne Leerzeichen und Zeilenumbrüche
            $apiKey = $apiKey.Trim()
        }
        "2" {
            # Beispiel-API-Key für Tests
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
    
    # Korrigierte Funktion verwenden
    Set-ChatAssistantConfig -ApiKey $apiKey
    Write-Host "API-Key wurde gespeichert." -ForegroundColor Green
}

# Windows Forms laden
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# P/Invoke-Deklaration für GetWindowRect (um die Position des Konsolenfensters zu ermitteln)
# Korrigierte Version mit System.Drawing.Rectangle
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, ref System.Drawing.Rectangle lpRect);
}
"@ -ReferencedAssemblies "System.Drawing", "System.Drawing.Primitives"

# Globale Variablen für Drag-Funktionalität
$script:isDragging = $false
$script:dragStartPoint = New-Object System.Drawing.Point(0, 0)

# Hauptfenster erstellen
$form = New-Object System.Windows.Forms.Form
$form.Text = 'PowerShell Chat-Assistent'
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
$titleBarWidth = $form.ClientSize.Width
$titleBar.Size = New-Object System.Drawing.Size($titleBarWidth, 30)
$titleBar.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30) # Dunklerer Hintergrund für die Titelleiste
$form.Controls.Add($titleBar)

# Titel-Label hinzufügen
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = 'PowerShell Chat-Assistent'
$titleLabel.Location = New-Object System.Drawing.Point(10, 5)
$titleLabel.Size = New-Object System.Drawing.Size(300, 20)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleBar.Controls.Add($titleLabel)

# Schließen-Button hinzufügen
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = 'X'
$closeButton.Size = New-Object System.Drawing.Size(30, 30)
$closeButtonX = $form.ClientSize.Width - 30
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

# Chat-Bereich erstellen
$chatBox = New-Object System.Windows.Forms.RichTextBox
$chatBox.Location = New-Object System.Drawing.Point(10, 40) # Mehr Platz oben für den Titelbereich
$chatBoxWidth = $form.ClientSize.Width - 20
$chatBoxHeight = $form.ClientSize.Height - 100
$chatBox.Size = New-Object System.Drawing.Size($chatBoxWidth, $chatBoxHeight) # Dynamische Größe
$chatBox.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 15) # Dunkler Hintergrund für den Chat-Bereich
$chatBox.ForeColor = [System.Drawing.Color]::White
$chatBox.ReadOnly = $true
$chatBox.Multiline = $true
$chatBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None # Keine Ränder
$form.Controls.Add($chatBox)

# Eingabefeld erstellen
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBoxY = $form.ClientSize.Height - 50
$inputBox.Location = New-Object System.Drawing.Point(10, $inputBoxY) # Am unteren Rand
$inputBoxWidth = $form.ClientSize.Width - 120
$inputBox.Size = New-Object System.Drawing.Size($inputBoxWidth, 40) # Dynamische Größe
$inputBox.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10) # Dunklerer Hintergrund für das Eingabefeld
$inputBox.ForeColor = [System.Drawing.Color]::White
$inputBox.Multiline = $true
$inputBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None # Keine Ränder
$form.Controls.Add($inputBox)

# Senden-Button erstellen
$sendButton = New-Object System.Windows.Forms.Button
$sendButtonX = $form.ClientSize.Width - 100
$sendButtonY = $form.ClientSize.Height - 50
$sendButton.Location = New-Object System.Drawing.Point($sendButtonX, $sendButtonY) # Rechts neben dem Eingabefeld
$sendButton.Size = New-Object System.Drawing.Size(90, 40) # Angepasste Größe
$sendButton.Text = 'Senden'
$sendButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212) # Blauer Button wie im ersten Bild
$sendButton.ForeColor = [System.Drawing.Color]::White
$sendButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Flacher Button-Stil für modernes Aussehen
$sendButton.FlatAppearance.BorderSize = 0 # Keine Ränder für den Button
$form.Controls.Add($sendButton)

# Event-Handler für den Senden-Button
$sendButton.Add_Click({
    $message = $inputBox.Text.Trim()
    if ($message) {
        # Nachricht zum Chat-Bereich hinzufügen
        $chatBox.SelectionColor = [System.Drawing.Color]::LightGray
        $chatBox.AppendText("Sie: ${message}`r`n`r`n")
        $inputBox.Clear()

        # Antwort vom Assistenten abrufen
        try {
            $response = Invoke-ChatAssistant -Prompt $message -ErrorAction Stop
            $chatBox.SelectionColor = [System.Drawing.Color]::LightGreen
            $chatBox.AppendText("Assistent: ${response}`r`n`r`n")
        } catch {
            $chatBox.SelectionColor = [System.Drawing.Color]::Red
            $chatBox.AppendText("Fehler: $($_.Exception.Message)`r`n`r`n")
        }

        # Zum Ende des Chat-Bereichs scrollen
        $chatBox.SelectionStart = $chatBox.Text.Length
        $chatBox.ScrollToCaret()
    }
})

# Event-Handler für das Eingabefeld (Enter-Taste)
$inputBox.Add_KeyDown({
    if ($_.KeyCode -eq 'Enter' -and $_.Modifiers -eq 'None') {
        $sendButton.PerformClick()
        $_.SuppressKeyPress = $true
    }
})

# Willkommensnachricht anzeigen
$chatBox.SelectionColor = [System.Drawing.Color]::LightGreen
$chatBox.AppendText("Assistent: Hallo! Wie kann ich Ihnen heute helfen?`r`n`r`n")

# Event-Handler für Größenänderung des Formulars
$form.Add_Resize({
    # Titelleiste anpassen
    $titleBar.Width = $form.ClientSize.Width
    $closeButtonX = $form.ClientSize.Width - 30
    $closeButton.Location = New-Object System.Drawing.Point($closeButtonX, 0)

    # Chat-Bereich anpassen
    $chatBoxWidth = $form.ClientSize.Width - 20
    $chatBoxHeight = $form.ClientSize.Height - 100
    $chatBox.Width = $chatBoxWidth
    $chatBox.Height = $chatBoxHeight

    # Eingabefeld und Senden-Button anpassen
    $inputBoxY = $form.ClientSize.Height - 50
    $inputBoxWidth = $form.ClientSize.Width - 120
    $inputBox.Location = New-Object System.Drawing.Point(10, $inputBoxY)
    $inputBox.Width = $inputBoxWidth

    $sendButtonX = $form.ClientSize.Width - 100
    $sendButtonY = $form.ClientSize.Height - 50
    $sendButton.Location = New-Object System.Drawing.Point($sendButtonX, $sendButtonY)
})

# Formular anzeigen
$form.ShowDialog()
