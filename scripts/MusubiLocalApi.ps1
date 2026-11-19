#Requires -Version 5.1
<#
.SYNOPSIS
  musubi-api local para las pruebas (02-10, SCRUM-120). Se carga con: . "$PSScriptRoot/MusubiLocalApi.ps1"
.DESCRIPTION
  Start-MusubiLocalApi compila y levanta musubi-api en Development (en memoria, correo en el log) y espera
  /health/ready. La llave de pagos se genera al vuelo (32 bytes aleatorios): no es un secreto y muere con el
  proceso. Stop-MusubiLocalApi la detiene. Lo usan run_integration_tests.ps1 y run_device_tests.ps1.
  Compatible con PowerShell 5.1 y pwsh. ASCII puro.
#>

function Resolve-MusubiApiPath([string]$ApiPath, [string]$RepoRoot) {
    if ($ApiPath -eq '') { $ApiPath = Join-Path (Split-Path -Parent $RepoRoot) 'musubi-api' }
    $resolved = (Resolve-Path -LiteralPath $ApiPath).Path
    if (-not (Test-Path -LiteralPath (Join-Path $resolved 'Musubi.Api/Musubi.Api.csproj'))) {
        throw ('No encuentro musubi-api en {0}' -f $resolved)
    }
    return $resolved
}

function Start-MusubiLocalApi {
    param(
        [Parameter(Mandatory = $true)][string]$ApiPath,
        [Parameter(Mandatory = $true)][int]$Port,
        [Parameter(Mandatory = $true)][string]$Log,
        [switch]$NoBuild
    )
    $project = Join-Path $ApiPath 'Musubi.Api/Musubi.Api.csproj'
    if (-not $NoBuild) {
        & dotnet build $project -c Release --nologo -v quiet
        if ($LASTEXITCODE -ne 0) { throw 'No compila musubi-api' }
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
        -ArgumentList @($dll) -RedirectStandardOutput $Log -RedirectStandardError ($Log + '.err')

    for ($i = 0; $i -lt 120; $i++) {
        try {
            $r = Invoke-WebRequest -Uri ($url + '/health/ready') -UseBasicParsing -TimeoutSec 2
            if ($r.StatusCode -eq 200) { return $api }
        }
        catch { Start-Sleep -Milliseconds 500 }
    }
    Stop-MusubiLocalApi $api
    Get-Content -LiteralPath $Log -Tail 40
    throw 'La API no respondio /health/ready'
}

function Stop-MusubiLocalApi($Process) {
    if ($null -ne $Process -and -not $Process.HasExited) { Stop-Process -Id $Process.Id -Force }
}
