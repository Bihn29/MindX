# PowerShell script to deploy application with HTTPS on AKS
# Usage: .\scripts\deploy-https.ps1 -AcrName <acr-name> -DomainName <domain> -Email <email>

param(
    [Parameter(Mandatory=$true)]
    [string]$AcrName,
    
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    
    [Parameter(Mandatory=$true)]
    [string]$Email
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting HTTPS deployment..." -ForegroundColor Cyan
Write-Host "ACR Name: $AcrName" -ForegroundColor Yellow
Write-Host "Domain: $DomainName" -ForegroundColor Yellow
Write-Host "Email: $Email" -ForegroundColor Yellow
Write-Host ""

# Step 1: Update manifests with ACR name
Write-Host "📝 Updating manifests with ACR name..." -ForegroundColor Cyan
$backendContent = Get-Content k8s/backend-deployment.yaml -Raw
$backendContent = $backendContent -replace '<ACR_NAME>', $AcrName
Set-Content -Path k8s/backend-deployment.yaml -Value $backendContent

$frontendContent = Get-Content k8s/react-deployment.yaml -Raw
$frontendContent = $frontendContent -replace '<ACR_NAME>', $AcrName
Set-Content -Path k8s/react-deployment.yaml -Value $frontendContent

# Step 2: Update cert-manager with email
Write-Host "📝 Updating cert-manager with email..." -ForegroundColor Cyan
$certManagerContent = Get-Content k8s/cert-manager.yaml -Raw
$certManagerContent = $certManagerContent -replace '<your-email@example.com>', $Email
Set-Content -Path k8s/cert-manager.yaml -Value $certManagerContent

# Step 3: Update ingress-https with domain
Write-Host "📝 Updating ingress-https with domain..." -ForegroundColor Cyan
$ingressContent = Get-Content k8s/ingress-https.yaml -Raw
$ingressContent = $ingressContent -replace '<your-domain.com>', $DomainName
Set-Content -Path k8s/ingress-https.yaml -Value $ingressContent

# Step 4: Deploy backend and frontend
Write-Host "🚀 Deploying backend and frontend..." -ForegroundColor Cyan
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/react-deployment.yaml

# Step 5: Apply cert-manager ClusterIssuer
Write-Host "🔐 Applying cert-manager ClusterIssuer..." -ForegroundColor Cyan
kubectl apply -f k8s/cert-manager.yaml

# Step 6: Apply HTTPS ingress
Write-Host "🌐 Applying HTTPS ingress..." -ForegroundColor Cyan
kubectl apply -f k8s/ingress-https.yaml

Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure DNS A record pointing to Ingress external IP:"
Write-Host "   kubectl get service ingress-nginx-controller -n ingress-nginx"
Write-Host ""
Write-Host "2. Wait for certificate to be issued (may take a few minutes):"
Write-Host "   kubectl get certificate"
Write-Host ""
Write-Host "3. Test HTTPS access:"
Write-Host "   curl -I https://$DomainName"
Write-Host ""
Write-Host "4. Get Redirect URI for admin:" -ForegroundColor Cyan
Write-Host "   https://$DomainName/auth/callback" -ForegroundColor Green

