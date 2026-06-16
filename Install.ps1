$ErrorActionPreference = "Stop"

$AppName = "ComputerUsageController"
$InstallDir = Join-Path $env:ProgramData $AppName
$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TaskName = "Computer Usage Controller"

function Assert-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "יש להפעיל את Install.ps1 כ-Administrator."
    }
}

Assert-Admin

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $InstallDir "sessions") | Out-Null

Copy-Item -LiteralPath (Join-Path $SourceDir "UsageController.ps1") -Destination $InstallDir -Force
Copy-Item -LiteralPath (Join-Path $SourceDir "AdminDashboard.ps1") -Destination $InstallDir -Force
Copy-Item -LiteralPath (Join-Path $SourceDir "Uninstall.ps1") -Destination $InstallDir -Force

$controller = Join-Path $InstallDir "UsageController.ps1"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$controller`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Shows the computer usage form and shuts down after the selected time." -Force | Out-Null

$dashboard = Join-Path $InstallDir "AdminDashboard.ps1"
$shortcutPath = Join-Path ([Environment]::GetFolderPath("CommonDesktopDirectory")) "ניהול שימוש במחשב.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$dashboard`""
$shortcut.WorkingDirectory = $InstallDir
$shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,44"
$shortcut.Save()

Write-Host "ההתקנה הסתיימה."
Write-Host "הבקר יופעל בכל כניסה ל-Windows."
Write-Host "ממשק הניהול נוסף לשולחן העבודה הציבורי."
