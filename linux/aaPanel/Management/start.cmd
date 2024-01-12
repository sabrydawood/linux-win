@echo off
echo Starting aaPanel Server ...
wsl -e bash -c "cd ~ && sudo service bt start"
echo aaPanel Server Started
pause