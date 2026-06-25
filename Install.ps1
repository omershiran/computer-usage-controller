$ErrorActionPreference = "Stop"

$AppName = "ComputerUsageController"
$InstallDir = Join-Path $env:ProgramData $AppName
$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TaskName = "Computer Usage Controller"
$WScriptExe = Join-Path $env:SystemRoot "System32\wscript.exe"

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
Copy-Item -LiteralPath (Join-Path $SourceDir "Launcher.vbs") -Destination $InstallDir -Force

$controller = Join-Path $InstallDir "UsageController.ps1"
$launcher = Join-Path $InstallDir "Launcher.vbs"
$action = New-ScheduledTaskAction -Execute $WScriptExe -Argument "`"$launcher`" `"$controller`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -GroupId "Users" -RunLevel LeastPrivilege
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Shows the computer usage form and shuts down after the selected time." -Force | Out-Null

$dashboard = Join-Path $InstallDir "AdminDashboard.ps1"

function New-DashboardShortcut {
    param([string]$DesktopPath)

    if ([string]::IsNullOrWhiteSpace($DesktopPath)) { return }
    if (-not (Test-Path -LiteralPath $DesktopPath)) { return }

    $shortcutPath = Join-Path $DesktopPath "ניהול שימוש במחשב.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $WScriptExe
    $shortcut.Arguments = "`"$launcher`" `"$dashboard`""
    $shortcut.WorkingDirectory = $InstallDir
    $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,44"
    $shortcut.Save()
}

New-DashboardShortcut ([Environment]::GetFolderPath("CommonDesktopDirectory"))

$usersRoot = Join-Path $env:SystemDrive "Users"
if (Test-Path -LiteralPath $usersRoot) {
    Get-ChildItem -LiteralPath $usersRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin @("Default", "Default User", "All Users", "Public") } |
        ForEach-Object {
            New-DashboardShortcut (Join-Path $_.FullName "Desktop")
        }
}

Write-Host "ההתקנה הסתיימה."
Write-Host "הבקר יופעל בכל כניסה ל-Windows."
Write-Host "ממשק הניהול נוסף לשולחן העבודה."
