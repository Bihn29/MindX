# Start port-forward and open browser
Write-Host "🚀 Khởi động AKS Web Access..." -ForegroundColor Cyan
Write-Host ""

# Kill old port-forward if exists
Write-Host "🧹 Dọn dẹp port-forward cũ..." -ForegroundColor Yellow
Get-Process powershell | Where-Object {
    $_.CommandLine -like "*port-forward*" -and $_.CommandLine -like "*ingress-nginx*"
} | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 1

# Start new port-forward in separate window
Write-Host "⚡ Khởi động port-forward mới..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "Write-Host '═════════════════════════════════════════' -ForegroundColor Cyan; " + `
    "Write-Host '⚡ PORT-FORWARD ĐANG CHẠY' -ForegroundColor Green; " + `
    "Write-Host '═════════════════════════════════════════' -ForegroundColor Cyan; " + `
    "Write-Host ''; " + `
    "Write-Host '🌐 URL Truy Cập:' -ForegroundColor Yellow; " + `
    "Write-Host '   HTTP:  http://localhost:8080' -ForegroundColor Green; " + `
    "Write-Host '   HTTPS: https://localhost:8443 (self-signed)' -ForegroundColor Green; " + `
    "Write-Host ''; " + `
    "Write-Host '⚠️  LƯU Ý:' -ForegroundColor Yellow; " + `
    "Write-Host '   - PHẢI giữ cửa sổ này mở' -ForegroundColor Gray; " + `
    "Write-Host '   - Nhấn Ctrl+C để dừng' -ForegroundColor Gray; " + `
    "Write-Host ''; " + `
    "Write-Host '═════════════════════════════════════════' -ForegroundColor Cyan; " + `
    "Write-Host ''; " + `
    "kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80 8443:443"

# Wait for port-forward to be ready
Write-Host "⏳ Đợi port-forward khởi động..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Test connection
Write-Host "🔍 Kiểm tra kết nối..." -ForegroundColor Yellow
$maxRetries = 10
$retryCount = 0
$connected = $false

while ($retryCount -lt $maxRetries -and -not $connected) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $connected = $true
        }
    } catch {
        $retryCount++
        Write-Host "   Thử lần $retryCount/$maxRetries..." -ForegroundColor Gray
        Start-Sleep -Seconds 1
    }
}

if ($connected) {
    Write-Host "✅ Kết nối thành công!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Mở browser..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    start http://localhost:8080
    
    Write-Host ""
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "✅ HOÀN TẤT!" -ForegroundColor Green
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📱 Website đã mở tại: http://localhost:8080" -ForegroundColor Green
    Write-Host "🔗 Backend API: http://localhost:8080/api/health" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  Lưu ý: Đừng đóng terminal port-forward!" -ForegroundColor Yellow
} else {
    Write-Host "❌ Không thể kết nối sau $maxRetries lần thử" -ForegroundColor Red
    Write-Host ""
    Write-Host "Kiểm tra thủ công:" -ForegroundColor Yellow
    Write-Host "  1. Terminal port-forward có mở không?" -ForegroundColor Gray
    Write-Host "  2. Thử: curl http://localhost:8080" -ForegroundColor Gray
}
