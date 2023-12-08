@echo off

wsl -e bash -c "cd ~ && sudo apt-add-repository ppa:redislabs/redis && sudo apt-get update && sudo apt-get upgrade && sudo apt-get install redis-server"

pause