@echo off
setlocal enabledelayedexpansion
taskkill /f /im explorer.exe 

start explorer.exe

if errorlevel 1 goto endlocal
exit