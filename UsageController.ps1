Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$AppName = "ComputerUsageController"
$DataDir = Join-Path $env:ProgramData $AppName
$SessionsDir = Join-Path $DataDir "sessions"
$UsersFile = Join-Path $DataDir "users.json"

New-Item -ItemType Directory -Force -Path $SessionsDir | Out-Null

function ConvertTo-SafeFileName {
    param([string]$Text)
    $invalid = [System.IO.Path]::GetInvalidFileNameChars()
    $safe = -join ($Text.ToCharArray() | ForEach-Object {
        if ($invalid -contains $_) { "_" } else { $_ }
    })
    if ([string]::IsNullOrWhiteSpace($safe)) { return "unknown" }
    return $safe.Trim()
}

function Read-JsonFile {
    param($Path, $Default)
    if (-not (Test-Path $Path)) { return $Default }
    try {
        return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
    }
    catch {
        return $Default
    }
}

function Write-JsonFile {
    param($Path, $Value)
    $json = $Value | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Show-HebrewMessage {
    param(
        [string]$Text,
        [string]$Title = "בקר שימוש במחשב",
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Information
    )
    [System.Windows.Forms.MessageBox]::Show(
        $Text,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $Icon,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button1,
        [System.Windows.Forms.MessageBoxOptions]::RightAlign -bor [System.Windows.Forms.MessageBoxOptions]::RtlReading
    ) | Out-Null
}

function New-Label {
    param([string]$Text, [int]$X, [int]$Y)
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Size = New-Object System.Drawing.Size(390, 24)
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    return $label
}

function Show-UsageForm {
    param([bool]$AfterNine)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "רישום שימוש במחשב"
    $form.Size = New-Object System.Drawing.Size(460, 360)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.RightToLeft = "Yes"
    $form.RightToLeftLayout = $true
    $form.TopMost = $true
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    $nameLabel = New-Label "מי המשתמש?" 25 24
    $nameBox = New-Object System.Windows.Forms.TextBox
    $nameBox.Location = New-Object System.Drawing.Point(25, 52)
    $nameBox.Size = New-Object System.Drawing.Size(390, 28)
    $nameBox.RightToLeft = "Yes"

    $purposeLabel = New-Label "מטרת השימוש" 25 90
    $purposeBox = New-Object System.Windows.Forms.TextBox
    $purposeBox.Location = New-Object System.Drawing.Point(25, 118)
    $purposeBox.Size = New-Object System.Drawing.Size(390, 68)
    $purposeBox.Multiline = $true
    $purposeBox.RightToLeft = "Yes"

    $minutesLabel = New-Label "זמן בדקות (עד 120)" 25 198
    $minutesInput = New-Object System.Windows.Forms.NumericUpDown
    $minutesInput.Location = New-Object System.Drawing.Point(25, 226)
    $minutesInput.Size = New-Object System.Drawing.Size(120, 28)
    $minutesInput.Minimum = 1
    $minutesInput.Maximum = 120
    $minutesInput.Value = 40

    $notice = New-Object System.Windows.Forms.Label
    $notice.Location = New-Object System.Drawing.Point(25, 260)
    $notice.Size = New-Object System.Drawing.Size(390, 34)
    $notice.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $notice.ForeColor = [System.Drawing.Color]::DarkRed
    if ($AfterNine) {
        $notice.Text = "אחרי 21:00 מותר שימוש דחוף בלבד. הזמן מוגבל אוטומטית ל-10 דקות."
        $minutesInput.Value = 10
        $minutesInput.Enabled = $false
    }

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "אישור"
    $okButton.Location = New-Object System.Drawing.Point(230, 298)
    $okButton.Size = New-Object System.Drawing.Size(88, 32)
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "ביטול"
    $cancelButton.Location = New-Object System.Drawing.Point(327, 298)
    $cancelButton.Size = New-Object System.Drawing.Size(88, 32)
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    $form.Controls.AddRange(@(
        $nameLabel, $nameBox,
        $purposeLabel, $purposeBox,
        $minutesLabel, $minutesInput,
        $notice, $okButton, $cancelButton
    ))

    while ($true) {
        $result = $form.ShowDialog()
        if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
            return $null
        }

        if ([string]::IsNullOrWhiteSpace($nameBox.Text)) {
            Show-HebrewMessage "חובה להזין שם משתמש." "חסר שם" ([System.Windows.Forms.MessageBoxIcon]::Warning)
            continue
        }
        if ([string]::IsNullOrWhiteSpace($purposeBox.Text)) {
            Show-HebrewMessage "חובה להזין מטרת שימוש." "חסרה מטרה" ([System.Windows.Forms.MessageBoxIcon]::Warning)
            continue
        }

        return [pscustomobject]@{
            UserName = $nameBox.Text.Trim()
            Purpose = $purposeBox.Text.Trim()
            PlannedMinutes = [int]$minutesInput.Value
        }
    }
}

Show-HebrewMessage "שימוש מרובה במחשב אינו בריא , השתמש בו בתבונה"

$now = Get-Date
$afterNine = $now.TimeOfDay -ge ([TimeSpan]::FromHours(21))
if ($afterNine) {
    Show-HebrewMessage "אין להשתמש במחשב אחרי שעה 9 אלא במקרים דחופים ועד 10 דקות." "אזהרת שימוש" ([System.Windows.Forms.MessageBoxIcon]::Warning)
}

$entry = Show-UsageForm -AfterNine:$afterNine
if ($null -eq $entry) {
    Show-HebrewMessage "לא הוזנו פרטי שימוש. המחשב יכובה בעוד דקה." "בקר שימוש במחשב" ([System.Windows.Forms.MessageBoxIcon]::Warning)
    shutdown.exe /s /t 60 /c "לא הוזנו פרטי שימוש במחשב."
    exit
}

if ($afterNine) {
    $entry.PlannedMinutes = 10
}
elseif ($entry.PlannedMinutes -gt 120) {
    $entry.PlannedMinutes = 120
}

$sessionId = [guid]::NewGuid().ToString()
$start = Get-Date
$end = $start.AddMinutes($entry.PlannedMinutes)
$session = [ordered]@{
    SessionId = $sessionId
    UserName = $entry.UserName
    Purpose = $entry.Purpose
    StartedAtUtc = $start.ToUniversalTime().ToString("o")
    PlannedEndUtc = $end.ToUniversalTime().ToString("o")
    PlannedMinutes = $entry.PlannedMinutes
    AfterNineRule = [bool]$afterNine
    LastHeartbeatUtc = $start.ToUniversalTime().ToString("o")
    ShutdownTriggeredUtc = $null
}

$sessionFile = Join-Path $SessionsDir ("{0}_{1}.json" -f $start.ToString("yyyyMMdd_HHmmss"), (ConvertTo-SafeFileName $entry.UserName))
Write-JsonFile $sessionFile $session

$users = @(Read-JsonFile $UsersFile @())
if (-not ($users | Where-Object { $_ -eq $entry.UserName })) {
    $users += $entry.UserName
    Write-JsonFile $UsersFile $users
}

$warned = $false
while ($true) {
    $remaining = $end - (Get-Date)
    if (-not $warned -and $remaining.TotalSeconds -le 300 -and $remaining.TotalSeconds -gt 0) {
        $warned = $true
        Show-HebrewMessage "תזכורת: בעוד 5 דקות המחשב יכבה אוטומטית." "תזכורת כיבוי" ([System.Windows.Forms.MessageBoxIcon]::Warning)
    }

    if ((Get-Date) -ge $end) {
        $session.ShutdownTriggeredUtc = (Get-Date).ToUniversalTime().ToString("o")
        $session.LastHeartbeatUtc = (Get-Date).ToUniversalTime().ToString("o")
        Write-JsonFile $sessionFile $session
        shutdown.exe /s /t 60 /c "זמן השימוש שהוגדר הסתיים. המחשב יכובה."
        exit
    }

    $session.LastHeartbeatUtc = (Get-Date).ToUniversalTime().ToString("o")
    Write-JsonFile $sessionFile $session
    Start-Sleep -Seconds ([Math]::Min(60, [Math]::Max(5, [int]$remaining.TotalSeconds)))
}
