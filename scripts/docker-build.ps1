# PowerShell script to build Docker images for backend and frontend
# Usage: .\scripts\docker-build.ps1 [tag]

param(
    [Parameter(Mandatory=$false)]
    [string]$Tag = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "🔨 Building Docker images with tag: $Tag" -ForegroundColor Cyan
Write-Host ""

# Build backend
Write-Host "📦 Building backend image..." -ForegroundColor Yellow
Set-Location backend
docker build -t "week1-backend:$Tag" .
Set-Location ..

# Build frontend
Write-Host "📦 Building frontend image..." -ForegroundColor Yellow
Set-Location frontend
docker build -t "week1-frontend:$Tag" .
Set-Location ..

Write-Host ""
Write-Host "✅ Build complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Images created:" -ForegroundColor Cyan
Write-Host "   - week1-backend:$Tag"
Write-Host "   - week1-frontend:$Tag"
Write-Host ""
Write-Host "🚀 To run with Docker Compose:" -ForegroundColor Yellow
Write-Host "   docker-compose up -d"

