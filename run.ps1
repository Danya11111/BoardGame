# Run lsFusion BusinessLogicsBootstrap from project root.
# Bootstrap resolves lsfusion.properties as /lsfusion.properties (on Windows: C:\lsfusion.properties),
# not the file in this folder. This script reads local lsfusion.properties and passes db.* via -D.

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
Set-Location -LiteralPath $Root

$Jar = Join-Path $Root "lib\lsfusion-server-6.1.jar"
$PropsFile = Join-Path $Root "lsfusion.properties"
$Example = Join-Path $Root "lsfusion.properties.example"

if (-not (Test-Path -LiteralPath $Jar)) {
    Write-Error "Missing lib\lsfusion-server-6.1.jar. Run .\download-server.ps1"
}

if (-not (Test-Path -LiteralPath $PropsFile)) {
    if (Test-Path -LiteralPath $Example) {
        Copy-Item -LiteralPath $Example -Destination $PropsFile
    }
    Write-Error "Created lsfusion.properties from example. Set db.password and run again."
}

function Read-LsfProperties {
    param([string]$Path)
    $map = @{}
    Get-Content -LiteralPath $Path -Encoding UTF8 | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $eq = $line.IndexOf("=")
        if ($eq -lt 1) { return }
        $k = $line.Substring(0, $eq).Trim()
        $v = $line.Substring($eq + 1).Trim()
        $map[$k] = $v
    }
    $map
}

$props = Read-LsfProperties -Path $PropsFile

$required = @("db.server", "db.name", "db.user", "db.password")
foreach ($k in $required) {
    if (-not $props.ContainsKey($k) -or [string]::IsNullOrWhiteSpace($props[$k])) {
        Write-Error "Missing or empty in lsfusion.properties: $k"
    }
}
$badPasswords = @("CHANGE_ME", "yourpassword", "ВАШ_ПАРОЛЬ")
if ($badPasswords -contains $props["db.password"]) {
    Write-Error "Set a real db.password in lsfusion.properties (not the example placeholder)."
}

Write-Host "mvn clean compile..."
& mvn -q clean compile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$passThrough = @(
    "db.server", "db.name", "db.user", "db.password", "db.connectTimeout",
    "rmi.port", "rmi.exportName", "http.port"
)

$jvmArgs = New-Object System.Collections.Generic.List[string]
foreach ($k in $passThrough) {
    if ($props.ContainsKey($k) -and -not [string]::IsNullOrWhiteSpace($props[$k])) {
        $jvmArgs.Add("-D$k=$($props[$k])")
    }
}

$cp = "lib/lsfusion-server-6.1.jar;target/classes"
$jvmArgs.Add("-cp")
$jvmArgs.Add($cp)
$jvmArgs.Add("lsfusion.server.logics.BusinessLogicsBootstrap")

Write-Host "Starting java with -D db.* from local lsfusion.properties..."
& java @jvmArgs
exit $LASTEXITCODE
