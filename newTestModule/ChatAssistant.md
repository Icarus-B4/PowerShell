# PowerShell Chat-Assistent

Dieses PowerShell-Modul implementiert einen Chat-Assistenten mit Tab-Autovervollständigung für PowerShell. Es ermöglicht die einfache Interaktion mit einem KI-Sprachmodell direkt aus der PowerShell-Konsole.

## Funktionen

- Einfache Interaktion mit KI-Sprachmodellen (z.B. GPT-3.5-Turbo)
- Tab-Autovervollständigung für häufig verwendete Befehle
- Verwaltung des Chat-Verlaufs
- Anpassbare Konfiguration

## Installation

1. Stellen Sie sicher, dass das PSReadLine-Modul installiert ist:

```powershell
Install-Module PSReadLine -Scope CurrentUser
```

2. Kopieren Sie die Datei `ChatAssistant.psm1` in einen Ihrer PowerShell-Modulpfade.

3. Importieren Sie das Modul:

```powershell
Import-Module ChatAssistant
```

4. Konfigurieren Sie Ihren API-Schlüssel:

```powershell
Set-ChatAssistantConfig -ApiKey "Ihr-API-Schlüssel"
```

## Verwendung

### Konfiguration

Konfigurieren Sie den Chat-Assistenten mit Ihren bevorzugten Einstellungen:

```powershell
Set-ChatAssistantConfig -ApiKey "Ihr-API-Schlüssel" -Model "gpt-3.5-turbo" -MaxTokens 1000 -Temperature 0.7
```

Zeigen Sie die aktuelle Konfiguration an:

```powershell
Get-ChatAssistantConfig
```

### Chat-Interaktion

Stellen Sie eine Frage an den Assistenten:

```powershell
Invoke-ChatAssistant "Wie funktioniert PowerShell Remoting?"
```

Oder verwenden Sie den Alias `chat`:

```powershell
chat "Erkläre mir PowerShell Pipelines"
```

### Tab-Autovervollständigung

Drücken Sie die Tab-Taste nach dem Eingeben eines Teils eines Befehls, um Vorschläge zu erhalten:

```powershell
chat "Erk[TAB]"
# Vervollständigt zu: chat "Erkläre"
```

Verfügbare Befehle für die Autovervollständigung:
- Hilfe
- Erkläre
- Übersetze
- Fasse zusammen
- Korrigiere
- Optimiere
- Analysiere
- Vergleiche
- Erstelle
- Konvertiere

### Chat-Verlauf

Löschen Sie den Chat-Verlauf:

```powershell
Clear-ChatAssistantHistory
```

Oder starten Sie eine neue Konversation bei einer Anfrage:

```powershell
Invoke-ChatAssistant "Neues Thema: PowerShell Module" -ClearHistory
```

## Anpassung

Sie können die Liste der Befehle für die Tab-Autovervollständigung anpassen, indem Sie das Array `$chatCommands` in der Datei `ChatAssistant.psm1` bearbeiten.

## Anforderungen

- PowerShell 5.1 oder höher
- PSReadLine-Modul
- Internetzugang für API-Anfragen
- API-Schlüssel für den Zugriff auf das Sprachmodell

## Hinweise

- Bewahren Sie Ihren API-Schlüssel sicher auf und teilen Sie ihn nicht mit anderen.
- Beachten Sie die Nutzungsbedingungen und Kosten des verwendeten API-Dienstes.