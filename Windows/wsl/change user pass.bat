@echo off
wsl -l -v

set /p WSL_NAME=Enter the WSL distribution Name: 

wsl -d %WSL_NAME% -u root -e bash -c "read -p 'Enter the username to change password: ' username; passwd $username"

pause
