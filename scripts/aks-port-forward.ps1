# AKS Port-Forward Testing Script
# Use this script to access AKS services locally when external IP is not publicly accessible

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('backend', 'frontend', 'all')]
    [string]$Service = 'all'
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  AKS Port-Forward Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verify kubectl connection
try {
    $context = kubectl config current-context
    Write-Host "✅ Connected to cluster: $context" -ForegroundColor Green
} catch {
    Write-Host "❌ Not connected to AKS cluster" -ForegroundColor Red
    Write-Host "Run: az aks get-credentials --resource-group mindx-intern-03-rg --name mindx-week1-aks" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

function Start-PortForward {
    param(
        [string]$ServiceName,
        [int]$LocalPort,
        [int]$RemotePort,
        [string]$DisplayName
    )
    
    Write-Host "🚀 Starting port-forward for $DisplayName..." -ForegroundColor Cyan
    Write-Host "   Local:  http://localhost:$LocalPort" -ForegroundColor White
    Write-Host "   Remote: $ServiceName`:$RemotePort`n" -ForegroundColor Gray
    
    # Start port-forward in background
    Start-Job -Name "pf-$ServiceName" -ScriptBlock {
        param($svc, $local, $remote)
        kubectl port-forward "svc/$svc" "${local}:${remote}" -n default
    } -ArgumentList $ServiceName, $LocalPort, $RemotePort | Out-Null
    
    Start-Sleep -Seconds 2
}

if ($Service -eq 'backend' -or $Service -eq 'all') {
    Start-PortForward -ServiceName "backend-service" -LocalPort 3000 -RemotePort 3000 -DisplayName "Backend API"
}

if ($Service -eq 'frontend' -or $Service -eq 'all') {
    Start-PortForward -ServiceName "react-app-service" -LocalPort 8080 -RemotePort 8080 -DisplayName "Frontend App"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Port-Forward Active" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

if ($Service -eq 'backend' -or $Service -eq 'all') {
    Write-Host "Backend API:" -ForegroundColor Yellow
    Write-Host "  http://localhost:3000/health" -ForegroundColor White
    Write-Host "  http://localhost:3000/api/info" -ForegroundColor White
    Write-Host "  http://localhost:3000/api/protected (requires auth)" -ForegroundColor White
    Write-Host ""
}

if ($Service -eq 'frontend' -or $Service -eq 'all') {
    Write-Host "Frontend App:" -ForegroundColor Yellow
    Write-Host "  http://localhost:8080" -ForegroundColor White
    Write-Host ""
}

Write-Host "Press Ctrl+C to stop port-forwarding`n" -ForegroundColor Gray
Write-Host "========================================`n" -ForegroundColor Cyan

# Test endpoints
if ($Service -eq 'backend' -or $Service -eq 'all') {
    Write-Host "Testing backend health..." -ForegroundColor Cyan
    Start-Sleep -Seconds 3
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:3000/health" -Method Get -TimeoutSec 10
        Write-Host "✅ Backend health check: " -NoNewline -ForegroundColor Green
        Write-Host $response.status -ForegroundColor White
    } catch {
        Write-Host "⚠️  Backend not ready yet, wait a moment..." -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($Service -eq 'frontend' -or $Service -eq 'all') {
    Write-Host "Testing frontend..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -Method Get -UseBasicParsing -TimeoutSec 10
        Write-Host "✅ Frontend status: " -NoNewline -ForegroundColor Green
        Write-Host $response.StatusCode -ForegroundColor White
    } catch {
        Write-Host "⚠️  Frontend not ready yet, wait a moment..." -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "========================================`n" -ForegroundColor Cyan

# Keep running
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    Write-Host "`n`nStopping port-forwards..." -ForegroundColor Yellow
    Get-Job -Name "pf-*" | Stop-Job
    Get-Job -Name "pf-*" | Remove-Job
    Write-Host "✅ Port-forwards stopped`n" -ForegroundColor Green
}
