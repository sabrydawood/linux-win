@echo off
echo ReStarting Redis Server ...
wsl -e bash -c "cd ~ && sudo service redis-server restart"
echo Redis Server Started
pause