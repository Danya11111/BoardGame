# Download lsFusion server JAR for Board Game project
# Run: .\download-server.ps1

$url = "https://download.lsfusion.org/java/lsfusion-server-6.1.jar"
$output = "$PSScriptRoot\lib\lsfusion-server-6.1.jar"

if (-not (Test-Path "$PSScriptRoot\lib")) {
    New-Item -ItemType Directory -Path "$PSScriptRoot\lib" -Force
}

Write-Host "Downloading lsFusion server 6.1..."
Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing
Write-Host "Done! JAR saved to: $output"
Write-Host "Now run: mvn clean compile"
