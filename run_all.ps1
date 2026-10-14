# =====================================================================
# FinSight AI - Full Stack Launcher (Backend + Frontend)
# =====================================================================

$projectRoot = $PSScriptRoot
if (-not $projectRoot) {
    $projectRoot = "d:\FINSIGHT_AI"
}

$backendDir = Join-Path $projectRoot "backend"
$frontendDir = Join-Path $projectRoot "frontend"
$pythonExe = Join-Path $projectRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
    $pythonExe = "python"
}

Clear-Host
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "          FinSight AI - Full Stack Launcher             " -ForegroundColor White
Write-Host "      FastAPI Engine (8000) + Flutter Application       " -ForegroundColor DarkCyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Start Backend in the background if not active
Write-Host "[1/3] Checking FastAPI Backend status..." -ForegroundColor Yellow
$backendRunning = $false
try {
    $test = Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
    if ($test.StatusCode -eq 200) { $backendRunning = $true }
} catch {
    try {
        $testRoot = Invoke-WebRequest -Uri "http://127.0.0.1:8000/" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
        if ($testRoot.StatusCode -eq 200) { $backendRunning = $true }
    } catch {}
}

$backendProcess = $null
if ($backendRunning) {
    Write-Host "  -> Backend is already active and listening on http://127.0.0.1:8000" -ForegroundColor Green
} else {
    Write-Host "  -> Launching backend server via $pythonExe..." -ForegroundColor DarkYellow
    $backendProcess = Start-Process -FilePath $pythonExe -ArgumentList "-m uvicorn app.main:app --host 0.0.0.0 --port 8000" -WorkingDirectory $backendDir -PassThru -WindowStyle Hidden
    
    $ready = $false
    for ($i = 1; $i -le 15; $i++) {
        Start-Sleep -Milliseconds 800
        try {
            $resp = Invoke-WebRequest -Uri "http://127.0.0.1:8000/" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
            if ($resp.StatusCode -eq 200) {
                $ready = $true
                break
            }
        } catch {}
        Write-Host "  -> Waiting for backend to start... ($i/15)" -ForegroundColor DarkGray
    }

    if ($ready) {
        Write-Host "  -> Backend ready at http://127.0.0.1:8000 (Process ID: $($backendProcess.Id))" -ForegroundColor Green
    } else {
        Write-Host "  -> Backend process started, continuing to launch frontend..." -ForegroundColor Yellow
    }
}

# Step 2: Android ADB reverse port forwarding (if device is plugged in)
Write-Host ""
Write-Host "[2/3] Checking mobile device connectivity..." -ForegroundColor Yellow
if (Get-Command "adb" -ErrorAction SilentlyContinue) {
    try {
        $devices = adb devices
        if ($devices -match "device\b") {
            adb reverse tcp:8000 tcp:8000 2>$null
            Write-Host "  -> Android device detected. Forwarded port 8000 via ADB reverse!" -ForegroundColor Green
        } else {
            Write-Host "  -> No Android device detected. Skipping ADB forwarding." -ForegroundColor DarkGray
        }
    } catch {}
} else {
    Write-Host "  -> ADB not found. Skipping mobile port bridge." -ForegroundColor DarkGray
}

# Step 3: Run Flutter
Write-Host ""
Write-Host "[3/3] Launching Flutter Application..." -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan
Push-Location $frontendDir
try {
    flutter run
} finally {
    Pop-Location
    Write-Host ""
    Write-Host "[FinSight] Frontend stopped." -ForegroundColor Cyan
}
