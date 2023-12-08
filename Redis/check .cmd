@echo off
echo Checking Redis Server ...
wsl -e bash -c "cd ~ && sudo service redis-server status"
@REM wsl -e bash -c "cd ~ && redis-cli"

pause