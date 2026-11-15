param(
    [switch]$Local,
    [switch]$Stop,
    [switch]$Rebuild,
    [switch]$Android,
    [switch]$NoBrowser
)

$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskArtifacts = Join-Path $taskRoot 'artifacts'
[void][IO.Directory]::CreateDirectory($taskArtifacts)
$taskTranscript = $false
Push-Location $taskRoot
try {
    Start-Transcript -Path (Join-Path $taskArtifacts 'launcher.log') -Append | Out-Null
    $taskTranscript = $true
    if ($Android -and $Local -and -not $Stop) { throw 'Use -Android without -Local so the phone gets a reachable HTTPS API.' }

    function Invoke-Checked {
        param([string]$Command, [string[]]$Arguments)
        & $Command @Arguments
        if ($LASTEXITCODE -ne 0) { throw "Command failed: $Command (exit $LASTEXITCODE). See artifacts/launcher.log." }
    }

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw 'Docker Desktop is required. Install it, then run Start_MyHome.cmd again.'
    }
    $taskDockerReady = $false
    try { $taskDockerReady = [bool](& docker info --format '{{.ServerVersion}}' 2>$null) } catch { }
    if (-not $taskDockerReady -and $Stop) {
        Write-Host 'Docker is stopped. No active demo sharing to stop.'
        return
    }
    if (-not $taskDockerReady) {
        $taskDesktop = @(
            (Join-Path $env:LOCALAPPDATA 'Programs/DockerDesktop/Docker Desktop.exe'),
            (Join-Path $env:ProgramFiles 'Docker/Docker/Docker Desktop.exe')
        ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if (-not $taskDesktop) { throw 'Open Docker Desktop, then run Start_MyHome.cmd again.' }
        Write-Host 'Starting Docker Desktop. Waiting for the Linux engine...'
        Start-Process -FilePath $taskDesktop -WindowStyle Hidden
        for ($taskAttempt = 0; $taskAttempt -lt 30; $taskAttempt++) {
            Start-Sleep -Seconds 2
            try { $taskDockerReady = [bool](& docker info --format '{{.ServerVersion}}' 2>$null) } catch { }
            if ($taskDockerReady) { break }
        }
        if (-not $taskDockerReady) { throw 'Docker is still starting. Wait until Docker Desktop is ready, then retry.' }
    }

    if ($Stop -and -not (Test-Path infrastructure/.env.demo)) {
        Write-Host 'No demo setup exists yet.'
        return
    }
    $taskCompose = @('compose', '--env-file', 'infrastructure/.env', '--env-file', 'infrastructure/.env.demo',
        '-f', 'infrastructure/compose.yaml', '-f', 'infrastructure/compose.demo.yaml', '-f', 'infrastructure/compose.share.yaml')
    function Invoke-Compose {
        param([string[]]$Arguments)
        Invoke-Checked -Command 'docker' -Arguments ($taskCompose + $Arguments)
    }
    if ($Stop) {
        Invoke-Compose -Arguments @('stop', 'demo-share', 'demo-web', 'demo-api')
        $taskUrlFile = Join-Path $taskArtifacts 'share-url.txt'
        if (Test-Path -LiteralPath $taskUrlFile) { Remove-Item -LiteralPath $taskUrlFile }
        $taskStateFile = Join-Path $taskArtifacts 'share-state.json'
        if (Test-Path -LiteralPath $taskStateFile) { Remove-Item -LiteralPath $taskStateFile }
        Write-Host 'Demo and public sharing stopped. Database data is preserved.' -ForegroundColor Green
        Write-Host 'PostgreSQL stays running because it may also serve the main API.'
        return
    }

    $taskPython = (Get-Command python -ErrorAction Stop).Source
    $taskFlutter = (Get-Command flutter -ErrorAction Stop).Source
    Invoke-Checked -Command $taskPython -Arguments @('tools/setup_local.py')
    Invoke-Checked -Command $taskPython -Arguments @('tools/setup_demo.py')
    $taskVenvPython = Join-Path $taskRoot 'backend_fastapi/.venv/Scripts/python.exe'
    if (-not (Test-Path -LiteralPath $taskVenvPython)) {
        Write-Host 'Preparing the Python environment (first run only)...'
        Invoke-Checked -Command $taskPython -Arguments @('-m', 'venv', 'backend_fastapi/.venv')
        Invoke-Checked -Command $taskVenvPython -Arguments @('-m', 'pip', 'install', '-r', 'backend_fastapi/requirements-dev.txt')
    }
    Write-Host 'Starting PostgreSQL...'
    Invoke-Compose -Arguments @('up', '-d', '--wait', '--wait-timeout', '60', 'postgres')
    Write-Host 'Starting the isolated demo API. Existing accounts and edits are retained...'
    Invoke-Checked -Command 'powershell.exe' -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
        (Join-Path $PSScriptRoot 'start_demo.ps1'), '-SeedIfEmpty')

    Push-Location (Join-Path $taskRoot 'myhome_flutter')
    try {
        Invoke-Checked -Command $taskFlutter -Arguments @('pub', 'get')
        # Cache only a successful build of exactly these inputs, with this Flutter version.
        $taskInputLines = @('API_BASE_URL=/api/v1')
        $taskVersion = (& $taskFlutter --version --machine | Out-String)
        if ($LASTEXITCODE -ne 0) { throw 'Flutter SDK could not start.' }
        $taskInputLines += $taskVersion
        $taskFiles = @(Get-ChildItem -LiteralPath 'lib', 'web', 'assets' -Recurse -File)
        $taskFiles += Get-Item -LiteralPath 'pubspec.yaml', 'pubspec.lock', 'l10n.yaml'
        foreach ($taskFile in ($taskFiles | Sort-Object FullName)) {
            $taskInputLines += $taskFile.FullName.Substring($taskRoot.Length) + ':' + (Get-FileHash -LiteralPath $taskFile.FullName -Algorithm SHA256).Hash
        }
        $taskHasher = [Security.Cryptography.SHA256]::Create()
        try { $taskFingerprint = [BitConverter]::ToString($taskHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($taskInputLines -join "`n")))) }
        finally { $taskHasher.Dispose() }
        $taskCache = Join-Path $taskArtifacts 'share-web.fingerprint'
        $taskOutput = Join-Path $taskArtifacts 'share-web'
        $taskCached = (Test-Path -LiteralPath $taskCache) -and
            (Test-Path -LiteralPath (Join-Path $taskOutput 'main.dart.js')) -and
            (Test-Path -LiteralPath (Join-Path $taskOutput 'index.html'))
        if ($taskCached) { $taskCached = (Get-Content -LiteralPath $taskCache -Raw).Trim() -eq $taskFingerprint }
        if ($Rebuild -or -not $taskCached) {
            Write-Host 'Building the shareable Web app. The first build can take a few minutes...'
            Invoke-Checked -Command $taskFlutter -Arguments @('build', 'web', '--release', '--dart-define=API_BASE_URL=/api/v1', "--output=$taskOutput")
            Set-Content -LiteralPath $taskCache -Value $taskFingerprint -Encoding ASCII
        } else { Write-Host 'Web build is up to date.' }
    } finally { Pop-Location }

    Write-Host 'Starting the single-origin Web/API gateway...'
    Invoke-Compose -Arguments @('up', '-d', '--wait', '--wait-timeout', '60', 'demo-web')
    $taskLocalUrl = 'http://localhost:8082'
    $taskOpenUrl = $taskLocalUrl
    if ($Local) {
        Invoke-Compose -Arguments @('stop', 'demo-share')
        $taskUrlFile = Join-Path $taskArtifacts 'share-url.txt'
        if (Test-Path -LiteralPath $taskUrlFile) { Remove-Item -LiteralPath $taskUrlFile }
        $taskStateFile = Join-Path $taskArtifacts 'share-state.json'
        if (Test-Path -LiteralPath $taskStateFile) { Remove-Item -LiteralPath $taskStateFile }
        Write-Host 'Local-only mode. Use this computer; run without -Local for a mobile/share HTTPS link.'
    } else {
        Write-Host 'Starting a temporary HTTPS link for mobile and external testers...'
        Invoke-Compose -Arguments @('up', '-d', 'demo-share')
        $taskShareContainer = (& docker @taskCompose ps -q demo-share | Out-String).Trim()
        $taskShareStarted = (& docker inspect --format '{{.State.StartedAt}}' $taskShareContainer | Out-String).Trim()
        $taskStateFile = Join-Path $taskArtifacts 'share-state.json'
        $taskPublicUrl = $null
        if (Test-Path -LiteralPath $taskStateFile) {
            try {
                $taskPreviousShare = Get-Content -LiteralPath $taskStateFile -Raw | ConvertFrom-Json
                if ($taskPreviousShare.container -eq $taskShareContainer -and $taskPreviousShare.started -eq $taskShareStarted -and
                    $taskPreviousShare.url -match '^https://[a-z0-9-]+\.trycloudflare\.com$') {
                    $taskPublicUrl = $taskPreviousShare.url
                }
            } catch { }
        }
        for ($taskAttempt = 0; $taskAttempt -lt 30 -and -not $taskPublicUrl; $taskAttempt++) {
            $taskTunnelLog = (& docker @taskCompose logs --no-color --since $taskShareStarted --tail 100 demo-share | Out-String)
            $taskMatches = [regex]::Matches($taskTunnelLog, 'https://[a-z0-9-]+\.trycloudflare\.com')
            if ($taskMatches.Count -gt 0) { $taskPublicUrl = $taskMatches[$taskMatches.Count - 1].Value; break }
            Start-Sleep -Seconds 2
        }
        if (-not $taskPublicUrl) { throw 'No HTTPS link was created. Run Start_MyHome.cmd -Local for desktop testing; check Docker demo-share logs and internet access.' }
        Write-Host "HTTPS link allocated: $taskPublicUrl"
        Write-Host 'Checking the public Web/API connection...'
        $taskPublicReady = $false
        for ($taskAttempt = 0; $taskAttempt -lt 10; $taskAttempt++) {
            try {
                $taskHealth = Invoke-RestMethod -Uri "$taskPublicUrl/api/v1/health" -TimeoutSec 5
                if ($taskHealth.status -eq 'ok') { $taskPublicReady = $true; break }
            } catch { }
            Start-Sleep -Seconds 1
        }
        if (-not $taskPublicReady) { throw "The tunnel link was allocated but could not reach the API yet: $taskPublicUrl . Check internet access or retry startup." }
        $taskOpenUrl = $taskPublicUrl
        Set-Content -LiteralPath (Join-Path $taskArtifacts 'share-url.txt') -Value $taskPublicUrl -Encoding ASCII
        @{container=$taskShareContainer; started=$taskShareStarted; url=$taskPublicUrl} | ConvertTo-Json | Set-Content -LiteralPath $taskStateFile -Encoding ASCII
        Write-Host ''
        Write-Host "MOBILE / SHARE: $taskPublicUrl" -ForegroundColor Green
        Write-Host 'Send that HTTPS link to your tester. Keep this PC and Docker running.'
        Write-Host 'This is a public demo link, accessible to anyone who has it.'
    }
    Write-Host "THIS COMPUTER: $taskLocalUrl" -ForegroundColor Cyan
    if ($Android) {
        Write-Host 'Building an Android debug APK connected to the current HTTPS demo link...'
        Push-Location (Join-Path $taskRoot 'myhome_flutter')
        try {
            Invoke-Checked -Command $taskFlutter -Arguments @('build', 'apk', '--debug', "--dart-define=API_BASE_URL=$taskOpenUrl/api/v1")
            Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-debug.apk' -Destination (Join-Path $taskArtifacts 'MyHome-demo.apk') -Force
        } finally { Pop-Location }
        Write-Host "ANDROID APK: $(Join-Path $taskArtifacts 'MyHome-demo.apk')" -ForegroundColor Green
        Write-Host 'Rebuild with -Android if you restart sharing and the HTTPS link changes.'
    }
    Write-Host "DEMO LOGINS:   $(Join-Path $taskArtifacts 'demo-accounts.json')"
    Write-Host 'Stop sharing with Stop_MyHome.cmd. Closing this window alone does not stop Docker.'
    if (-not $NoBrowser) { Start-Process -FilePath $taskOpenUrl }
} catch {
    Write-Host ''
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
} finally {
    if ($taskTranscript) { Stop-Transcript | Out-Null }
    Pop-Location
}
