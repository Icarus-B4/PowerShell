# PowerShell Chat-Assistent

Ein leistungsstarker Chat-Assistent mit Tab-Autovervollständigung für PowerShell. Dieses Projekt ermöglicht die einfache Interaktion mit KI-Sprachmodellen direkt aus der PowerShell-Konsole.

## Überblick

Dieses Projekt besteht aus mehreren Komponenten:

1. **ChatAssistant.psm1** - Das Hauptmodul, das die Kernfunktionalität des Chat-Assistenten bereitstellt.
2. **ChatAssistant.Extension.psm1** - Eine Erweiterung, die zusätzliche Funktionen wie gespeicherte Prompts, Sprachausgabe und Protokollierung hinzufügt.
3. **Setup-ChatAssistant.ps1** - Ein Skript zur automatisierten Installation und Konfiguration des Chat-Assistenten.
4. **ChatAssistantDemo.ps1** - Eine interaktive Demo des Chat-Assistenten.
5. **PowerShell-ChatAssistant-Examples.ps1** - Beispiele für die Verwendung des Chat-Assistenten mit PowerShell-Befehlen.
6. **Test-ChatAssistant.ps1** - Ein Testskript zur Überprüfung der Funktionalität des Chat-Assistenten.
7. **Example-Profile.ps1** - Ein Beispiel für die Integration des Chat-Assistenten in das PowerShell-Profil.

## Funktionen

### Kernfunktionen

- Einfache Interaktion mit KI-Sprachmodellen (z.B. GPT-3.5-Turbo)
- Tab-Autovervollständigung für häufig verwendete Befehle
- Verwaltung des Chat-Verlaufs
- Anpassbare Konfiguration

### Erweiterte Funktionen (mit der Erweiterung)

- Speichern und Verwalten von benutzerdefinierten Prompts
- Sprachausgabe für Antworten des Assistenten
- Protokollierung von Konversationen
- Exportieren des Chat-Verlaufs in verschiedenen Formaten

## Schnellstart

### Automatische Installation

Verwenden Sie das Setup-Skript für eine automatisierte Installation:

```powershell
# Einfache Installation
.\Setup-ChatAssistant.ps1

# Installation mit API-Key
.\Setup-ChatAssistant.ps1 -ApiKey "Ihr-API-Schlüssel"

# Installation mit Erweiterung und Hinzufügen zum PowerShell-Profil
.\Setup-ChatAssistant.ps1 -InstallExtension -AddToProfile
```

### Manuelle Installation

1. Stellen Sie sicher, dass das PSReadLine-Modul installiert ist:

```powershell
Install-Module PSReadLine -Scope CurrentUser
```

2. Kopieren Sie die Dateien in einen Ihrer PowerShell-Modulpfade:

```powershell
# Modulpfad anzeigen
$env:PSModulePath -split ";"

# Dateien kopieren
$modulePath = "$HOME\Documents\PowerShell\Modules\ChatAssistant"
New-Item -Path $modulePath -ItemType Directory -Force
Copy-Item -Path "ChatAssistant.psm1" -Destination "$modulePath\"
```

3. Importieren Sie das Modul und konfigurieren Sie Ihren API-Schlüssel:

```powershell
Import-Module ChatAssistant
Set-ChatAssistantConfig -ApiKey "Ihr-API-Schlüssel"
```

## Verwendung

### Grundlegende Verwendung

```powershell
# Einfache Anfrage
chat "Was ist PowerShell?"

# Oder mit dem vollständigen Befehl
Invoke-ChatAssistant "Erkläre mir PowerShell Pipelines"

# Chat-Verlauf löschen
Clear-ChatAssistantHistory
```

### Erweiterte Verwendung (mit der Erweiterung)

```powershell
# Prompt speichern
chatp "code-review" "Überprüfe den folgenden Code und schlage Verbesserungen vor:"

# Gespeicherten Prompt verwenden
chatx "#code-review Get-Process | Select-Object -First 5"

# Mit Sprachausgabe
chatx "Erkläre mir Variablen in PowerShell" -UseVoice

# Chat-Verlauf exportieren
Export-ChatHistory -Format HTML -Path "C:\Temp\ChatVerlauf.html"
```

## Beispiele und Demos

### Demo ausführen

```powershell
# Interaktive Demo
.\ChatAssistantDemo.ps1
```

### Beispiele ausführen

```powershell
# PowerShell-Beispiele
.\PowerShell-ChatAssistant-Examples.ps1
```

## Integration in das PowerShell-Profil

Fügen Sie den Chat-Assistenten zu Ihrem PowerShell-Profil hinzu, um ihn automatisch beim Start zu laden:

```powershell
# Profil bearbeiten
notepad $PROFILE

# Fügen Sie die folgenden Zeilen hinzu
if (Get-Module -Name ChatAssistant -ListAvailable) {
    Import-Module ChatAssistant
    Write-Host "Chat-Assistent geladen. Verwenden Sie 'chat' gefolgt von Ihrer Anfrage." -ForegroundColor Cyan
}
```

Eine vollständige Beispiel-Profildatei finden Sie in `Example-Profile.ps1`.

## Tests

Führen Sie das Testskript aus, um die Funktionalität des Chat-Assistenten zu überprüfen:

```powershell
.\Test-ChatAssistant.ps1
```

## Anforderungen

- PowerShell 5.1 oder höher
- PSReadLine-Modul
- Internetzugang für API-Anfragen
- API-Schlüssel für den Zugriff auf das Sprachmodell

## Dokumentation

Detaillierte Dokumentation finden Sie in den folgenden Dateien:

- `ChatAssistant.md` - Dokumentation für das Hauptmodul
- `ChatAssistant.Extension.md` - Dokumentation für die Erweiterung

## Hinweise

- Bewahren Sie Ihren API-Schlüssel sicher auf und teilen Sie ihn nicht mit anderen.
- Beachten Sie die Nutzungsbedingungen und Kosten des verwendeten API-Dienstes.
- Die Sprachausgabe erfordert das .NET Framework und funktioniert nur unter Windows.