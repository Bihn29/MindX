# Script fix Azure Load Balancer cho HTTP/HTTPS
Write-Host "=== FIX AZURE LOAD BALANCER ===" -ForegroundColor Cyan

Write-Host "`n⚠️  VẤN ĐỀ:" -ForegroundColor Yellow
Write-Host "Azure Load Balancer chưa mở port 80/443 cho public access" -ForegroundColor Red
Write-Host ""

Write-Host "💡 GIẢI PHÁP:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Có 2 cách fix:" -ForegroundColor Green
Write-Host ""

Write-Host "1️⃣  SỬ DỤNG PORT-FORWARD (Dễ - Không cần quyền Azure)" -ForegroundColor Cyan
Write-Host "   kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80 8443:443" -ForegroundColor Gray
Write-Host "   Sau đó truy cập: http://localhost:8080 hoặc https://localhost:8443" -ForegroundColor Gray
Write-Host ""

Write-Host "2️⃣  MỞ PORT TRÊN AZURE (Cần quyền admin)" -ForegroundColor Cyan
Write-Host "   Yêu cầu admin AKS chạy lệnh sau:" -ForegroundColor Gray
Write-Host "   az network nsg rule create \`" -ForegroundColor Gray
Write-Host "     --resource-group MC_mindx-week1-rg_mindx-week1-aks_eastasia \`" -ForegroundColor Gray
Write-Host "     --nsg-name <nsg-name> \`" -ForegroundColor Gray
Write-Host "     --name AllowHTTP \`" -ForegroundColor Gray
Write-Host "     --priority 100 \`" -ForegroundColor Gray
Write-Host "     --source-address-prefixes '*' \`" -ForegroundColor Gray
Write-Host "     --destination-port-ranges 80 \`" -ForegroundColor Gray
Write-Host "     --access Allow \`" -ForegroundColor Gray
Write-Host "     --protocol Tcp" -ForegroundColor Gray
Write-Host ""
Write-Host "   az network nsg rule create \`" -ForegroundColor Gray
Write-Host "     --resource-group MC_mindx-week1-rg_mindx-week1-aks_eastasia \`" -ForegroundColor Gray
Write-Host "     --nsg-name <nsg-name> \`" -ForegroundColor Gray
Write-Host "     --name AllowHTTPS \`" -ForegroundColor Gray
Write-Host "     --priority 101 \`" -ForegroundColor Gray
Write-Host "     --source-address-prefixes '*' \`" -ForegroundColor Gray
Write-Host "     --destination-port-ranges 443 \`" -ForegroundColor Gray
Write-Host "     --access Allow \`" -ForegroundColor Gray
Write-Host "     --protocol Tcp" -ForegroundColor Gray
Write-Host ""

Write-Host "🚀 CHẠY PORT-FORWARD NGAY BÂY GIỜ? (y/n)" -ForegroundColor Green
$choice = Read-Host

if ($choice -eq 'y' -or $choice -eq 'Y') {
    Write-Host "`n⚡ Đang khởi động port-forward..." -ForegroundColor Cyan
    Write-Host "   HTTP:  http://localhost:8080" -ForegroundColor Green
    Write-Host "   HTTPS: https://localhost:8443" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  Giữ cửa sổ này mở. Nhấn Ctrl+C để dừng." -ForegroundColor Yellow
    Write-Host ""
    
    Start-Sleep -Seconds 2
    kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80 8443:443
} else {
    Write-Host "`nĐã hủy. Bạn có thể chạy port-forward thủ công:" -ForegroundColor Yellow
    Write-Host "kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80 8443:443" -ForegroundColor Cyan
}
