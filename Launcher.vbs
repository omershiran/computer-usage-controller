Option Explicit

Dim shell, fso, scriptPath, psCommand

If WScript.Arguments.Count <> 1 Then
    WScript.Quit 1
End If

scriptPath = WScript.Arguments(0)

Set fso = CreateObject("Scripting.FileSystemObject")
If Not fso.FileExists(scriptPath) Then
    WScript.Quit 2
End If

Set shell = CreateObject("WScript.Shell")
psCommand = "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File " & Chr(34) & scriptPath & Chr(34)
shell.Run psCommand, 0, False
