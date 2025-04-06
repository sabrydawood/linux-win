@echo off
setlocal

:: Prompt for filename and email
set /p "filename=Enter the SSH key filename: "
set /p "email=Enter your email: "

:: Define SSH directory
set "sshDir=%USERPROFILE%\.ssh"
if not exist "%sshDir%" mkdir "%sshDir%"

:: Generate SSH key
ssh-keygen -t rsa -b 4096 -C "%email%" -f "%sshDir%\%filename%" -N ""

:: Start SSH agent
echo.
echo Starting SSH agent...
@REM eval "$(ssh-agent -s)"
call ssh-agent > nul

:: Add SSH key to agent
ssh-add "%sshDir%\%filename%"

:: Display public key
echo.
echo ==== PUBLIC KEY ====
type "%sshDir%\%filename%.pub"

endlocal
pause