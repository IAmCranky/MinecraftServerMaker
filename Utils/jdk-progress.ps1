param(
    [Parameter(Mandatory=$true)]
    [string]$Url,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputPath,
    
    [string]$Title = "File Download Progress"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = $Title
$form.Size = New-Object System.Drawing.Size(500, 180)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.TopMost = $true

# Create progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 20)
$progressBar.Size = New-Object System.Drawing.Size(440, 25)
$progressBar.Style = "Continuous"
$progressBar.Minimum = 0
$progressBar.Maximum = 100

# Create status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(20, 55)
$statusLabel.Size = New-Object System.Drawing.Size(440, 20)
$statusLabel.Text = "Initializing download..."

# Create speed label
$speedLabel = New-Object System.Windows.Forms.Label
$speedLabel.Location = New-Object System.Drawing.Point(20, 80)
$speedLabel.Size = New-Object System.Drawing.Size(440, 20)
$speedLabel.Text = ""

# Create ETA label
$etaLabel = New-Object System.Windows.Forms.Label
$etaLabel.Location = New-Object System.Drawing.Point(20, 105)
$etaLabel.Size = New-Object System.Drawing.Size(440, 20)
$etaLabel.Text = ""

# Add controls to form
$form.Controls.Add($progressBar)
$form.Controls.Add($statusLabel)
$form.Controls.Add($speedLabel)
$form.Controls.Add($etaLabel)

# Show form
$form.Show()
$form.Refresh()

function Download-FileWithProgress {
    param(
        [string]$Url,
        [string]$OutputPath
    )
    
    $startTime = Get-Date
    
    try {
        # Create directory if it doesn't exist
        $directory = Split-Path -Parent $OutputPath
        if (!(Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        # Remove existing file if it exists
        if (Test-Path $OutputPath) {
            Remove-Item $OutputPath -Force
        }
        
        $statusLabel.Text = "Connecting to server..."
        $form.Refresh()
        
        # Create WebClient
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        
        # Progress event handler
        $progressAction = {
            try {
                $received = $Event.SourceEventArgs.BytesReceived
                $total = $Event.SourceEventArgs.TotalBytesToReceive
                $percentage = $Event.SourceEventArgs.ProgressPercentage
                
                # Update progress bar
                if ($percentage -ge 0 -and $percentage -le 100) {
                    $progressBar.Value = $percentage
                }
                
                # Calculate speed and ETA
                $elapsed = (Get-Date) - $startTime
                if ($elapsed.TotalSeconds -gt 1) {
                    $speed = $received / $elapsed.TotalSeconds
                    $speedKB = [Math]::Round($speed / 1KB, 0)
                    
                    if ($total -gt 0) {
                        $remaining = $total - $received
                        $eta = if ($speed -gt 0) { [TimeSpan]::FromSeconds($remaining / $speed) } else { [TimeSpan]::Zero }
                        
                        $receivedMB = [Math]::Round($received / 1MB, 1)
                        $totalMB = [Math]::Round($total / 1MB, 1)
                        
                        $statusLabel.Text = "Downloaded: $receivedMB MB / $totalMB MB ($percentage%)"
                        $speedLabel.Text = "Speed: $speedKB KB/s"
                        $etaLabel.Text = "ETA: $($eta.ToString('mm\:ss'))"
                    } else {
                        $receivedMB = [Math]::Round($received / 1MB, 1)
                        $statusLabel.Text = "Downloaded: $receivedMB MB ($percentage%)"
                        $speedLabel.Text = "Speed: $speedKB KB/s"
                    }
                }
                
                $form.Refresh()
            } catch {
                # Ignore errors in progress handler
            }
        }
        
        # Register progress event only
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action $progressAction | Out-Null
        
        # Start the download
        $statusLabel.Text = "Starting download..."
        $form.Refresh()
        $webClient.DownloadFileAsync($Url, $OutputPath)
        
        # FIXED: Check WebClient.IsBusy instead of relying on event variables
        $timeoutStart = Get-Date
        $timeoutMinutes = 10
        
        while ($webClient.IsBusy) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 15
            
            # Check for timeout
            $currentTime = Get-Date
            if (($currentTime - $timeoutStart).TotalMinutes -gt $timeoutMinutes) {
                $webClient.CancelAsync()
                $statusLabel.Text = "Download timed out after $timeoutMinutes minutes"
                $form.Refresh()
                break
            }
        }
        
        # Check if download was successful
        $success = $false
        if (Test-Path $OutputPath) {
            $fileSize = (Get-Item $OutputPath).Length
            if ($fileSize -gt 0) {
                $success = $true
                $progressBar.Value = 100
                $statusLabel.Text = "Download completed successfully!"
                $speedLabel.Text = ""
                $etaLabel.Text = ""
            } else {
                $statusLabel.Text = "Download failed: File is empty"
            }
        } else {
            $statusLabel.Text = "Download failed: File not found"
        }
        
        $form.Refresh()
        
        # Clean up events
        Get-EventSubscriber | Where-Object { $_.SourceObject -eq $webClient } | Unregister-Event
        $webClient.Dispose()
        
        return $success
        
    } catch {
        $statusLabel.Text = "Error: $($_.Exception.Message)"
        $form.Refresh()
        return $false
    }
}

# Perform the download
$success = Download-FileWithProgress -Url $Url -OutputPath $OutputPath

# Show result briefly then close
Start-Sleep -Seconds 1
$form.Close()
