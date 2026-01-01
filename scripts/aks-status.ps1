# Quick AKS Status Check Script
# Shows current deployment status and provides useful commands

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  AKS DEPLOYMENT STATUS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check cluster connection
try {
    $context = kubectl config current-context 2>$null
    Write-Host "Cluster: " -NoNewline -ForegroundColor Yellow
    Write-Host $context -ForegroundColor White
} catch {
    Write-Host "❌ Not connected to AKS cluster" -ForegroundColor Red
    Write-Host "`nRun: az aks get-credentials --resource-group mindx-intern-03-rg --name mindx-week1-aks`n" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Backend deployment
Write-Host "Backend Deployment:" -ForegroundColor Yellow
$backendStatus = kubectl get deployment backend-deployment -o json | ConvertFrom-Json
Write-Host "  Replicas: " -NoNewline -ForegroundColor Gray
Write-Host "$($backendStatus.status.availableReplicas)/$($backendStatus.spec.replicas) available" -ForegroundColor White

$backendPods = kubectl get pods -l app=backend -o json | ConvertFrom-Json
foreach ($pod in $backendPods.items) {
    $status = $pod.status.phase
    $color = if ($status -eq "Running") { "Green" } else { "Yellow" }
    Write-Host "    • $($pod.metadata.name): " -NoNewline -ForegroundColor Gray
    Write-Host $status -ForegroundColor $color
}

Write-Host ""

# Frontend deployment
Write-Host "Frontend Deployment:" -ForegroundColor Yellow
$frontendStatus = kubectl get deployment react-app-deployment -o json | ConvertFrom-Json
Write-Host "  Replicas: " -NoNewline -ForegroundColor Gray
Write-Host "$($frontendStatus.status.availableReplicas)/$($frontendStatus.spec.replicas) available" -ForegroundColor White

$frontendPods = kubectl get pods -l app=react-app -o json | ConvertFrom-Json
foreach ($pod in $frontendPods.items) {
    $status = $pod.status.phase
    $color = if ($status -eq "Running") { "Green" } else { "Yellow" }
    Write-Host "    • $($pod.metadata.name): " -NoNewline -ForegroundColor Gray
    Write-Host $status -ForegroundColor $color
}

Write-Host ""

# Ingress status
Write-Host "Ingress Configuration:" -ForegroundColor Yellow
$ingress = kubectl get ingress fullstack-ingress-https -o json | ConvertFrom-Json
$externalIP = $ingress.status.loadBalancer.ingress[0].ip
Write-Host "  External IP: " -NoNewline -ForegroundColor Gray
Write-Host $externalIP -ForegroundColor White
Write-Host "  Domain: " -NoNewline -ForegroundColor Gray
Write-Host "https://$($ingress.spec.rules[0].host)" -ForegroundColor White
Write-Host "  TLS Secret: " -NoNewline -ForegroundColor Gray
Write-Host $ingress.spec.tls[0].secretName -ForegroundColor White

Write-Host ""

# Certificate status
Write-Host "SSL Certificate:" -ForegroundColor Yellow
$cert = kubectl get certificate mindx-week1-tls -o json | ConvertFrom-Json
$certReady = $cert.status.conditions | Where-Object { $_.type -eq "Ready" }
$certColor = if ($certReady.status -eq "True") { "Green" } else { "Yellow" }
Write-Host "  Status: " -NoNewline -ForegroundColor Gray
Write-Host $certReady.reason -ForegroundColor $certColor
Write-Host "  Issuer: " -NoNewline -ForegroundColor Gray
Write-Host $cert.spec.issuerRef.name -ForegroundColor White

Write-Host ""

# Services
Write-Host "Services:" -ForegroundColor Yellow
kubectl get svc -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,PORT:.spec.ports[0].port | Select-Object -Skip 1

Write-Host ""

# Container images
Write-Host "Container Images:" -ForegroundColor Yellow
Write-Host "  Backend:  " -NoNewline -ForegroundColor Gray
Write-Host $backendStatus.spec.template.spec.containers[0].image -ForegroundColor White
Write-Host "  Frontend: " -NoNewline -ForegroundColor Gray
Write-Host $frontendStatus.spec.template.spec.containers[0].image -ForegroundColor White

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ACCESS METHODS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "⚠️  External IP $externalIP is not publicly accessible" -ForegroundColor Yellow
Write-Host ""

Write-Host "Option 1: Port-Forward (Recommended)" -ForegroundColor Yellow
Write-Host "  .\scripts\aks-port-forward.ps1" -ForegroundColor White
Write-Host "  Then access:" -ForegroundColor Gray
Write-Host "    Backend:  http://localhost:3000/health" -ForegroundColor White
Write-Host "    Frontend: http://localhost:8080" -ForegroundColor White
Write-Host ""

Write-Host "Option 2: Manual Port-Forward" -ForegroundColor Yellow
Write-Host "  kubectl port-forward svc/backend-service 3000:3000" -ForegroundColor White
Write-Host "  kubectl port-forward svc/react-app-service 8080:8080" -ForegroundColor White
Write-Host ""

Write-Host "Option 3: Exec into Pod" -ForegroundColor Yellow
$firstBackendPod = $backendPods.items[0].metadata.name
Write-Host "  kubectl exec -it $firstBackendPod -- sh" -ForegroundColor White
Write-Host "  # wget -O- http://localhost:3000/health" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  USEFUL COMMANDS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "View logs:" -ForegroundColor Yellow
Write-Host "  kubectl logs -l app=backend --tail=50" -ForegroundColor White
Write-Host "  kubectl logs -l app=react-app --tail=50" -ForegroundColor White
Write-Host ""

Write-Host "Restart deployments:" -ForegroundColor Yellow
Write-Host "  kubectl rollout restart deployment/backend-deployment" -ForegroundColor White
Write-Host "  kubectl rollout restart deployment/react-app-deployment" -ForegroundColor White
Write-Host ""

Write-Host "Check deployment status:" -ForegroundColor Yellow
Write-Host "  kubectl rollout status deployment/backend-deployment" -ForegroundColor White
Write-Host ""

Write-Host "Describe resources:" -ForegroundColor Yellow
Write-Host "  kubectl describe pod <pod-name>" -ForegroundColor White
Write-Host "  kubectl describe ingress fullstack-ingress-https" -ForegroundColor White
Write-Host ""

Write-Host "========================================`n" -ForegroundColor Cyan
