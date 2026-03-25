# Download lsFusion server JAR for Board Game project
# Run: .\download-server.ps1
#
# Скачивает во временный .part и затем переименовывает — так не падает, если старый JAR
# открыт другим процессом (но перед заменой лучше остановить java / lsFusion).

$ErrorActionPreference = "Stop"
$url = "https://download.lsfusion.org/java/lsfusion-server-6.1.jar"
$libDir = Join-Path $PSScriptRoot "lib"
$output = Join-Path $libDir "lsfusion-server-6.1.jar"
$part = Join-Path $libDir "lsfusion-server-6.1.jar.part"

if (-not (Test-Path -LiteralPath $libDir)) {
    New-Item -ItemType Directory -Path $libDir -Force | Out-Null
}

Write-Host "Downloading lsFusion server 6.1..."
try {
    Invoke-WebRequest -Uri $url -OutFile $part -UseBasicParsing
    Move-Item -LiteralPath $part -Destination $output -Force
} catch {
    if (Test-Path -LiteralPath $part) { Remove-Item -LiteralPath $part -Force -ErrorAction SilentlyContinue }
    Write-Host @"
Не удалось сохранить JAR. Если ошибка про «файл используется другим процессом»:
  1) Закройте IDE/запущенный lsFusion (процесс java), который держит lib\lsfusion-server-6.1.jar
  2) Повторите .\download-server.ps1

Исходная ошибка: $($_.Exception.Message)
"@ -ForegroundColor Red
    exit 1
}

Write-Host "Done! JAR saved to: $output"
Write-Host "Now run: mvn clean compile"
