@echo off
setlocal enabledelayedexpansion

set /p NAME=Enter the Wifi Name:

netsh wlan show profile name=!NAME! key=clear

endlocal
pause
