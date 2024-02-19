@echo off
setlocal enabledelayedexpansion

set /p "NAME=Enter the project name: "
set /p "VERSION=Enter the project version:"

echo Choose (1)avaScript or (2)ypeScript:
echo 1. JavaScript
echo 2. TypeScript

set "choice="
set /p "choice=Enter your choice (1 or 2): "
if "%choice%"=="1" set TEMPLATE=javascript
if "%choice%"=="2" set TEMPLATE=typescript
:: if not choice 1 or 2, default to JavaScript
if not "%choice%"=="1" if not "%choice%"=="2" set TEMPLATE=javascript

set "NAME=!NAME!"
set "VERSION=!VERSION!"

echo Creating project %NAME% with version %VERSION% and template %TEMPLATE%...
:: create react app 
call npx create-react-app !NAME! --template !TEMPLATE!
