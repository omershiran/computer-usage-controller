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

$shortcutPath = Join-Path ([Environment]::GetFolderPath("CommonDesktopDirectory")) "ניהול שימוש במחשב.lnk"
if (Test-Path $shortcutPath) {
    Remove-Item -LiteralPath $shortcutPath -Force
}

Write-Host "ההסרה הסתיימה. נתוני שימוש נשארו בתיקייה:"
Write-Host $InstallDir
Write-Host "אם רוצים למחוק גם את הנתונים, מחקו ידנית את התיקייה הזו."
