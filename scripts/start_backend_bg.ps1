# FinSight AI - Background Backend Starter & Health Verifier
$ErrorActionPreference = "SilentlyContinue"

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) {
    $projectRoot = "d:\FINSIGHT_AI"
}

$backendDir = Join-Path $projectRoot "backend"
$pythonExe = Join-Path $projectRoot ".venv\Scripts\python.exe"

if (-not (Test-Path $pythonExe)) {
    $pythonExe = "python"
}

Write-Host "[FinSight] Checking backend status on http://127.0.0.1:8000..." -ForegroundColor Cyan

# Check if backend is already responding
$isRunning = $false
try {
    $test = Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/health" -TimeoutSec 2 -UseBasicParsing
    if ($test.StatusCode -eq 200) {
        $isRunning = $true
    }
} catch {
    try {
        $testRoot = Invoke-WebRequest -Uri "http://127.0.0.1:8000/" -TimeoutSec 2 -UseBasicParsing
        if ($testRoot.StatusCode -eq 200) {
            $isRunning = $true
        }
    } catch {}
}

if ($isRunning) {
    Write-Host "[FinSight] Backend is already active and healthy on port 8000." -ForegroundColor Green
} else {
    Write-Host "[FinSight] Launching FastAPI backend server via $pythonExe..." -ForegroundColor Yellow
    
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $pythonExe
    $startInfo.Arguments = "-m uvicorn app.main:app --host 0.0.0.0 --port 8000"
    $startInfo.WorkingDirectory = $backendDir
    $startInfo.UseShellExecute = $true
    $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $null = [System.Diagnostics.Process]::Start($startInfo)

    # Poll until ready (up to 15 seconds)
    $ready = $false
    for ($i = 1; $i -le 15; $i++) {
        Start-Sleep -Milliseconds 1000
        try {
            $check = Invoke-WebRequest -Uri "http://127.0.0.1:8000/" -TimeoutSec 2 -UseBasicParsing
            if ($check.StatusCode -eq 200) {
                $ready = $true
                break
            }
        } catch {}
        Write-Host "[FinSight] Waiting for backend to initialize... ($i/15)" -ForegroundColor DarkGray
    }

    if ($ready) {
        Write-Host "[FinSight] Backend initialized successfully on http://127.0.0.1:8000!" -ForegroundColor Green
    } else {
        Write-Host "[FinSight] Warning: Backend took longer than expected to report healthy, continuing anyway." -ForegroundColor Yellow
    }
}

# Auto-configure reverse port forwarding for any connected Android devices or emulators
if (Get-Command "adb" -ErrorAction SilentlyContinue) {
    try {
        adb reverse tcp:8000 tcp:8000 2>$null
        Write-Host "[FinSight] Android ADB reverse port 8000 forwarded." -ForegroundColor Cyan
    } catch {}
}

exit 0
