#Requires -Version 5.1
<#
.SYNOPSIS
  critic-guardrails (musubi-app): checklist ligero pre-push y job `critic` del CI.
.DESCRIPTION
  Bloqueantes (exit 1):
    B1 marcador TODO en lib/, test/ o integration_test/ (usar NOTE (NN-NN) o NOTE (HU-NN)).
    B2 secretos en el codigo o en el CI: llaves privadas PEM, tokens con prefijos conocidos
       (AIza, APP_USR-, TEST-<digitos>-, sk-, ghp_, github_pat_, AKIA, xox?-) y --dart-define /
       String.fromEnvironment con nombres SECRET|KEY|TOKEN (lo que va en el APK es publico).
    B3 "http://" en lib/ (la URL de dev vive en config/*.json; fuera de dev, HTTPS - RNF-02).
    B4 catch vacio o que se traga la excepcion en lib/ (sin usar la variable, sin rethrow/throw).
  Ambito: diff contra origin/main + cambios locales + untracked. Si no existe origin/main
  (repo nuevo), analiza todos los archivos versionados + untracked.
  Compatible con PowerShell 5.1 y pwsh (sin ?. / ?? / -Parallel). ASCII puro.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)

$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

# powershell-quirks: stderr de git + EAP=Stop = terminating aunque haya 2>$null.
function Invoke-Git {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        return @(git @args 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
    } finally {
        $ErrorActionPreference = $prev
    }
}

function Test-OriginMain {
    $remotes = Invoke-Git remote
    if ($remotes -contains 'origin') {
        Invoke-Git fetch origin main | Out-Null
    }
    $null = Invoke-Git rev-parse --verify --quiet 'origin/main'
    return ($LASTEXITCODE -eq 0)
}

$hasBase = Test-OriginMain

function Get-ScopeFiles {
    $all = @()
    if ($hasBase) {
        $all += Invoke-Git diff --name-only 'origin/main...HEAD'
        $all += Invoke-Git diff --name-only HEAD
    } else {
        $all += Invoke-Git ls-files
    }
    $all += Invoke-Git ls-files --others --exclude-standard
    return @($all | Where-Object { $_ -and $_.Trim() -ne '' } | Select-Object -Unique)
}

# Devuelve el cuerpo de un bloque { ... } que empieza en $start (indice de la llave de apertura).
function Get-BlockBody([string]$text, [int]$start) {
    $depth = 0
    for ($k = $start; $k -lt $text.Length; $k++) {
        $c = $text[$k]
        if ($c -eq '{') { $depth++ }
        elseif ($c -eq '}') {
            $depth--
            if ($depth -eq 0) { return $text.Substring($start + 1, $k - $start - 1) }
        }
    }
    return $text.Substring($start + 1)
}

function Get-LineNumber([string]$text, [int]$index) {
    return ([regex]::Matches($text.Substring(0, $index), "`n")).Count + 1
}

$files = @(Get-ScopeFiles | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
if ($files.Count -eq 0) {
    Write-Host 'critic: sin archivos en el ambito - PASS'
    exit 0
}

$selfDefinitions = @('scripts/critic-guardrails.ps1', '.semgrep/semgrep.yaml', '.claude/hooks/readonly-git-guard.ps1')
$secretScanExt = @('.dart', '.yml', '.yaml', '.json', '.kts', '.gradle', '.properties', '.xml', '.ps1', '.sh', '.env', '.txt')
$secretPatterns = @(
    @{ Name = 'llave privada PEM'; Regex = '-----BEGIN [A-Z ]*PRIVATE KEY-----' },
    @{ Name = 'API key de Google/Firebase (AIza)'; Regex = 'AIza[0-9A-Za-z_\-]{35}' },
    @{ Name = 'access token de Mercado Pago (APP_USR-)'; Regex = 'APP_USR-[0-9A-Za-z\-]{20,}' },
    @{ Name = 'token de pruebas de Mercado Pago (TEST-)'; Regex = 'TEST-\d{10,}-' },
    @{ Name = 'llave de proveedor de IA (sk-)'; Regex = '\bsk-[A-Za-z0-9_\-]{20,}' },
    @{ Name = 'token de GitHub'; Regex = '\b(ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,})' },
    @{ Name = 'access key de AWS (AKIA)'; Regex = '\bAKIA[0-9A-Z]{16}\b' },
    @{ Name = 'token de Slack'; Regex = '\bxox[abprs]-[A-Za-z0-9\-]{10,}' },
    @{ Name = '--dart-define con nombre sensible'; Regex = '--dart-define[= ]"?[A-Za-z0-9_]*(SECRET|KEY|TOKEN)[A-Za-z0-9_]*=' },
    @{ Name = 'String.fromEnvironment con nombre sensible (queda en el APK)'; Regex = 'fromEnvironment\(\s*[''"][A-Za-z0-9_]*(SECRET|KEY|TOKEN)[A-Za-z0-9_]*[''"]' },
    @{ Name = 'clave sensible en config de ambiente'; Regex = '"[A-Za-z0-9_]*(SECRET|KEY|TOKEN)[A-Za-z0-9_]*"\s*:' }
)

foreach ($f in $files) {
    $path = $f -replace '\\', '/'
    if ($selfDefinitions -contains $path) { continue }
    $ext = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
    $isDartSource = $ext -eq '.dart' -and $path -match '^(lib|test|integration_test)/'
    $lines = @(Get-Content -LiteralPath $f)

    # B1: TODO en comentarios del codigo Dart (el analyzer tambien lo trata como error: todo: error).
    if ($isDartSource) {
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -cmatch '(//|/\*).*\bTODO\b') {
                $failures.Add("${path}:$($i + 1) B1 marcador TODO (usar NOTE (NN-NN) o NOTE (HU-NN))")
            }
        }
    }

    # B2: secretos en codigo, configuracion o CI.
    if ($secretScanExt -contains $ext -or $path -match '^\.github/') {
        for ($i = 0; $i -lt $lines.Count; $i++) {
            foreach ($p in $secretPatterns) {
                if ($lines[$i] -cmatch $p.Regex) {
                    $failures.Add("${path}:$($i + 1) B2 posible secreto: $($p.Name)")
                }
            }
        }
    }

    if ($ext -eq '.dart' -and $path -match '^lib/') {
        # B3: http:// en lib/.
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match 'http://') {
                $failures.Add("${path}:$($i + 1) B3 'http://' en lib/ (usar config/*.json; HTTPS fuera de dev)")
            }
        }

        # B4: catch vacio o que se traga la excepcion.
        $text = [string]::Join("`n", $lines)
        foreach ($m in [regex]::Matches($text, '(?:on\s+[\w<>.,\s]+?\s+)?catch\s*\(\s*(\w+)\s*(?:,\s*(\w+)\s*)?\)\s*\{')) {
            $var = $m.Groups[1].Value
            $body = Get-BlockBody $text ($m.Index + $m.Length - 1)
            $code = [regex]::Replace($body, '//[^\n]*', '').Trim()
            $line = Get-LineNumber $text $m.Index
            if ($code -eq '') {
                $failures.Add("${path}:$line B4 catch vacio (traga la excepcion)")
            } elseif ($code -notmatch '\brethrow\b' -and $code -notmatch '\bthrow\b' -and ($var -eq '_' -or $code -notmatch ('\b' + [regex]::Escape($var) + '\b'))) {
                $failures.Add("${path}:$line B4 catch que ignora la excepcion (usar la variable, mapearla o rethrow)")
            }
        }
        foreach ($m in [regex]::Matches($text, '\bon\s+[\w<>.]+\s*\{')) {
            $body = Get-BlockBody $text ($m.Index + $m.Length - 1)
            if ([regex]::Replace($body, '//[^\n]*', '').Trim() -eq '') {
                $failures.Add("${path}:$(Get-LineNumber $text $m.Index) B4 'on X {}' vacio (traga la excepcion)")
            }
        }
    }

    # A1: NOTE sin ID.
    if ($isDartSource) {
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -cmatch '\bNOTE\b' -and $lines[$i] -notmatch 'NOTE\s*\(((musubi-api:)?\d{2}-\d{2}|(musubi-api:)?HU-\d{2})\)') {
                $warnings.Add("${path}:$($i + 1) A1 NOTE sin ID de spec duena")
            }
        }
    }
}

foreach ($w in $warnings) { Write-Host "WARN $w" }
$scope = 'diff vs origin/main'
if (-not $hasBase) { $scope = 'repo completo (sin origin/main)' }
if ($failures.Count -gt 0) {
    foreach ($e in $failures) { Write-Host "FAIL $e" }
    Write-Host ("critic: FAIL ({0} bloqueantes, {1} avisos; ambito: {2})" -f $failures.Count, $warnings.Count, $scope)
    exit 1
}
Write-Host ("critic: PASS ({0} archivos analizados, {1} avisos; ambito: {2})" -f $files.Count, $warnings.Count, $scope)
exit 0
