@echo off
setlocal enabledelayedexpansion

:: Create the server diretory and navigate to it
for /f "tokens=1,* delims=:" %%a in ('findstr "Filepath:" server.txt') do (
    set filepath=%%b
)
set filepath=%filepath:~1%
echo %filepath%
echo Creating directory
mkdir %filepath%
cd %filepath%