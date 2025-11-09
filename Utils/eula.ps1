Add-Type -AssemblyName System.Windows.Forms

$result = [System.Windows.Forms.MessageBox]::Show(
    "Do you agree?", 
    "Confirmation", 
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)

if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
    Set-Content -Path 'eula.txt' -Value 'eula=true'
    # Continue with your script here
} else {
    Write-Host "Exiting program..."
    Start-Sleep 1
    exit
}