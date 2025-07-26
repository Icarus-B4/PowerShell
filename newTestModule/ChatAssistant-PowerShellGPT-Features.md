# ChatAssistant - PowerShellGPT-ähnliche Features

## Übersicht

Das ChatAssistant-Modul wurde erweitert um Features, die PowerShellGPT ähneln. Es kann nun sowohl PowerShell-Befehle ausführen als auch AI-Chat bereitstellen.

## Neue Features

### 1. Intelligente Befehlserkennung
Der Assistent erkennt automatisch PowerShell-Befehle und führt sie aus, anstatt zu sagen "Ich kann keine Befehle ausführen".

```powershell
# Beispiele:
chat "ls"           # Führt ls aus
chat "Get-Process"  # Führt Get-Process aus
chat "pwd"          # Zeigt aktuelles Verzeichnis
```

### 2. SafeMode für Sicherheit
Standardmäßig aktiviert - blockiert gefährliche Befehle:

```powershell
# SafeMode Status prüfen/ändern
Set-ChatAssistantSafeMode           # Status anzeigen
Set-ChatAssistantSafeMode -Enabled  # Aktivieren
Set-ChatAssistantSafeMode -Disabled # Deaktivieren (Vorsicht!)
```

### 3. Sichere vs. Gefährliche Befehle

**Sichere Befehle (erlaubt im SafeMode):**
- `Get-*`, `Show-*`, `Find-*`, `Search-*`, `Test-*`, `Measure-*`
- `ls`, `dir`, `pwd`, `whoami`, `hostname`, `date`, `cat`, `type`
- `Select-*`, `Where-*`, `Sort-*`, `Group-*`, `ForEach-*`
- `Out-*`, `Format-*`, `ConvertTo-*`, `ConvertFrom-*`

**Gefährliche Befehle (blockiert im SafeMode):**
- `Remove-*`, `Delete-*`, `Clear-*`, `Stop-*`, `Kill-*`, `Restart-*`
- `Set-*`, `New-*`, `Add-*`, `Install-*`, `Uninstall-*`, `Update-*`
- `rm`, `del`, `format`, `diskpart`, `reg`, `netsh`

### 4. Neue Aliase und Funktionen

```powershell
# Hauptfunktionen
chat "Befehl oder Frage"      # Intelligenter Chat (Befehl oder AI)
ai "Nur AI-Frage"             # Nur AI-Chat erzwingen
exec "PowerShell-Befehl"      # Direkter Befehl (mit Sicherheitsprüfung)

# Konfiguration
Set-ChatAssistantCommandExecution -Enabled   # Befehlsausführung ein
Set-ChatAssistantCommandExecution -Disabled  # Befehlsausführung aus

# Beispiel-Verwendung
chat "ls"                     # Führt ls aus
chat "Erkläre mir PowerShell" # AI-Chat
ai "Was ist PowerShell?"      # Erzwinge AI-Chat
exec "Get-Service"            # Direkter Befehl
```

### 5. Erweiterte Sicherheitsfeatures

- **Ausgabe-Begrenzung**: Befehlsausgaben werden auf 2000 Zeichen begrenzt
- **Fehlerbehandlung**: Sichere Ausführung mit Fehlerabfang
- **Befehlsvalidierung**: Prüfung ob Befehl existiert vor Ausführung
- **Kontext-Speicherung**: Befehlsergebnisse werden im Chat-Verlauf gespeichert

### 6. Erweiterte Konfiguration

```powershell
# Basis-Konfiguration (wie vorher)
Set-ChatAssistantConfig -ApiKey "sk-..." -Model "gpt-4"

# Neue Konfigurationsoptionen
$config = Get-ChatAssistantConfig
$config.EnableCommandExecution  # true/false
$config.SafeMode                # true/false
```

## Verwendungsbeispiele

### Szenario 1: Systemadministration
```powershell
chat "Get-Service | Where-Object Status -eq 'Running'"
# Führt den Befehl aus und zeigt laufende Services

chat "Erkläre mir die Ausgabe"
# AI erklärt die Service-Liste
```

### Szenario 2: Dateisystem-Navigation
```powershell
chat "ls"              # Zeigt Dateien
chat "pwd"             # Zeigt Pfad
chat "Get-ChildItem *.ps1"  # Zeigt PowerShell-Dateien
```

### Szenario 3: Sichere Nutzung
```powershell
# SafeMode ist standardmäßig aktiv
chat "Remove-Item test.txt"  # Wird blockiert
# Ausgabe: "Befehl 'Remove-Item' ist im SafeMode nicht erlaubt..."

# Falls wirklich nötig:
Set-ChatAssistantSafeMode -Disabled
chat "Remove-Item test.txt"  # Würde jetzt funktionieren (mit Warnung)
Set-ChatAssistantSafeMode -Enabled  # Sicherheit wieder aktivieren
```

## Installation und Setup

```powershell
# Modul laden
Import-Module .\ChatAssistant.psm1

# API-Key konfigurieren
Set-ChatAssistantConfig -ApiKey "your-api-key-here"

# Test
chat "pwd"          # Sollte aktuelles Verzeichnis zeigen
chat "Hallo Welt"   # Sollte AI-Antwort geben
```

## Technische Details

### Befehlserkennung
- Regex-basierte Erkennung: `^\\s*([a-zA-Z0-9-_]+)\\s*(.*)?$`
- Validierung über `Get-Command`
- Unterstützung für Argumente

### Sicherheitsarchitektur
- Zwei-stufige Sicherheit: SafeMode + Befehlsvalidierung
- Pattern-basierte Filterung (Wildcards unterstützt)
- Sichere Ausführung mit `Invoke-Expression` und Fehlerabfang

### GUI-Vorbereitung
Das Modul lädt bereits Windows Forms für zukünftige GUI-Features:
- `System.Windows.Forms`  
- `System.Drawing`
- `PresentationFramework`
- `System.Speech` (für TTS)

## Nächste Schritte / Weitere Features

Diese PowerShellGPT-ähnlichen Features können noch erweitert werden:
- Voice Control (Spracheingabe)
- Browser-Integration  
- GUI Interface
- Script-Generierung und -Ausführung
- Agent Memory System
- Multi-Session Koordination

Das Fundament ist gelegt - der ChatAssistant kann jetzt sowohl Befehle ausführen als auch intelligente Gespräche führen!
