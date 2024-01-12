@echo off
echo ReLoading Redis Server ...
wsl -e bash -c "cd ~ && sudo service redis-server force-reload"
echo Redis Server Started
pause