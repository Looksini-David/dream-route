# PowerShell script to start the backend server
Set-Location -Path "$PSScriptRoot\Backend"
python main.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

