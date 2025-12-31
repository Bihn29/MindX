# 🚀 Hướng dẫn Deploy lên HTTPS - TÓM TẮT NHANH

## Bước 1: Chuẩn bị

```powershell
# Kiểm tra tools
az --version
kubectl version --client
helm version
docker --version

# Login Azure và ACR
az login
az acr login --name <your-acr-name>

# Kết nối AKS
az aks get-credentials --resource-group <rg> --name <aks-cluster>
kubectl get nodes
```

## Bước 2: Deploy Tự động (KHUYẾN NGHỊ)

```powershell
# Chạy script deploy đầy đủ
.\scripts\deploy-full-https.ps1 `
  -AcrName "youracr" `
  -DomainName "myapp.example.com" `
  -Email "your@email.com" `
  -ResourceGroup "your-rg" `
  -AksCluster "your-aks"
```

Script sẽ tự động:
- ✅ Build và push images
- ✅ Install Ingress Controller
- ✅ Install Cert-Manager
- ✅ Deploy backend và frontend
- ✅ Setup SSL certificate
- ✅ Configure HTTPS ingress

## Bước 3: Cấu hình DNS

```powershell
# Lấy External IP
kubectl get service ingress-nginx-controller -n ingress-nginx

# Tạo DNS A Record:
# Type: A
# Name: @ hoặc subdomain
# Value: <External IP từ trên>
# TTL: 300
```

## Bước 4: Đợi Certificate

```powershell
# Kiểm tra certificate (đợi 1-5 phút)
kubectl get certificate
kubectl describe certificate tls-secret

# Đợi cho status = Ready
```

## Bước 5: Test HTTPS

```powershell
# Test trong terminal
curl -I https://myapp.example.com

# Mở browser
start https://myapp.example.com
```

## Bước 6: Đăng ký Redirect URI

Gửi cho admin:
- **Client ID:** mindx-onboarding
- **Redirect URI:** https://myapp.example.com/auth/callback
- **Environment:** Production

## 🎉 XONG!

Ứng dụng đã chạy tại: **https://myapp.example.com**

---

## ⚠️ Troubleshooting

### Certificate không issue
```powershell
kubectl logs -n cert-manager -l app=cert-manager
kubectl describe certificate tls-secret
```

### Pods không start
```powershell
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### DNS không resolve
```powershell
nslookup myapp.example.com
# Phải trả về External IP
```

---

## 📚 Tài liệu đầy đủ

- **HTTPS_QUICKSTART.md** - Hướng dẫn chi tiết
- **DEPLOY_HTTPS.md** - Manual deployment
- **DEPLOYMENT_CHECKLIST.md** - Checklist đầy đủ
