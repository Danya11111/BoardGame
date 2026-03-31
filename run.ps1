# Единая точка входа: JAR lsFusion, при наличии Docker — полный стек (Postgres + logics + web);
# иначе — локальный сервер логики (нужны Java 17, Maven, PostgreSQL на localhost).
# Bootstrap читает db.* из lsfusion.properties только в локальном режиме; в Docker параметры задаёт compose/entrypoint.

param(
    # Принудительно локальный сервер логики, даже если Docker доступен.
    [switch]$Local
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
Set-Location -LiteralPath $Root

function Ensure-LsfServerJar {
    param([string]$ProjectRoot)
    $libDir = Join-Path $ProjectRoot "lib"
    $jarPath = Join-Path $libDir "lsfusion-server-6.1.jar"
    if (Test-Path -LiteralPath $jarPath) { return }
    if (-not (Test-Path -LiteralPath $libDir)) {
        New-Item -ItemType Directory -Path $libDir -Force | Out-Null
    }
    $url = "https://download.lsfusion.org/java/lsfusion-server-6.1.jar"
    Write-Host "Не найден lib\lsfusion-server-6.1.jar — загрузка с download.lsfusion.org ..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $jarPath -UseBasicParsing
    } catch {
        if (Test-Path -LiteralPath $jarPath) {
            Remove-Item -LiteralPath $jarPath -Force -ErrorAction SilentlyContinue
        }
        throw
    }
    Write-Host "Готово: $jarPath"
}

function Test-DockerComposeReady {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { return $false }
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { return $false }
    docker compose version 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { return $true }
    docker-compose version 2>&1 | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Ensure-DotEnv {
    param([string]$ProjectRoot)
    $envFile = Join-Path $ProjectRoot ".env"
    $example = Join-Path $ProjectRoot ".env.example"
    if (-not (Test-Path -LiteralPath $envFile) -and (Test-Path -LiteralPath $example)) {
        Copy-Item -LiteralPath $example -Destination $envFile
        Write-Host "Создан .env из .env.example (пароль БД по умолчанию для compose — boardgame_dev)."
    }
}

function Invoke-DockerStack {
    docker compose version 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        docker compose up --build
    } else {
        docker-compose up --build
    }
    exit $LASTEXITCODE
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

function Ensure-LsfusionPropertiesForLocal {
    param([string]$ProjectRoot)
    $propsPath = Join-Path $ProjectRoot "lsfusion.properties"
    $example = Join-Path $ProjectRoot "lsfusion.properties.example"
    if (-not (Test-Path -LiteralPath $propsPath)) {
        if (-not (Test-Path -LiteralPath $example)) {
            Write-Error "Нет lsfusion.properties и lsfusion.properties.example."
        }
        Copy-Item -LiteralPath $example -Destination $propsPath
        Write-Host "Создан lsfusion.properties из примера."
    }
    $lines = Get-Content -LiteralPath $propsPath -Encoding UTF8
    $changed = $false
    $newLines = foreach ($line in $lines) {
        if ($line -match '^\s*db\.password\s*=\s*CHANGE_ME\s*$') {
            $changed = $true
            'db.password=boardgame_dev'
        } elseif ($line -match '^\s*db\.password\s*=\s*yourpassword\s*$') {
            $changed = $true
            'db.password=boardgame_dev'
        } elseif ($line -match '^\s*db\.password\s*=\s*ВАШ_ПАРОЛЬ\s*$') {
            $changed = $true
            'db.password=boardgame_dev'
        } else {
            $line
        }
    }
    if ($changed) {
        Set-Content -LiteralPath $propsPath -Value $newLines -Encoding UTF8
        Write-Host "В lsfusion.properties подставлен пароль БД boardgame_dev (как в Docker). Смените db.password, если у PostgreSQL другой пароль."
    }
}

function Invoke-PostgresInitIfPossible {
    param(
        [string]$ProjectRoot,
        [hashtable]$Props
    )
    if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
        Write-Host "Утилита psql не в PATH — базу boardgame создайте сами или используйте запуск через Docker (.\run.ps1 без -Local)."
        return
    }
    $user = if ($Props.ContainsKey("db.user") -and $Props["db.user"]) { $Props["db.user"] } else { "postgres" }
    $pass = $Props["db.password"]
    if ([string]::IsNullOrWhiteSpace($pass)) { return }
    $server = if ($Props.ContainsKey("db.server") -and $Props["db.server"]) { $Props["db.server"] } else { "localhost:5432" }
    $hostPart = "localhost"
    $portPart = "5432"
    if ($server -match '^(.+):(\d+)$') {
        $hostPart = $Matches[1].Trim()
        $portPart = $Matches[2].Trim()
    } elseif ($server.Trim() -ne "") {
        $hostPart = $server.Trim()
    }
    $env:PGPASSWORD = $pass
    try {
        $check = & psql -h $hostPart -p $portPart -U $user -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = 'boardgame'" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Не удалось подключиться к PostgreSQL (${hostPart}:${portPart}, пользователь $user). Убедитесь, что сервер запущен и пароль в lsfusion.properties верный."
            return
        }
        if ($check -match "1") { return }
        $initSql = Join-Path $ProjectRoot "scripts\postgres-init.sql"
        if (-not (Test-Path -LiteralPath $initSql)) { return }
        & psql -h $hostPart -p $portPart -U $user -d postgres -f $initSql
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Создана база данных boardgame (scripts\postgres-init.sql)."
        }
    } finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# --- общее: JAR для Maven и образа logics ---
Ensure-LsfServerJar -ProjectRoot $Root

# Docker в PATH, но демон не запущен — не уходим молча в локальный режим без PostgreSQL.
if (-not $Local -and (Get-Command docker -ErrorAction SilentlyContinue)) {
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Docker установлен, но демон не отвечает. Запустите Docker Desktop и снова выполните .\run.ps1" -ForegroundColor Yellow
        Write-Host "Локальный сервер логики без Docker: .\run.ps1 -Local (нужны Java 17, Maven, PostgreSQL)." -ForegroundColor DarkGray
        Write-Host ""
        exit 1
    }
}

# --- режим Docker: без ручных шагов с БД и lsfusion.properties ---
if (-not $Local -and (Test-DockerComposeReady)) {
    Ensure-DotEnv -ProjectRoot $Root
    Write-Host ""
    Write-Host "Режим: Docker Compose (PostgreSQL + сервер логики + веб-клиент)." -ForegroundColor Cyan
    Write-Host "После старта откройте http://localhost:8080/lsfusion" -ForegroundColor Cyan
    Write-Host "Остановка: Ctrl+C, затем при необходимости: docker compose down" -ForegroundColor DarkGray
    Write-Host ""
    Invoke-DockerStack
}

# --- локальный сервер логики ---
Write-Host ""
Write-Host "Режим: локальный BusinessLogicsBootstrap (Docker недоступен или указан -Local)." -ForegroundColor Yellow
Write-Host "Нужны Java 17, Maven и PostgreSQL с доступом по параметрам из lsfusion.properties." -ForegroundColor Yellow
Write-Host ""

Ensure-LsfusionPropertiesForLocal -ProjectRoot $Root

$PropsFile = Join-Path $Root "lsfusion.properties"
$props = Read-LsfProperties -Path $PropsFile

$required = @("db.server", "db.name", "db.user", "db.password")
foreach ($k in $required) {
    if (-not $props.ContainsKey($k) -or [string]::IsNullOrWhiteSpace($props[$k])) {
        Write-Error "В lsfusion.properties отсутствует или пусто: $k"
    }
}
$badPasswords = @("CHANGE_ME", "yourpassword", "ВАШ_ПАРОЛЬ")
if ($badPasswords -contains $props["db.password"]) {
    Write-Error "Укажите реальный db.password в lsfusion.properties (или запустите без -Local при установленном Docker)."
}

Invoke-PostgresInitIfPossible -ProjectRoot $Root -Props $props

Write-Host "mvn clean compile..."
& mvn -q clean compile
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$rmiPort = 7652
if ($props.ContainsKey("rmi.port") -and -not [string]::IsNullOrWhiteSpace($props["rmi.port"])) {
    $rmiPort = [int]$props["rmi.port"]
}
$listeners = Get-NetTCPConnection -LocalPort $rmiPort -State Listen -ErrorAction SilentlyContinue
if ($listeners) {
    Write-Host ""
    Write-Host "Порт $rmiPort (rmi.port) занят — второй экземпляр сервера не запустить." -ForegroundColor Red
    Write-Host "Остановите другой java.exe или смените rmi.port в lsfusion.properties."
    Write-Host ""
    exit 1
}

$passThrough = @(
    "db.server", "db.name", "db.user", "db.password", "db.connectTimeout",
    "rmi.port", "rmi.exportName", "http.port",
    "boardgame.initialAdminEmail",
    "boardgame.registrationUrl",
    "settings.enableUI",
    "settings.enableAPI"
)

$jvmArgs = New-Object System.Collections.Generic.List[string]
foreach ($k in $passThrough) {
    if ($props.ContainsKey($k) -and -not [string]::IsNullOrWhiteSpace($props[$k])) {
        $jvmArgs.Add("-D$k=$($props[$k])")
    }
}

$cp = "lib/lsfusion-server-6.1.jar;target/classes"
$serverLib = Join-Path $Root "target\server-lib"
if (Test-Path -LiteralPath $serverLib) {
    Get-ChildItem -LiteralPath $serverLib -Filter "*.jar" -ErrorAction SilentlyContinue | ForEach-Object {
        $cp = "$cp;$($_.FullName)"
    }
}
$jvmArgs.Add("-cp")
$jvmArgs.Add($cp)
$jvmArgs.Add("lsfusion.server.logics.BusinessLogicsBootstrap")

Write-Host "Запуск java с -D db.* из lsfusion.properties..."
& java @jvmArgs
exit $LASTEXITCODE
