Option Explicit

Dim shell, fso, scriptPath, psCommand, psPath, dataDir, logFile

If WScript.Arguments.Count <> 1 Then
    WScript.Quit 1
End If

scriptPath = WScript.Arguments(0)

Set fso = CreateObject("Scripting.FileSystemObject")
dataDir = shellExpand("%ProgramData%") & "\ComputerUsageController"
logFile = dataDir & "\launcher.log"

If Not fso.FolderExists(dataDir) Then
    On Error Resume Next
    fso.CreateFolder dataDir
    On Error GoTo 0
End If

If Not fso.FileExists(scriptPath) Then
    WriteLog "Script not found: " & scriptPath
    WScript.Quit 2
End If

psPath = shellExpand("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
If Not fso.FileExists(psPath) Then
    psPath = "powershell.exe"
End If

Set shell = CreateObject("WScript.Shell")
psCommand = Chr(34) & psPath & Chr(34) & " -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File " & Chr(34) & scriptPath & Chr(34)
WriteLog "Starting: " & psCommand
shell.Run psCommand, 0, False

Function shellExpand(value)
    Dim sh
    Set sh = CreateObject("WScript.Shell")
    shellExpand = sh.ExpandEnvironmentStrings(value)
End Function

Sub WriteLog(message)
    On Error Resume Next
    Dim stream
    Set stream = fso.OpenTextFile(logFile, 8, True)
    stream.WriteLine Now & " " & message
    stream.Close
    On Error GoTo 0
End Sub
