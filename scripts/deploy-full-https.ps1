# Complete HTTPS Deployment Script for Azure AKS
# Usage: .\scripts\deploy-full-https.ps1 -AcrName <acr-name> -DomainName <domain> -Email <email> -ResourceGroup <rg> -AksCluster <cluster>

param(
    [Parameter(Mandatory=$true)]
    [string]$AcrName,
    
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    
    [Parameter(Mandatory=$true)]
    [string]$Email,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [string]$AksCluster,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipIngressInstall,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipCertManager,
    
    [Parameter(Mandatory=$false)]
    [switch]$BuildImages = $true
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HTTPS Deployment to Azure AKS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  ACR Name:        $AcrName" -ForegroundColor White
Write-Host "  Domain:          $DomainName" -ForegroundColor White
Write-Host "  Email:           $Email" -ForegroundColor White
Write-Host "  Resource Group:  $ResourceGroup" -ForegroundColor White
Write-Host "  AKS Cluster:     $AksCluster" -ForegroundColor White
Write-Host ""

# Step 0: Pre-flight checks
Write-Host "🔍 Running pre-flight checks..." -ForegroundColor Cyan

# Check Azure CLI
try {
    $azVersion = az version --query '\"azure-cli\"' -o tsv
    Write-Host "✅ Azure CLI: $azVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI not found. Please install: https://aka.ms/installazurecliwindows" -ForegroundColor Red
    exit 1
}

# Check kubectl
try {
    $kubectlVersion = kubectl version --client --short 2>$null
    Write-Host "✅ kubectl installed" -ForegroundColor Green
} catch {
    Write-Host "❌ kubectl not found. Please install: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/" -ForegroundColor Red
    exit 1
}

# Check helm
try {
    $helmVersion = helm version --short
    Write-Host "✅ Helm: $helmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Helm not found. Please install: https://helm.sh/docs/intro/install/" -ForegroundColor Red
    exit 1
}

# Check Docker
if ($BuildImages) {
    try {
        $dockerVersion = docker --version
        Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
    } catch {
        Write-Host "❌ Docker not found. Please install: https://www.docker.com/products/docker-desktop" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Step 1: Azure Login and ACR Login
Write-Host "🔐 Step 1: Azure and ACR Login" -ForegroundColor Cyan
Write-Host "Checking Azure login status..." -ForegroundColor Gray

try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-Host "✅ Already logged in to Azure as: $($account.user.name)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Not logged in to Azure. Logging in..." -ForegroundColor Yellow
    az login
}

Write-Host "Logging in to ACR: $AcrName..." -ForegroundColor Gray
az acr login --name $AcrName
Write-Host "✅ ACR login successful" -ForegroundColor Green
Write-Host ""

# Step 2: Get AKS Credentials (if provided)
if ($AksCluster -and $ResourceGroup) {
    Write-Host "🔐 Step 2: Getting AKS credentials" -ForegroundColor Cyan
    az aks get-credentials --resource-group $ResourceGroup --name $AksCluster --overwrite-existing
    Write-Host "✅ AKS credentials configured" -ForegroundColor Green
    Write-Host ""
}

# Verify kubectl connection
Write-Host "🔍 Verifying kubectl connection..." -ForegroundColor Cyan
try {
    $nodes = kubectl get nodes 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Connected to Kubernetes cluster" -ForegroundColor Green
        Write-Host $nodes -ForegroundColor Gray
    } else {
        Write-Host "❌ Cannot connect to Kubernetes cluster" -ForegroundColor Red
        Write-Host "Please run: az aks get-credentials --resource-group <rg> --name <cluster>" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "❌ Cannot connect to Kubernetes cluster" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Build and Push Images
if ($BuildImages) {
    Write-Host "🐳 Step 3: Building and pushing Docker images" -ForegroundColor Cyan
    
    # Build Backend
    Write-Host "Building backend image..." -ForegroundColor Gray
    docker build -t "$AcrName.azurecr.io/week1-backend:latest" ./backend
    Write-Host "✅ Backend image built" -ForegroundColor Green
    
    Write-Host "Pushing backend image..." -ForegroundColor Gray
    docker push "$AcrName.azurecr.io/week1-backend:latest"
    Write-Host "✅ Backend image pushed" -ForegroundColor Green
    
    # Build Frontend
    Write-Host "Building frontend image..." -ForegroundColor Gray
    docker build -t "$AcrName.azurecr.io/week1-frontend:latest" ./frontend
    Write-Host "✅ Frontend image built" -ForegroundColor Green
    
    Write-Host "Pushing frontend image..." -ForegroundColor Gray
    docker push "$AcrName.azurecr.io/week1-frontend:latest"
    Write-Host "✅ Frontend image pushed" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "⏭️  Step 3: Skipping image build (using existing images)" -ForegroundColor Yellow
    Write-Host ""
}

# Step 4: Install Ingress Controller
if (-not $SkipIngressInstall) {
    Write-Host "🌐 Step 4: Installing Ingress Controller" -ForegroundColor Cyan
    
    # Check if already installed
    $ingressExists = kubectl get namespace ingress-nginx 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "⚠️  Ingress-nginx namespace already exists. Skipping installation." -ForegroundColor Yellow
    } else {
        Write-Host "Adding Helm repo..." -ForegroundColor Gray
        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
        helm repo update
        
        Write-Host "Installing ingress-nginx..." -ForegroundColor Gray
        helm install ingress-nginx ingress-nginx/ingress-nginx `
            --namespace ingress-nginx `
            --create-namespace `
            --set controller.service.type=LoadBalancer
        
        Write-Host "✅ Ingress controller installed" -ForegroundColor Green
    }
    
    Write-Host "Waiting for External IP..." -ForegroundColor Gray
    $retries = 0
    $maxRetries = 30
    $externalIp = ""
    
    while ($retries -lt $maxRetries) {
        $service = kubectl get service ingress-nginx-controller -n ingress-nginx -o json 2>$null | ConvertFrom-Json
        if ($service.status.loadBalancer.ingress) {
            $externalIp = $service.status.loadBalancer.ingress[0].ip
            break
        }
        $retries++
        Write-Host "  Waiting... ($retries/$maxRetries)" -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
    
    if ($externalIp) {
        Write-Host "✅ External IP assigned: $externalIp" -ForegroundColor Green
        Write-Host ""
        Write-Host "⚠️  IMPORTANT: Configure DNS A record:" -ForegroundColor Yellow
        Write-Host "   Type:  A" -ForegroundColor White
        Write-Host "   Name:  @ or subdomain" -ForegroundColor White
        Write-Host "   Value: $externalIp" -ForegroundColor White
        Write-Host "   TTL:   300" -ForegroundColor White
        Write-Host ""
        Write-Host "Press any key after DNS is configured..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        Write-Host "⚠️  External IP not assigned yet. Check manually:" -ForegroundColor Yellow
        Write-Host "   kubectl get service ingress-nginx-controller -n ingress-nginx" -ForegroundColor White
    }
    Write-Host ""
} else {
    Write-Host "⏭️  Step 4: Skipping Ingress Controller installation" -ForegroundColor Yellow
    Write-Host ""
}

# Step 5: Install Cert-Manager
if (-not $SkipCertManager) {
    Write-Host "🔐 Step 5: Installing Cert-Manager" -ForegroundColor Cyan
    
    # Check if already installed
    $certManagerExists = kubectl get namespace cert-manager 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "⚠️  Cert-manager namespace already exists. Skipping installation." -ForegroundColor Yellow
    } else {
        Write-Host "Adding Helm repo..." -ForegroundColor Gray
        helm repo add jetstack https://charts.jetstack.io
        helm repo update
        
        Write-Host "Installing cert-manager..." -ForegroundColor Gray
        helm install cert-manager jetstack/cert-manager `
            --namespace cert-manager `
            --create-namespace `
            --set installCRDs=true
        
        Write-Host "✅ Cert-manager installed" -ForegroundColor Green
        
        Write-Host "Waiting for cert-manager pods to be ready..." -ForegroundColor Gray
        kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=120s
        Write-Host "✅ Cert-manager pods ready" -ForegroundColor Green
    }
    Write-Host ""
} else {
    Write-Host "⏭️  Step 5: Skipping Cert-Manager installation" -ForegroundColor Yellow
    Write-Host ""
}

# Step 6: Update and Deploy Manifests
Write-Host "📝 Step 6: Updating and deploying manifests" -ForegroundColor Cyan

# Create temp directory for updated manifests
$tempDir = "temp_manifests"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory | Out-Null

# Update backend deployment
Write-Host "Updating backend-deployment.yaml..." -ForegroundColor Gray
$backendContent = Get-Content k8s/backend-deployment.yaml -Raw
$backendContent = $backendContent -replace '<ACR_NAME>', $AcrName
Set-Content -Path "$tempDir/backend-deployment.yaml" -Value $backendContent

# Update frontend deployment
Write-Host "Updating react-deployment.yaml..." -ForegroundColor Gray
$frontendContent = Get-Content k8s/react-deployment.yaml -Raw
$frontendContent = $frontendContent -replace '<ACR_NAME>', $AcrName
Set-Content -Path "$tempDir/react-deployment.yaml" -Value $frontendContent

# Update cert-manager
Write-Host "Updating cert-manager.yaml..." -ForegroundColor Gray
$certManagerContent = Get-Content k8s/cert-manager.yaml -Raw
$certManagerContent = $certManagerContent -replace '<your-email@example.com>', $Email
Set-Content -Path "$tempDir/cert-manager.yaml" -Value $certManagerContent

# Update ingress-https
Write-Host "Updating ingress-https.yaml..." -ForegroundColor Gray
$ingressContent = Get-Content k8s/ingress-https.yaml -Raw
$ingressContent = $ingressContent -replace '<your-domain.com>', $DomainName
Set-Content -Path "$tempDir/ingress-https.yaml" -Value $ingressContent

# Deploy
Write-Host "Deploying backend..." -ForegroundColor Gray
kubectl apply -f "$tempDir/backend-deployment.yaml"
Write-Host "✅ Backend deployed" -ForegroundColor Green

Write-Host "Deploying frontend..." -ForegroundColor Gray
kubectl apply -f "$tempDir/react-deployment.yaml"
Write-Host "✅ Frontend deployed" -ForegroundColor Green

Write-Host "Deploying cert-manager ClusterIssuer..." -ForegroundColor Gray
kubectl apply -f "$tempDir/cert-manager.yaml"
Write-Host "✅ ClusterIssuer deployed" -ForegroundColor Green

Write-Host "Deploying HTTPS ingress..." -ForegroundColor Gray
kubectl apply -f "$tempDir/ingress-https.yaml"
Write-Host "✅ HTTPS ingress deployed" -ForegroundColor Green

# Cleanup temp directory
Remove-Item -Path $tempDir -Recurse -Force
Write-Host ""

# Step 7: Wait for Certificate
Write-Host "🔐 Step 7: Waiting for SSL certificate" -ForegroundColor Cyan
Write-Host "This may take 1-5 minutes..." -ForegroundColor Gray

$retries = 0
$maxRetries = 30
$certReady = $false

while ($retries -lt $maxRetries) {
    $cert = kubectl get certificate tls-secret -o json 2>$null | ConvertFrom-Json
    if ($cert.status.conditions) {
        $readyCondition = $cert.status.conditions | Where-Object { $_.type -eq "Ready" }
        if ($readyCondition -and $readyCondition.status -eq "True") {
            $certReady = $true
            break
        }
    }
    $retries++
    Write-Host "  Waiting for certificate... ($retries/$maxRetries)" -ForegroundColor Gray
    Start-Sleep -Seconds 10
}

if ($certReady) {
    Write-Host "✅ SSL certificate issued successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Certificate not ready yet. Check status:" -ForegroundColor Yellow
    Write-Host "   kubectl get certificate" -ForegroundColor White
    Write-Host "   kubectl describe certificate tls-secret" -ForegroundColor White
}
Write-Host ""

# Step 8: Final Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Deployment Summary:" -ForegroundColor Yellow
Write-Host "  Domain:       https://$DomainName" -ForegroundColor White
Write-Host "  Redirect URI: https://$DomainName/auth/callback" -ForegroundColor White
Write-Host ""
Write-Host "🔍 Verification Commands:" -ForegroundColor Yellow
Write-Host "  kubectl get pods                    # Check pods status" -ForegroundColor White
Write-Host "  kubectl get certificate             # Check certificate status" -ForegroundColor White
Write-Host "  kubectl get ingress                 # Check ingress" -ForegroundColor White
Write-Host "  curl -I https://$DomainName         # Test HTTPS" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Open in browser:" -ForegroundColor Yellow
Write-Host "  https://$DomainName" -ForegroundColor Cyan
Write-Host ""
Write-Host "📧 Send to Admin for OpenID registration:" -ForegroundColor Yellow
Write-Host "  Client ID:    mindx-onboarding" -ForegroundColor White
Write-Host "  Redirect URI: https://$DomainName/auth/callback" -ForegroundColor White
Write-Host "  Environment:  Production" -ForegroundColor White
Write-Host ""
Write-Host "🎉 Happy coding!" -ForegroundColor Green
Write-Host ""
