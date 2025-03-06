@echo off
setlocal enabledelayedexpansion

:: Get WSL distributions and store in a temporary file
wsl -l -v > wsl_list.txt

:: Display options to the user
set /a count=0
for /f "skip=1 tokens=1,2,3" %%A in (wsl_list.txt) do (
    set /a count+=1
    echo %%A %%B %%C ^=> !count!
    set "wsl[!count!]=%%A"
)

del wsl_list.txt

echo.
set /p choice=Enter the number of the WSL distribution: 

:: Validate choice
if not defined wsl[%choice%] (
    echo Invalid choice. Exiting.
    exit /b
)

set "wsl_name=!wsl[%choice%]!"

echo Selected WSL: %wsl_name%

:: Ask for username
set /p username=Enter the username to change password: 

:: Change password
wsl -d %wsl_name% -u root -- passwd %username%

echo Password changed successfully!
pause
