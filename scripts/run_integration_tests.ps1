#Requires -Version 5.1
<#
.SYNOPSIS
  Pruebas de integracion de la app contra musubi-api real (02-10, SCRUM-120).
.DESCRIPTION
  1. Compila y levanta musubi-api en Development (en memoria, correo en el log) en http://localhost:<Port>.
     La llave de pagos se genera al vuelo (32 bytes aleatorios): no es un secreto y muere con el proceso.
  2. Corre test/integration con los proveedores reales de la app (--dart-define MUSUBI_API_*).
  3. Corre tool/check_integration_coverage.dart: cada fila de docs/endpoints.md que consume musubi-app
     tiene que haberse llamado en alguna prueba.
  4. Detiene la API (siempre). El log queda en build/integration/api.log.
  Compatible con PowerShell 5.1 y pwsh. ASCII puro.
.EXAMPLE
  pwsh scripts/run_integration_tests.ps1                      # ../musubi-api
  pwsh scripts/run_integration_tests.ps1 -ApiPath ./musubi-api -Port 5090
#>
[CmdletBinding()]
param(
    [string]$ApiPath = '',
    [int]$Port = 5080,
    [string]$Tests = 'test/integration',
    [switch]$NoBuild,
    [switch]$SkipCoverage
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
if ($ApiPath -eq '') { $ApiPath = Join-Path (Split-Path -Parent $repoRoot) 'musubi-api' }
$ApiPath = (Resolve-Path -LiteralPath $ApiPath).Path
$project = Join-Path $ApiPath 'Musubi.Api/Musubi.Api.csproj'
if (-not (Test-Path -LiteralPath $project)) {
    Write-Output ('integration: FAIL (no encuentro {0})' -f $project)
    exit 1
}

$outDir = Join-Path $repoRoot 'build/integration'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$log = Join-Path $outDir 'api.log'
$errLog = Join-Path $outDir 'api.err.log'
$coverage = Join-Path $outDir 'coverage'
foreach ($f in @($log, $errLog, $coverage)) { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Recurse -Force } }

if (-not $NoBuild) {
    & dotnet build $project -c Release --nologo -v quiet
    if ($LASTEXITCODE -ne 0) { Write-Output 'integration: FAIL (no compila musubi-api)'; exit 1 }
}

$key = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($key)
$url = 'http://localhost:{0}' -f $Port
$env:ASPNETCORE_ENVIRONMENT = 'Development'
$env:ASPNETCORE_URLS = $url
$env:UseInMemoryDatabase = 'true'
$env:Admin__Emails__0 = 'admin.integracion@uttt.edu.mx'
$env:Payments__EncryptionKey = [Convert]::ToBase64String($key)
# Muchas cuentas desde la misma IP: el limite de /auth se prueba en musubi-api/SecurityTest.
$env:RateLimiting__Auth__PermitLimit = '10000'
$env:RateLimiting__Uploads__PermitLimit = '10000'
$env:RateLimiting__Chat__PermitLimit = '10000'
$env:RateLimiting__Reports__PermitLimit = '10000'
$env:Firebase__Provider = 'InMemory'
$env:GenAi__Provider = 'InMemory'

# El DLL directo (no `dotnet run`): asi detener el proceso detiene la API, sin hijos huerfanos.
$apiDir = Join-Path $ApiPath 'Musubi.Api'
$dll = Join-Path $apiDir 'bin/Release/net10.0/Musubi.Api.dll'
$api = Start-Process -FilePath 'dotnet' -PassThru -NoNewWindow -WorkingDirectory $apiDir `
    -ArgumentList @($dll) -RedirectStandardOutput $log -RedirectStandardError $errLog

$exit = 1
try {
    $ready = $false
    for ($i = 0; $i -lt 120; $i++) {
        try {
            $r = Invoke-WebRequest -Uri ($url + '/health/ready') -UseBasicParsing -TimeoutSec 2
            if ($r.StatusCode -eq 200) { $ready = $true; break }
        }
        catch { Start-Sleep -Milliseconds 500 }
    }
    if (-not $ready) { Write-Output 'integration: FAIL (la API no respondio /health/ready)'; Get-Content -LiteralPath $log -Tail 40; exit 1 }

    Push-Location $repoRoot
    try {
        & flutter test $Tests --reporter expanded `
            ('--dart-define=MUSUBI_API_URL={0}' -f $url) `
            ('--dart-define=MUSUBI_API_LOG={0}' -f $log) `
            ('--dart-define=MUSUBI_API_COVERAGE={0}' -f $coverage)
        $exit = $LASTEXITCODE
        if ($exit -eq 0 -and -not $SkipCoverage) {
            & dart run tool/check_integration_coverage.dart (Join-Path $ApiPath 'docs/endpoints.md') $coverage
            $exit = $LASTEXITCODE
        }
    }
    finally { Pop-Location }
}
finally {
    if (-not $api.HasExited) { Stop-Process -Id $api.Id -Force }
}

if ($exit -ne 0) { Write-Output ('integration: FAIL (exit {0}; log de la API en {1})' -f $exit, $log) }
else { Write-Output 'integration: OK' }
exit $exit
