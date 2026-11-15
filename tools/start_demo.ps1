param([switch]$SeedIfEmpty)
# Run from the repository root. All synthetic data stays in myhome_demo.
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
Push-Location $taskRoot
try {
    python tools/setup_demo.py
    $taskSecrets = Get-Content infrastructure/.env -Raw | ConvertFrom-StringData
    $taskDemoSecrets = Get-Content infrastructure/.env.demo -Raw | ConvertFrom-StringData
    $taskCompose = @('compose','--env-file','infrastructure/.env','-f','infrastructure/compose.yaml')
    $taskExists = & docker @taskCompose exec -T postgres psql -U postgres -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='myhome_demo'"
    if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL must already be running; see README.' }
    if (($taskExists | Out-String).Trim() -ne '1') {
        & docker @taskCompose exec -T postgres createdb -U postgres myhome_demo
        if ($LASTEXITCODE -ne 0) { throw 'Could not create the isolated demo database.' }
    }
    & docker @taskCompose exec -T postgres psql -U postgres -d myhome_demo -v ON_ERROR_STOP=1 -c 'REVOKE CREATE ON SCHEMA public FROM PUBLIC; GRANT CONNECT ON DATABASE myhome_demo TO myhome; GRANT USAGE ON SCHEMA public TO myhome; ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO myhome;'
    if ($LASTEXITCODE -ne 0) { throw 'Could not configure demo runtime privileges.' }
    $taskDatabasePort = if ($taskSecrets.POSTGRES_PORT) { [int]$taskSecrets.POSTGRES_PORT } else { 55432 }
    $env:DATABASE_URL='postgresql://postgres:'+$taskSecrets.POSTGRES_PASSWORD+'@127.0.0.1:'+$taskDatabasePort+'/myhome_demo'
    $env:JWT_SECRET=$taskDemoSecrets.DEMO_JWT_SECRET
    $env:DOCUMENT_KEY=$taskDemoSecrets.DEMO_DOCUMENT_KEY
    $env:OCR_ENABLED='false'
    $env:COMMISSION_ENABLED='true'
    $env:RATE_LIMIT='1000'
    $env:STORAGE_PATH=Join-Path $taskRoot 'artifacts/demo-private-media'
    Push-Location backend_fastapi
    try {
        ./.venv/Scripts/python.exe -m alembic upgrade head
        if ($LASTEXITCODE -ne 0) { throw 'Demo migration failed.' }
        $taskShouldSeed = $true
        if ($SeedIfEmpty) {
            $taskExistingDemo = & ./.venv/Scripts/python.exe -c "from sqlalchemy import select; from sqlalchemy.orm import Session; from app.database import engine; from app.models import User; db=Session(engine()); print('present' if db.scalar(select(User.id).where(User.email=='demo-owner_all@example.com').limit(1)) else 'empty'); db.close()"
            if ($LASTEXITCODE -ne 0) { throw 'Could not inspect the demo database.' }
            $taskShouldSeed = ($taskExistingDemo | Out-String).Trim() -eq 'empty'
        }
        if ($taskShouldSeed) {
            ./.venv/Scripts/python.exe -m app.seed_demo
            if ($LASTEXITCODE -ne 0) { throw 'Demo scenario checks failed.' }
        } else {
            Write-Output 'Existing demo accounts/listings retained. Startup does not reset your changes.'
        }
    } finally { Pop-Location }
    & docker compose --env-file infrastructure/.env --env-file infrastructure/.env.demo -f infrastructure/compose.yaml -f infrastructure/compose.demo.yaml up -d --build --wait --wait-timeout 60 demo-api
    if ($LASTEXITCODE -ne 0) { throw 'Demo API startup failed.' }
    Write-Output 'Demo API: http://127.0.0.1:3001/api/v1. Credentials: artifacts/demo-accounts.json'
    Write-Output 'Flutter: flutter run -d chrome --web-port 8081 --dart-define=API_BASE_URL=http://localhost:3001/api/v1'
} finally { Pop-Location }
