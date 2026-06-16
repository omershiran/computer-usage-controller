$ErrorActionPreference = "Stop"

$TaskName = "Computer Usage Controller"
$AppName = "ComputerUsageController"
$InstallDir = Join-Path $env:ProgramData $AppName

try {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
}
catch {
    Write-Host "לא נמצאה משימה מתוזמנת בשם $TaskName."
}

function Remove-DashboardShortcut {
    param([string]$DesktopPath)

    if ([string]::IsNullOrWhiteSpace($DesktopPath)) { return }
    $shortcutPath = Join-Path $DesktopPath "ניהול שימוש במחשב.lnk"
    if (Test-Path -LiteralPath $shortcutPath) {
        Remove-Item -LiteralPath $shortcutPath -Force
    }
}

Remove-DashboardShortcut ([Environment]::GetFolderPath("CommonDesktopDirectory"))

$usersRoot = Join-Path $env:SystemDrive "Users"
if (Test-Path -LiteralPath $usersRoot) {
    Get-ChildItem -LiteralPath $usersRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin @("Default", "Default User", "All Users", "Public") } |
        ForEach-Object {
            Remove-DashboardShortcut (Join-Path $_.FullName "Desktop")
        }
}

Write-Host "ההסרה הסתיימה. נתוני שימוש נשארו בתיקייה:"
Write-Host $InstallDir
Write-Host "אם רוצים למחוק גם את הנתונים, מחקו ידנית את התיקייה הזו."
