# Script fix nip.io cho AKS
Write-Host "=== FIX NIP.IO CHO AKS ===" -ForegroundColor Cyan

# 1. Kiểm tra kubectl
Write-Host "`n1. Kiểm tra kết nối AKS..." -ForegroundColor Yellow
kubectl cluster-info | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Lỗi: Chưa kết nối với AKS!" -ForegroundColor Red
    exit 1
}
Write-Host "   OK - Đã kết nối" -ForegroundColor Green

# 2. Kiểm tra NGINX Ingress
Write-Host "`n2. Kiểm tra NGINX Ingress Controller..." -ForegroundColor Yellow
$nginx = kubectl get pods -n ingress-nginx 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Cài đặt NGINX Ingress Controller..." -ForegroundColor Cyan
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
    Start-Sleep -Seconds 30
}
Write-Host "   OK - NGINX đã có" -ForegroundColor Green

# 3. Lấy External IP
Write-Host "`n3. Lấy External IP..." -ForegroundColor Yellow
$ip = $null
for ($i = 0; $i -lt 30; $i++) {
    $svcJson = kubectl get svc ingress-nginx-controller -n ingress-nginx -o json 2>$null
    if ($svcJson) {
        $svc = $svcJson | ConvertFrom-Json
        if ($svc.status.loadBalancer.ingress) {
            $ip = $svc.status.loadBalancer.ingress[0].ip
            if ($ip) { break }
        }
    }
    Write-Host "   Đợi IP... ($i/30)" -ForegroundColor Gray
    Start-Sleep -Seconds 10
}

if (-not $ip) {
    Write-Host "   Lỗi: Không lấy được IP!" -ForegroundColor Red
    exit 1
}
Write-Host "   IP: $ip" -ForegroundColor Green

# 4. Cập nhật domain
$domain = "$ip.nip.io"
Write-Host "`n4. Cập nhật domain: $domain" -ForegroundColor Yellow

$ingress = Get-Content k8s\ingress-https-ip.yaml -Raw
$ingress = $ingress -replace '\d+\.\d+\.\d+\.\d+\.nip\.io', $domain
Set-Content k8s\ingress-https-ip.yaml -Value $ingress -NoNewline
Write-Host "   OK - Đã cập nhật ingress" -ForegroundColor Green

$cert = Get-Content k8s\self-signed-issuer.yaml -Raw
$cert = $cert -replace '\d+\.\d+\.\d+\.\d+\.nip\.io', $domain
Set-Content k8s\self-signed-issuer.yaml -Value $cert -NoNewline
Write-Host "   OK - Đã cập nhật certificate" -ForegroundColor Green

# 5. Kiểm tra cert-manager
Write-Host "`n5. Kiểm tra cert-manager..." -ForegroundColor Yellow
$certmgr = kubectl get pods -n cert-manager 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   Cài đặt cert-manager..." -ForegroundColor Cyan
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
    Start-Sleep -Seconds 30
}
Write-Host "   OK - cert-manager đã có" -ForegroundColor Green

# 6. Deploy
Write-Host "`n6. Deploy ứng dụng..." -ForegroundColor Yellow
kubectl apply -f k8s\backend-deployment.yaml
kubectl apply -f k8s\react-deployment.yaml
kubectl apply -f k8s\self-signed-issuer.yaml
Start-Sleep -Seconds 10
kubectl apply -f k8s\ingress-https-ip.yaml
Write-Host "   OK - Đã deploy" -ForegroundColor Green

# 7. Hiển thị kết quả
Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "HOÀN THÀNH!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "`nURL: https://$domain" -ForegroundColor Green
Write-Host "API: https://$domain/api/health" -ForegroundColor Green
Write-Host "`nLưu ý: Chứng chỉ self-signed - bấm Advanced > Proceed" -ForegroundColor Yellow
Write-Host "`nKiểm tra:" -ForegroundColor Yellow
Write-Host "  kubectl get pods"
Write-Host "  kubectl get certificate"
Write-Host "  kubectl get ingress"
