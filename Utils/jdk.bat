@echo off
setlocal enabledelayedexpansion

powershell -ExecutionPolicy Bypass -File "Utils\uninstallJDK.ps1"

cls
color 06

:: Get the latest JDK version using PowerShell
echo Retrieving latest Java version. . .
for /f %%i in ('powershell -Command "(Invoke-RestMethod 'https://api.adoptium.net/v3/info/available_releases').most_recent_feature_release"') do set java_version=%%i

if "%java_version%"=="" (
    echo Error: You didn't enter anything!
    pause
    exit /b 1
)

echo %java_version%| findstr /r "^[0-9][0-9]*$" >nul
if !errorlevel! neq 0 (
    echo Error: Please enter a valid number
    pause
    exit /b 1
)

:: Get the JSON
set "api_url=https://api.github.com/repos/adoptium/temurin%java_version%-binaries/releases/latest"
set "temp_json=%TEMP%\java%java_version%_release.json"

echo Getting release information. . .
curl -s "!api_url!" > "%temp_json%"

if !errorlevel! neq 0 (
    echo Error: Failed to get release info
    pause
    exit /b 1
)

:: Use PowerShell to extract the URL 
echo Extracting download URL. . .
for /f "delims=" %%i in ('powershell -Command "& {$json = Get-Content '%temp_json%' | ConvertFrom-Json; $json.assets | Where-Object {$_.name -like '*windows*' -and $_.name -like '*.msi'} | Select-Object -First 1 | ForEach-Object {$_.browser_download_url}}"') do (
    set "download_url=%%i"
)

if "%download_url%"=="" (
    echo Error: Could not find Windows MSI download URL
    echo Available files:
    powershell -Command "& {$json = Get-Content \"%temp_json%\" | ConvertFrom-Json; $json.assets | ForEach-Object {$_.name}}"
    pause
    exit /b 1
)

echo.

:: Set up the installer path
set "installer_path=%TEMP%\OpenJDK%java_version%-installer.msi"

:: Download with GUI progress bar instead of curl
echo Downloading Java %java_version% installer with GUI progress. . .
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "Utils\jdk-progress.ps1" -Url "!download_url!" -OutputPath "!installer_path!" -Title "Downloading Java %java_version%"

if !errorlevel! neq 0 (
    echo Error: Download failed
    pause
    exit /b 1
)

echo.
echo Download succeeded! Java %java_version% installer downloaded!
echo.
cls
del "%temp_json%" 2>nul

:: Install Java
set "install_dir=C:\Program Files\Eclipse Adoptium\OpenJDK%java_version%"
echo Installing Open JDK %java_version% to %install_dir%

powershell -Command "& {Start-Process msiexec -ArgumentList '/i \"!installer_path!\" /passive INSTALLDIR=\"%install_dir%\"' -Wait}"

echo Installation complete!

echo Cleaning up. . .
del "%installer_path%" 2>nul
