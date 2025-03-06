@echo off
setlocal

rem Prompt for the port number
set /p port="Enter the port number: "

rem Run the PowerShell command to find the process using the specified port
powershell -Command "Get-NetTCPConnection | Where-Object { $_.LocalPort -eq %port% } | Select-Object LocalAddress, LocalPort, OwningProcess | Format-Table -AutoSize"

if %errorlevel% neq 0 (
    echo No process found using port %port%.
)

endlocal
pause
