# PowerShell script to deploy API to AKS
# Usage: .\scripts\deploy-to-aks.ps1 -AcrName <acr-name>

param(
    [Parameter(Mandatory=$false)]
    [string]$AcrName = "myregistry"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrEmpty($AcrName)) {
    Write-Host "Error: ACR name is required" -ForegroundColor Red
    Write-Host "Usage: .\scripts\deploy-to-aks.ps1 -AcrName <acr-name>"
    exit 1
}

Write-Host "📝 Updating Kubernetes manifests with ACR name..." -ForegroundColor Cyan
$content = Get-Content k8s/backend-deployment.yaml -Raw
$content = $content -replace '<ACR_NAME>', $AcrName
Set-Content -Path k8s/backend-deployment.yaml -Value $content

Write-Host "🚀 Deploying Backend to AKS..." -ForegroundColor Cyan
kubectl apply -f k8s/backend-deployment.yaml

Write-Host "⏳ Waiting for deployment to be ready..." -ForegroundColor Cyan
kubectl wait --for=condition=available --timeout=300s deployment/backend-deployment

Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Deployment status:" -ForegroundColor Cyan
kubectl get deployments
kubectl get pods -l app=backend
kubectl get services -l app=backend

Write-Host ""
Write-Host "🔍 To test the Backend, use port-forwarding:" -ForegroundColor Yellow
Write-Host "   kubectl port-forward service/backend-service 3000:3000"
Write-Host "   curl http://localhost:3000/health"

