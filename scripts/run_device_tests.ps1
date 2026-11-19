#Requires -Version 5.1
<#
.SYNOPSIS
  Suite automatizada en un telefono fisico (02-10, SCRUM-120): las pantallas reales contra musubi-api.
.DESCRIPTION
  Con el telefono conectado por USB (depuracion USB activa):
  1. Compila y levanta musubi-api en la PC (Development, en memoria) en http://localhost:<Port>.
  2. Levanta tool/device_code_server.dart en <CodePort>: el telefono le pide los codigos de verificacion
     que la API escribe en su log.
  3. adb reverse de los dos puertos: en el telefono, localhost:<Port> y localhost:<CodePort> son la PC.
  4. Corre integration_test/ en el telefono (flutter test -d <id>, build debug: solo debug permite HTTP
     hacia localhost).
  5. Deshace el adb reverse y detiene el servidor de codigos y la API (siempre).
  Compatible con PowerShell 5.1 y pwsh. ASCII puro.
.EXAMPLE
  pwsh scripts/run_device_tests.ps1                         # el primer telefono Android conectado
  pwsh scripts/run_device_tests.ps1 -Device R58N12ABCDE     # uno en particular (flutter devices)
#>
[CmdletBinding()]
param(
    [string]$ApiPath = '',
    [string]$Device = '',
    [int]$Port = 5080,
    [int]$CodePort = 5081,
    [string]$Tests = 'integration_test',
    [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'MusubiLocalApi.ps1')
$repoRoot = Split-Path -Parent $PSScriptRoot
$ApiPath = Resolve-MusubiApiPath $ApiPath $repoRoot

$adb = 'adb'
if (-not (Get-Command $adb -ErrorAction SilentlyContinue)) {
    foreach ($sdk in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, (Join-Path $env:LOCALAPPDATA 'Android/Sdk'))) {
        if ($sdk -and (Test-Path -LiteralPath (Join-Path $sdk 'platform-tools'))) {
            $adb = Join-Path $sdk 'platform-tools/adb'
            break
        }
    }
}

if ($Device -eq '') {
    $attached = @(& $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '^(\S+)\s+device$' } | ForEach-Object { $Matches[1] })
    if ($attached.Count -eq 0) {
        Write-Output 'device: FAIL (no hay telefono conectado; activa la depuracion USB y acepta la huella de la PC)'
        exit 1
    }
    $Device = $attached[0]
}
Write-Output ('device: telefono {0}' -f $Device)

$outDir = Join-Path $repoRoot 'build/device'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$log = Join-Path $outDir 'api.log'
foreach ($f in @($log, ($log + '.err'))) { if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force } }

$api = Start-MusubiLocalApi -ApiPath $ApiPath -Port $Port -Log $log -NoBuild:$NoBuild
$codes = $null
$exit = 1
try {
    $codes = Start-Process -FilePath 'dart' -PassThru -NoNewWindow -WorkingDirectory $repoRoot `
        -ArgumentList @('tool/device_code_server.dart', $log, $CodePort) `
        -RedirectStandardOutput (Join-Path $outDir 'codes.log') -RedirectStandardError (Join-Path $outDir 'codes.err.log')
    & $adb -s $Device reverse ('tcp:{0}' -f $Port) ('tcp:{0}' -f $Port) | Out-Null
    & $adb -s $Device reverse ('tcp:{0}' -f $CodePort) ('tcp:{0}' -f $CodePort) | Out-Null

    Push-Location $repoRoot
    try {
        & flutter test $Tests -d $Device --reporter expanded `
            ('--dart-define=MUSUBI_API_URL=http://localhost:{0}' -f $Port) `
            ('--dart-define=MUSUBI_CODE_URL=http://localhost:{0}' -f $CodePort)
        $exit = $LASTEXITCODE
    }
    finally { Pop-Location }
}
finally {
    & $adb -s $Device reverse --remove ('tcp:{0}' -f $Port) 2>$null | Out-Null
    & $adb -s $Device reverse --remove ('tcp:{0}' -f $CodePort) 2>$null | Out-Null
    if ($null -ne $codes -and -not $codes.HasExited) { Stop-Process -Id $codes.Id -Force }
    Stop-MusubiLocalApi $api
}

if ($exit -ne 0) { Write-Output ('device: FAIL (exit {0}; log de la API en {1})' -f $exit, $log) }
else { Write-Output 'device: OK' }
exit $exit
