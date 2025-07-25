# PowerShell Chat-Assistent Erweiterung

Diese Erweiterung fügt dem PowerShell Chat-Assistenten zusätzliche Funktionen hinzu, wie gespeicherte Prompts, Sprachausgabe und Protokollierung.

## Funktionen

- Speichern und Verwalten von benutzerdefinierten Prompts
- Sprachausgabe für Antworten des Assistenten
- Protokollierung von Konversationen
- Exportieren des Chat-Verlaufs in verschiedenen Formaten

## Installation

1. Stellen Sie sicher, dass das Hauptmodul `ChatAssistant` bereits installiert ist.

2. Kopieren Sie die Datei `ChatAssistant.Extension.psm1` in einen Ihrer PowerShell-Modulpfade oder in dasselbe Verzeichnis wie das Hauptmodul.

3. Importieren Sie beide Module:

```powershell
Import-Module ChatAssistant
Import-Module ChatAssistant.Extension
```

## Verwendung

### Gespeicherte Prompts

Speichern Sie häufig verwendete Prompts für schnellen Zugriff:

```powershell
# Prompt speichern
Set-ChatPrompt -Name "code-review" -Prompt "Überprüfe den folgenden Code und schlage Verbesserungen vor:"

# Oder mit dem Alias
chatp "code-review" "Überprüfe den folgenden Code und schlage Verbesserungen vor:"
```

Verwenden Sie gespeicherte Prompts mit dem #-Präfix:

```powershell
# Gespeicherten Prompt verwenden
Invoke-ChatAssistantExtended -Prompt "#code-review Get-Process | Select-Object -First 5"

# Oder mit dem Alias
chatx "#code-review Get-Process | Select-Object -First 5"
```

Gespeicherte Prompts anzeigen und verwalten:

```powershell
# Alle gespeicherten Prompts anzeigen
Get-ChatPrompt

# Einen bestimmten Prompt anzeigen
Get-ChatPrompt -Name "code-review"

# Einen Prompt löschen
Remove-ChatPrompt -Name "code-review"
```

### Sprachausgabe

Aktivieren und konfigurieren Sie die Sprachausgabe:

```powershell
# Sprachausgabe aktivieren
Set-ChatVoice -Enable $true

# Sprachgeschwindigkeit und Lautstärke anpassen
Set-ChatVoice -Rate 1 -Volume 80

# Oder mit dem Alias
chatv -Enable $true -Rate 1 -Volume 80
```

Verwenden Sie die Sprachausgabe für eine einzelne Anfrage:

```powershell
Invoke-ChatAssistantExtended -Prompt "Erzähle mir einen kurzen Witz" -UseVoice
```

### Protokollierung

Aktivieren und konfigurieren Sie die Protokollierung:

```powershell
# Protokollierung aktivieren
Set-ChatLogging -Enable $true

# Protokollierungspfad anpassen
Set-ChatLogging -LogPath "C:\ChatLogs"
```

### Chat-Verlauf exportieren

Exportieren Sie den Chat-Verlauf in verschiedenen Formaten:

```powershell
# Als Textdatei exportieren (Standard)
Export-ChatHistory

# Als JSON exportieren
Export-ChatHistory -Format JSON

# Als HTML exportieren
Export-ChatHistory -Format HTML -Path "C:\Temp\ChatVerlauf.html"

# Als Markdown exportieren
Export-ChatHistory -Format Markdown
```

## Erweiterte Chat-Funktion

Die erweiterte Chat-Funktion `Invoke-ChatAssistantExtended` (Alias: `chatx`) kombiniert alle Funktionen:

```powershell
# Einfache Anfrage
chatx "Was ist PowerShell?"

# Gespeicherten Prompt verwenden
chatx "#code-review $code"

# Mit Sprachausgabe
chatx "Erkläre mir Variablen in PowerShell" -UseVoice

# Neuen Chat starten
chatx "Neues Thema: PowerShell Module" -ClearHistory
```

## Tab-Autovervollständigung

Die Erweiterung unterstützt Tab-Autovervollständigung für gespeicherte Prompts:

```powershell
# Drücken Sie Tab nach dem #-Zeichen
chatx "#[TAB]"
# Zeigt alle verfügbaren gespeicherten Prompts an
```

## Integration in das PowerShell-Profil

Fügen Sie die folgenden Zeilen zu Ihrem PowerShell-Profil hinzu, um die Erweiterung automatisch zu laden:

```powershell
# Chat-Assistent und Erweiterung laden
if (Get-Module -Name ChatAssistant -ListAvailable) {
    Import-Module ChatAssistant
    if (Get-Module -Name ChatAssistant.Extension -ListAvailable) {
        Import-Module ChatAssistant.Extension
        Write-Host "Chat-Assistent mit Erweiterungen geladen." -ForegroundColor Cyan
    }
    else {
        Write-Host "Chat-Assistent geladen (ohne Erweiterungen)." -ForegroundColor Cyan
    }
}
```

## Hinweise

- Die Sprachausgabe erfordert das .NET Framework und funktioniert nur unter Windows.
- Für die Protokollierung werden Schreibrechte im angegebenen Verzeichnis benötigt.
- Gespeicherte Prompts werden nur für die aktuelle PowerShell-Sitzung gespeichert. Für permanente Speicherung müssten Sie die Konfiguration in einer Datei speichern und beim Start laden.