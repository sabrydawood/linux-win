@echo off
echo Restarting aaPanel Server ...
wsl -e bash -c "cd ~ && sudo service bt restart"
echo aaPanel Server Restarted
pause