@echo off

wsl -e bash -c "sudo curl -O https://nodejs.org/dist/v20.10.0/node-v20.10.0-linux-x64.tar.xz && sudo mkdir -p /opt/nodejs && sudo tar xvfJ node-v20.10.0-linux-x64.tar.xz -C /opt/nodejs/ && export PATH=/opt/nodejs/node-v20.10.0-linux-x64/bin:$PATH && node -v"

pause