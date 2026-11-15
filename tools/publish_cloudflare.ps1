param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^https://[a-z0-9-]+\.trycloudflare\.com$')]
    [string]$ApiOrigin,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskPackage = Join-Path $taskRoot 'infrastructure/cloudflare'
$taskArtifacts = Join-Path $taskRoot 'artifacts'
$taskStatePath = Join-Path $taskArtifacts 'cloudflare-worker.json'
$taskWrangler = Join-Path $taskPackage 'node_modules/.bin/wrangler.cmd'
$env:WRANGLER_SEND_METRICS = 'false'
Push-Location $taskPackage
try {
    if (-not (Get-Command node -ErrorAction SilentlyContinue) -or -not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
        throw 'Node.js 22.12+ is required for Cloudflare publishing. Install Node.js, then retry -Cloudflare.'
    }
    if (-not (Test-Path -LiteralPath $taskWrangler)) {
        & npm.cmd ci --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) { throw 'Could not install the pinned official Cloudflare Wrangler CLI.' }
    }
    $taskConfig = Get-Content -LiteralPath 'wrangler.jsonc' -Raw | ConvertFrom-Json
    if ($taskConfig.name -ne 'myhome' -or $taskConfig.account_id -ne '191dfbad351e265b9f10d46ec543e5fd') {
        throw 'The configured Worker/account does not match the requested MyHome deployment.'
    }
    foreach ($taskRequired in @('share-web/index.html', 'share-web/main.dart.js', 'share-web.fingerprint')) {
        if (-not (Test-Path -LiteralPath (Join-Path $taskArtifacts $taskRequired))) {
            throw 'The Web build is missing. Start with Deploy_Cloudflare.cmd or Start_MyHome.cmd -Cloudflare.'
        }
    }
    # Publish only the small gateway. Flutter files stay on the isolated demo-web
    # service; the Worker forwards both Web and API to that controlled origin.
    # The Worker is a gateway: updating Flutter files needs no Worker upload.
    $taskInputs = @($ApiOrigin)
    foreach ($taskFile in @('wrangler.jsonc', 'package-lock.json', 'src/worker.js')) {
        $taskInputs += (Get-FileHash -LiteralPath $taskFile -Algorithm SHA256).Hash
    }
    $taskHasher = [Security.Cryptography.SHA256]::Create()
    try { $taskFingerprint = [BitConverter]::ToString($taskHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($taskInputs -join "`n")))) }
    finally { $taskHasher.Dispose() }
    if (-not $Force -and (Test-Path -LiteralPath $taskStatePath)) {
        try {
            $taskPrevious = Get-Content -LiteralPath $taskStatePath -Raw | ConvertFrom-Json
            if ($taskPrevious.fingerprint -eq $taskFingerprint -and $taskPrevious.url -match '^https://myhome\.[a-z0-9-]+\.workers\.dev$') {
                $taskHealth = Invoke-RestMethod -Uri ($taskPrevious.url + '/api/v1/health') -TimeoutSec 10
                if ($taskHealth.status -eq 'ok') {
                    Write-Host ('Cloudflare Worker is up to date: ' + $taskPrevious.url)
                    return
                }
            }
        } catch { }
    }
    function Invoke-Wrangler {
        param([string[]]$Arguments, [string]$LogPath, [switch]$ShowOutput)
        $taskPriorPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $taskLines = [System.Collections.Generic.List[string]]::new()
        Set-Content -LiteralPath $LogPath -Value '' -Encoding UTF8
        try {
            for ($taskNetworkAttempt = 0; $taskNetworkAttempt -lt 2; $taskNetworkAttempt++) {
              & node '--import=./scripts/wrangler-network.mjs' (Join-Path $taskPackage 'node_modules/wrangler/bin/wrangler.js') @Arguments 2>&1 | ForEach-Object {
                $taskLine = if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { $_.ToString() }
                $taskLines.Add($taskLine)
                Add-Content -LiteralPath $LogPath -Value $taskLine -Encoding UTF8
                if ($ShowOutput) { Write-Host $taskLine }
            }
              $taskExit = $LASTEXITCODE
              if ($taskExit -eq 0 -or $taskNetworkAttempt -gt 0 -or ($taskLines -join "`n") -notmatch 'fetch failed|CONNECT_TIMEOUT|ECONNRESET|ETIMEDOUT') { break }
              Write-Host 'Temporary Cloudflare connection failure; retrying once...'
              Start-Sleep -Seconds 2
            }
        } finally { $ErrorActionPreference = $taskPriorPreference }
        if ($taskExit -ne 0) {
            throw "Cloudflare command failed. See $LogPath. If your session expired, run infrastructure/cloudflare/node_modules/.bin/wrangler.cmd login."
        }
        return ($taskLines -join "`n")
    }
    # Retain the previous deployment IDs for rollback before every actual publish.
    $taskBackupPath = Join-Path $taskArtifacts ('cloudflare-versions-before-' + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + '.json')
    $null = Invoke-Wrangler -Arguments @('versions', 'list', '--json') -LogPath $taskBackupPath
    $taskDeployLog = Join-Path $taskArtifacts 'cloudflare-deploy.log'
    $taskOutput = Invoke-Wrangler -Arguments @('deploy', '--var', "API_ORIGIN:$ApiOrigin", '--message', 'MyHome web and local demo API sync') -LogPath $taskDeployLog -ShowOutput
    $taskMatches = [regex]::Matches($taskOutput, 'https://myhome\.[a-z0-9-]+\.workers\.dev')
    if ($taskMatches.Count -eq 0) { throw 'Deployment did not report the expected myhome workers.dev address; inspect artifacts/cloudflare-deploy.log.' }
    $taskUrl = $taskMatches[$taskMatches.Count - 1].Value
    $taskReady = $false
    for ($taskAttempt = 0; $taskAttempt -lt 30; $taskAttempt++) {
        try {
            $taskHealth = Invoke-RestMethod -Uri ($taskUrl + '/api/v1/health') -TimeoutSec 5
            if ($taskHealth.status -eq 'ok') { $taskReady = $true; break }
        } catch { }
        if ($taskAttempt % 5 -eq 4) { Write-Host 'Waiting for the Worker deployment to reach the public API...' }
        Start-Sleep -Seconds 2
    }
    if (-not $taskReady) { throw "Worker deployed but its API health check did not pass yet: $taskUrl . Keep Docker/local demo running and inspect the deployment log." }
    @{
        account_id=$taskConfig.account_id; worker=$taskConfig.name; url=$taskUrl; api_origin=$ApiOrigin
        fingerprint=$taskFingerprint; published_at=[DateTimeOffset]::UtcNow.ToString('o'); rollback_inventory=$taskBackupPath
    } | ConvertTo-Json | Set-Content -LiteralPath $taskStatePath -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $taskArtifacts 'project-url.txt') -Value $taskUrl -Encoding ASCII
    Write-Host ('Verified Cloudflare project URL: ' + $taskUrl) -ForegroundColor Green
} finally { Pop-Location }
