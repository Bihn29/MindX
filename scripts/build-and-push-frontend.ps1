# PowerShell script to build and push React frontend Docker image to Azure Container Registry
# Usage: .\scripts\build-and-push-frontend.ps1 -AcrName <acr-name> -ImageName <image-name> -Tag <tag>

param(
    [Parameter(Mandatory=$false)]
    [string]$AcrName = "myregistry",
    
    [Parameter(Mandatory=$false)]
    [string]$ImageName = "week1-frontend",
    
    [Parameter(Mandatory=$false)]
    [string]$Tag = "latest"
)

$ErrorActionPreference = "Stop"

$AcrLoginServer = "${AcrName}.azurecr.io"
$FullImageName = "${AcrLoginServer}/${ImageName}:${Tag}"

Write-Host "🔨 Building Docker image..." -ForegroundColor Cyan
Set-Location frontend
docker build -t ${ImageName}:${Tag} .

Write-Host "🏷️  Tagging image for ACR..." -ForegroundColor Cyan
docker tag "${ImageName}:${Tag}" $FullImageName

Write-Host "🔐 Logging in to Azure Container Registry..." -ForegroundColor Cyan
az acr login --name $AcrName

Write-Host "📤 Pushing image to ACR..." -ForegroundColor Cyan
docker push $FullImageName

Write-Host "✅ Successfully pushed $FullImageName" -ForegroundColor Green
Write-Host "📋 Image details:" -ForegroundColor Cyan
az acr repository show-tags --name $AcrName --repository $ImageName --output table

Set-Location ..

