@echo off
echo Closing Redis Server ...
wsl -e bash -c "cd ~ && sudo service redis-server stop"
echo Redis Server Closed

pause