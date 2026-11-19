#Requires -Version 5.1
<#
.SYNOPSIS
  Pruebas de integracion de la app contra musubi-api real (02-10, SCRUM-120).
.DESCRIPTION
  1. Compila y levanta musubi-api en Development en http://localhost:<Port> (MusubiLocalApi.ps1).
  2. Corre test/integration con los proveedores reales de la app (--dart-define MUSUBI_API_*).
  3. Corre tool/check_integration_coverage.dart: cada fila de docs/endpoints.md que consume musubi-app
     tiene que haberse llamado en alguna prueba.
  4. Detiene la API (siempre). El log queda en build/integration/api.log.
  En un telefono fisico: scripts/run_device_tests.ps1.
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
. (Join-Path $PSScriptRoot 'MusubiLocalApi.ps1')
$repoRoot = Split-Path -Parent $PSScriptRoot
$ApiPath = Resolve-MusubiApiPath $ApiPath $repoRoot

$outDir = Join-Path $repoRoot 'build/integration'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$log = Join-Path $outDir 'api.log'
$coverage = Join-Path $outDir 'coverage'
foreach ($f in @($log, ($log + '.err'), $coverage)) { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Recurse -Force } }

$api = Start-MusubiLocalApi -ApiPath $ApiPath -Port $Port -Log $log -NoBuild:$NoBuild
$exit = 1
try {
    Push-Location $repoRoot
    try {
        & flutter test $Tests --reporter expanded `
            ('--dart-define=MUSUBI_API_URL=http://localhost:{0}' -f $Port) `
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
finally { Stop-MusubiLocalApi $api }

if ($exit -ne 0) { Write-Output ('integration: FAIL (exit {0}; log de la API en {1})' -f $exit, $log) }
else { Write-Output 'integration: OK' }
exit $exit
