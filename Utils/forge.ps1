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
    Write-Host "Run with: java -jar $filename" -ForegroundColor Cyan
    Set-Content "run.bat" -Value "java -jar $filename nogui"
} catch {
    Set-Content "log.txt" -Value "$($_)"
    exit 1
}