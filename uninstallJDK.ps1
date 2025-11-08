$uninstallPaths = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

$currentVersions = foreach ($path in $uninstallPaths) {
    Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like '*Eclipse Temurin JDK with Hotspot*'
    }
}

if (-not $currentVersions -or $currentVersions.Count -eq 0) {
    Write-Host "No Eclipse Temurin JDK installations found. Exiting script." -ForegroundColor Yellow
    exit
}

foreach ($uninstaller in $currentVersions) {
    try {
        Write-Host "Uninstalling $($uninstaller.DisplayName)..."
        $uninstallString = $uninstaller.UninstallString
        if ($uninstallString) {
            $exePath = $null
            $uninstallArgs = $null
            if ($uninstallString -match 'msiexec\.exe') {
                $exePath = 'msiexec.exe'
                $uninstallArgs = (($uninstallString -replace '^"?msiexec\.exe"?\s*', '') -replace '/I', '/X') + ' /passive'
            } else {
                if ($uninstallString -match '^"(.+?)"\s*(.*)') {
                    $exePath = $matches[1]
                    $uninstallArgs = $matches[2]
                } else {
                    $parts = $uninstallString -split '\s+', 2
                    $exePath = $parts[0]
                    $uninstallArgs = $parts[1]
                }
                
                if ($uninstallArgs) {
                    $uninstallArgs = "$uninstallArgs /quiet /norestart"
                } else {
                    $uninstallArgs = '/quiet /norestart'
                }
            }
            
            Write-Host "Running: $exePath $uninstallArgs"
            Start-Process -FilePath $exePath -ArgumentList $uninstallArgs -Wait -PassThru
            Write-Host "$($uninstaller.DisplayName) uninstalled successfully!"
        }
    }
    catch {
        Write-Host "Error uninstalling $($uninstaller.DisplayName): $_"
    }
}