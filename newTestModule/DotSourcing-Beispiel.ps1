# DotSourcing-Beispiel.ps1
# Beispiel für die Einbindung eines Moduls mit Dot-Sourcing und Kompilierung mit PS2EXE

# Methode 1: Direktes Einbetten des Moduls durch Kopieren des Codes
# Diese Methode ist am besten für die Kompilierung mit PS2EXE geeignet

# Modulcode direkt einbetten (Kopie aus MeinModul.psm1)
function Get-Begruessung {
    param(
        [string]$Name = "Welt"
    )
    return "Hallo, $Name!"
}

function Get-Datum {
    return Get-Date -Format "dd.MM.yyyy HH:mm:ss"
}

function Get-Systeminfo {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    
    return @{
        ComputerName = $computerSystem.Name
        OSName = $os.Caption
        OSVersion = $os.Version
        Manufacturer = $computerSystem.Manufacturer
        Model = $computerSystem.Model
        Memory = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
    }
}

# Hauptskript
function Show-SystemInfo {
    Clear-Host
    $begruessung = Get-Begruessung -Name $env:USERNAME
    $datum = Get-Datum
    $sysInfo = Get-Systeminfo
    
    Write-Host "$begruessung" -ForegroundColor Green
    Write-Host "Aktuelles Datum und Uhrzeit: $datum" -ForegroundColor Yellow
    Write-Host "\nSysteminformationen:" -ForegroundColor Cyan
    Write-Host "------------------" -ForegroundColor Cyan
    Write-Host "Computername: $($sysInfo.ComputerName)" -ForegroundColor White
    Write-Host "Betriebssystem: $($sysInfo.OSName)" -ForegroundColor White
    Write-Host "Version: $($sysInfo.OSVersion)" -ForegroundColor White
    Write-Host "Hersteller: $($sysInfo.Manufacturer)" -ForegroundColor White
    Write-Host "Modell: $($sysInfo.Model)" -ForegroundColor White
    Write-Host "Arbeitsspeicher: $($sysInfo.Memory) GB" -ForegroundColor White
    
    Write-Host "\nDieses Programm wurde mit PS2EXE kompiliert." -ForegroundColor Magenta
}

# Ausführen der Hauptfunktion
Show-SystemInfo

# Warten auf Benutzereingabe, damit das Fenster nicht sofort schließt
Write-Host "\nDrücken Sie eine beliebige Taste, um fortzufahren..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

<#
# Kompilieren mit PS2EXE
# Führen Sie die folgenden Befehle in PowerShell aus, um das Skript zu kompilieren:

# Installieren des PS2EXE-Moduls (falls noch nicht installiert)
Install-Module -Name ps2exe -Scope CurrentUser -Force

# Kompilieren des Skripts zu einer EXE-Datei
Invoke-ps2exe -inputFile "DotSourcing-Beispiel.ps1" -outputFile "SystemInfo.exe" -title "System Information" -version "1.0.0"

# Alternativ können Sie auch die GUI-Version verwenden:
Win-PS2EXE
#>