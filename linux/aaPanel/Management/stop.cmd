@echo off
echo Stop aaPanel Server ...
wsl -e bash -c "cd ~ && sudo service bt stop"
echo aaPanel Server Stoped
pause