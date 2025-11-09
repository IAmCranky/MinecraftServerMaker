@echo off
setlocal enabledelayedexpansion

:: Create the server diretory and navigate to it
set /p "filepath=Filepath: "
echo %filepath%
echo Creating directory
mkdir %filepath%

:: call Utils\jdk.bat

cd %filepath%
set /p "mc_version=Minecraft Version: "
:: %~dp0 is basically C:\current_directory\
powershell -ExecutionPolicy Bypass -File "%~dp0Utils\forge.ps1" -MinecraftVersion "%mc_version%" 

pause
