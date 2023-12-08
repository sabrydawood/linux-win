@echo off
powershell -Command "Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux"

:: Wait for a moment to allow the installation to complete
timeout /t 10 /nobreak

:: Install Ubuntu 18.04 (or your preferred version)
wsl --list --quiet | findstr /i "Ubuntu-18.04"
if %errorlevel% neq 0 (
    echo Installing Ubuntu 18.04
    wsl --install -d Ubuntu-18.04
) else (
    echo Ubuntu 18.04 is already installed
)

wsl

pause

