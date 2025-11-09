param(
    [Parameter(Mandatory=$true)]
    [string]$MinecraftVersion
)

try {
    Write-Host "Fetching latest Forge version for Minecraft $MinecraftVersion..." -ForegroundColor Yellow
    
    # Get promotions data
    $response = Invoke-RestMethod -Uri "https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json"
    
    # Find latest version
    $latestKey = "$MinecraftVersion-latest"
    if (-not $response.promos.PSObject.Properties.Name -contains $latestKey) {
        Write-Host "No Forge version found for Minecraft $MinecraftVersion" -ForegroundColor Red
        exit 1
    }
    
    $forgeBuild = $response.promos.$latestKey
    $forgeVersion = "$MinecraftVersion-$forgeBuild"
    
    # Download
    $url = "https://maven.minecraftforge.net/net/minecraftforge/forge/$forgeVersion/forge-$forgeVersion-installer.jar"
    $filename = "forge-$forgeVersion-installer.jar"
    
    Write-Host "Downloading Forge $forgeVersion..." -ForegroundColor Green
    
    Invoke-WebRequest -Uri $url -OutFile $filename -UseBasicParsing

    Write-Host "Successfully downloaded: $filename" -ForegroundColor Green    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

try{
    java -jar $filename --installServer --extract
    Set-Content -Path 'user_jvm_args.txt' -Value '-Xmx4G
-Djava.awt.headless=true'
} catch {
    Set-Content -Path "log.txt" -Value "$($_)"
    exit 1
}

# AGREE TO EULA
Add-Type -AssemblyName System.Windows.Forms

$result = [System.Windows.Forms.MessageBox]::Show(
    "Do you agree?", 
    "Confirmation", 
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)
if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
    Copy-Item "..\Config\run.bat" "run.bat" -Force
    Set-Content -Path 'eula.txt' -Value 'eula=true'
    # Continue with your script here
} else {
    Write-Host "Exiting program..."
    Start-Sleep 1
    exit
}