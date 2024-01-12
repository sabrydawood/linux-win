@echo off
echo Starting Redis Server ...
wsl -e bash -c "cd ~ && sudo service redis-server start"
echo Redis Server Started
pause