@echo off
setlocal enabledelayedexpansion
set /p PORT=Enter the port number:
:: Find the process using the specified port
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%PORT%"') do set "PID=%%a"
:: Check if PID is not empty (process found)
if not "!PID!"=="" (
    echo Process found with PID: !PID!
    :: ask to kill or not
    set /P "KILL=Do you want to kill this process? (Y/N): "
    set "KILL=!KILL:~0,1!"  :: Extract the first character (Y/N)
    :: Check if user wants to kill
    if /i "!KILL!"=="Y" (
        :: Kill the process
        taskkill /PID !PID! /F
        @REM echo Process killed.
        exit /b 0  :: Exit the script
    ) else (
        echo Cancelled.
        exit /b 0  :: Exit the script
    )
) else (
    echo No process found using port %PORT%.
)

endlocal


