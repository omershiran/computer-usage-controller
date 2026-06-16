Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$AppName = "ComputerUsageController"
$DataDir = Join-Path $env:ProgramData $AppName
$SessionsDir = Join-Path $DataDir "sessions"

function Read-JsonFile {
    param($Path)
    try {
        return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
    }
    catch {
        return $null
    }
}

function Get-SessionRows {
    $weekStart = (Get-Date).AddDays(-7).ToUniversalTime()
    if (-not (Test-Path $SessionsDir)) { return @() }

    $rows = foreach ($file in Get-ChildItem -LiteralPath $SessionsDir -Filter "*.json" -File -ErrorAction SilentlyContinue) {
        $s = Read-JsonFile $file.FullName
        if ($null -eq $s) { continue }

        $start = [DateTime]::Parse($s.StartedAtUtc).ToUniversalTime()
        if ($start -lt $weekStart) { continue }

        $lastHeartbeat = [DateTime]::Parse($s.LastHeartbeatUtc).ToUniversalTime()
        $plannedEnd = [DateTime]::Parse($s.PlannedEndUtc).ToUniversalTime()
        $effectiveEnd = if ($lastHeartbeat -lt $plannedEnd) { $lastHeartbeat } else { $plannedEnd }
        if ($effectiveEnd -lt $start) { $effectiveEnd = $start }

        $minutes = [Math]::Round(($effectiveEnd - $start).TotalMinutes, 1)
        [pscustomobject]@{
            UserName = [string]$s.UserName
            Purpose = [string]$s.Purpose
            StartedLocal = $start.ToLocalTime()
            Minutes = $minutes
            PlannedMinutes = [int]$s.PlannedMinutes
            AfterNineRule = [bool]$s.AfterNineRule
        }
    }

    return @($rows | Sort-Object StartedLocal -Descending)
}

function Build-Summary {
    param($Rows)
    $summary = foreach ($group in ($Rows | Group-Object UserName | Sort-Object Name)) {
        $minutes = ($group.Group | Measure-Object Minutes -Sum).Sum
        [pscustomobject]@{
            "משתמש" = $group.Name
            "שעות בשבוע האחרון" = [Math]::Round($minutes / 60, 2)
            "דקות בשבוע האחרון" = [Math]::Round($minutes, 1)
            "מספר שימושים" = $group.Count
        }
    }
    return @($summary)
}

function Build-Details {
    param($Rows)
    return @($Rows | ForEach-Object {
        [pscustomobject]@{
            "משתמש" = $_.UserName
            "מטרה" = $_.Purpose
            "תחילת שימוש" = $_.StartedLocal.ToString("dd/MM/yyyy HH:mm")
            "דקות בפועל" = $_.Minutes
            "דקות שהוגדרו" = $_.PlannedMinutes
            "כלל אחרי 21:00" = if ($_.AfterNineRule) { "כן" } else { "לא" }
        }
    })
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "ניהול שימוש במחשב"
$form.Size = New-Object System.Drawing.Size(920, 620)
$form.StartPosition = "CenterScreen"
$form.RightToLeft = "Yes"
$form.RightToLeftLayout = $true
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Dock = "Fill"
$tabs.RightToLeft = "Yes"

$summaryTab = New-Object System.Windows.Forms.TabPage
$summaryTab.Text = "סיכום שבועי"
$detailsTab = New-Object System.Windows.Forms.TabPage
$detailsTab.Text = "פירוט שימושים"

$summaryGrid = New-Object System.Windows.Forms.DataGridView
$summaryGrid.Dock = "Fill"
$summaryGrid.ReadOnly = $true
$summaryGrid.AllowUserToAddRows = $false
$summaryGrid.AllowUserToDeleteRows = $false
$summaryGrid.AutoSizeColumnsMode = "Fill"
$summaryGrid.SelectionMode = "FullRowSelect"

$detailsGrid = New-Object System.Windows.Forms.DataGridView
$detailsGrid.Dock = "Fill"
$detailsGrid.ReadOnly = $true
$detailsGrid.AllowUserToAddRows = $false
$detailsGrid.AllowUserToDeleteRows = $false
$detailsGrid.AutoSizeColumnsMode = "Fill"
$detailsGrid.SelectionMode = "FullRowSelect"

$topPanel = New-Object System.Windows.Forms.Panel
$topPanel.Dock = "Top"
$topPanel.Height = 46

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "רענון"
$refreshButton.Location = New-Object System.Drawing.Point(780, 8)
$refreshButton.Size = New-Object System.Drawing.Size(90, 30)

$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Text = "הנתונים מחושבים לפי 7 הימים האחרונים. אם המחשב כובה לפני הזמן, החישוב נעצר לפי פעימת החיים האחרונה שנרשמה."
$infoLabel.Location = New-Object System.Drawing.Point(20, 11)
$infoLabel.Size = New-Object System.Drawing.Size(735, 24)
$infoLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight

$topPanel.Controls.AddRange(@($refreshButton, $infoLabel))
$summaryTab.Controls.Add($summaryGrid)
$detailsTab.Controls.Add($detailsGrid)
$tabs.TabPages.AddRange(@($summaryTab, $detailsTab))
$form.Controls.Add($tabs)
$form.Controls.Add($topPanel)

$refresh = {
    $rows = Get-SessionRows
    $summaryGrid.DataSource = [System.Collections.ArrayList](Build-Summary $rows)
    $detailsGrid.DataSource = [System.Collections.ArrayList](Build-Details $rows)
}

$refreshButton.Add_Click($refresh)
$form.Add_Shown($refresh)

[void]$form.ShowDialog()
