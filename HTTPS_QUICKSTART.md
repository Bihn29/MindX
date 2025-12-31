# Quick Start: Deploy lên HTTPS trên Azure AKS

Hướng dẫn nhanh để deploy ứng dụng từ localhost lên HTTPS trên Azure.

## 📋 Prerequisites (Cần có trước)

### 1. Azure Resources
- ✅ Azure subscription
- ✅ AKS cluster đã được tạo
- ✅ Azure Container Registry (ACR) đã được tạo
- ✅ kubectl đã kết nối với AKS cluster
- ✅ Azure CLI đã đăng nhập

### 2. Domain Name
- ✅ Domain name hoặc subdomain (ví dụ: `myapp.example.com`)
- ✅ Quyền truy cập DNS settings để cấu hình A record

### 3. Local Tools
```powershell
# Kiểm tra các tools cần thiết
az --version                    # Azure CLI
kubectl version --client        # Kubernetes CLI
docker --version                # Docker
helm version                    # Helm (package manager for Kubernetes)
```

## 🚀 Deployment Steps

### Option A: Sử dụng Script Tự động (KHUYẾN NGHỊ)

```powershell
# Chạy script deploy tự động
.\scripts\deploy-https.ps1 `
  -AcrName "your-acr-name" `
  -DomainName "myapp.example.com" `
  -Email "your-email@example.com"
```

**Script sẽ tự động:**
1. ✅ Build và push Docker images lên ACR
2. ✅ Deploy backend và frontend lên AKS
3. ✅ Cấu hình cert-manager
4. ✅ Tạo HTTPS ingress với SSL certificate

### Option B: Deploy Từng bước Thủ công

#### Bước 1: Login vào Azure và ACR

```powershell
# Login Azure
az login

# Login ACR
az acr login --name your-acr-name
```

#### Bước 2: Build và Push Images

```powershell
# Backend
docker build -t your-acr-name.azurecr.io/week1-backend:latest ./backend
docker push your-acr-name.azurecr.io/week1-backend:latest

# Frontend
docker build -t your-acr-name.azurecr.io/week1-frontend:latest ./frontend
docker push your-acr-name.azurecr.io/week1-frontend:latest
```

#### Bước 3: Cấu hình kubectl

```powershell
# Get AKS credentials
az aks get-credentials --resource-group <resource-group> --name <aks-cluster-name>

# Verify connection
kubectl get nodes
```

#### Bước 4: Install Ingress Controller (Nếu chưa có)

```powershell
# Add Helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx `
  --namespace ingress-nginx `
  --create-namespace `
  --set controller.service.type=LoadBalancer

# Wait and get External IP
kubectl get service ingress-nginx-controller -n ingress-nginx --watch
```

#### Bước 5: Cấu hình DNS

```powershell
# Lấy External IP
$EXTERNAL_IP = kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
Write-Host "Configure DNS A record: $EXTERNAL_IP"
```

**Vào DNS Management của domain:**
- Type: `A`
- Name: `@` hoặc `myapp` (cho subdomain)
- Value: `<EXTERNAL_IP từ trên>`
- TTL: `300`

**Kiểm tra DNS:**
```powershell
nslookup myapp.example.com
# Phải trả về IP = EXTERNAL_IP
```

#### Bước 6: Install Cert-Manager (Nếu chưa có)

```powershell
# Add cert-manager Helm repo
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager
helm install cert-manager jetstack/cert-manager `
  --namespace cert-manager `
  --create-namespace `
  --set installCRDs=true

# Verify
kubectl get pods -n cert-manager
```

#### Bước 7: Update và Deploy Manifests

**Cập nhật k8s/backend-deployment.yaml:**
```yaml
image: your-acr-name.azurecr.io/week1-backend:latest  # Thay your-acr-name
```

**Cập nhật k8s/react-deployment.yaml:**
```yaml
image: your-acr-name.azurecr.io/week1-frontend:latest  # Thay your-acr-name
```

**Cập nhật k8s/cert-manager.yaml:**
```yaml
email: your-email@example.com  # Thay email của bạn
```

**Cập nhật k8s/ingress-https.yaml:**
```yaml
- host: myapp.example.com  # Thay domain của bạn (2 chỗ)
```

**Deploy:**
```powershell
# Deploy backend và frontend
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/react-deployment.yaml

# Deploy cert-manager ClusterIssuer
kubectl apply -f k8s/cert-manager.yaml

# Deploy HTTPS ingress
kubectl apply -f k8s/ingress-https.yaml
```

#### Bước 8: Kiểm tra Certificate

```powershell
# Check certificate status
kubectl get certificate
kubectl describe certificate tls-secret

# Đợi cho đến khi status = Ready (có thể mất 1-5 phút)
```

#### Bước 9: Test HTTPS

```powershell
# Test HTTPS
curl -I https://myapp.example.com

# Mở browser
start https://myapp.example.com
```

## 🔐 Cấu hình OpenID Redirect URI

Sau khi deploy thành công, cần đăng ký Redirect URI với admin:

**Redirect URI:**
```
https://myapp.example.com/auth/callback
```

Gửi thông tin sau cho admin:
- **Client ID:** `mindx-onboarding`
- **Redirect URI:** `https://myapp.example.com/auth/callback`
- **Environment:** Production/Dev

## ✅ Verification Checklist

- [ ] External IP được assign cho Ingress Controller
- [ ] DNS A record đã được cấu hình và resolve đúng
- [ ] Backend pods đang running: `kubectl get pods -l app=backend`
- [ ] Frontend pods đang running: `kubectl get pods -l app=react-app`
- [ ] Certificate đã được issued: `kubectl get certificate`
- [ ] HTTPS hoạt động: `curl -I https://myapp.example.com`
- [ ] Redirect URI đã được đăng ký với admin
- [ ] Authentication flow hoạt động

## 🔍 Troubleshooting

### Certificate không được issue

```powershell
# Check cert-manager pods
kubectl get pods -n cert-manager

# Check certificate details
kubectl describe certificate tls-secret

# Check certificate request
kubectl get certificaterequest
kubectl describe certificaterequest <name>
```

### DNS không resolve

```powershell
# Check external IP
kubectl get service ingress-nginx-controller -n ingress-nginx

# Test DNS
nslookup myapp.example.com
dig myapp.example.com
```

### Pods không start

```powershell
# Check pod status
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Check if image can be pulled
kubectl get events --sort-by='.lastTimestamp'
```

### HTTP redirect không hoạt động

```powershell
# Check ingress
kubectl get ingress
kubectl describe ingress fullstack-ingress-https
```

## 📝 Environment Variables

Nếu cần cấu hình environment variables cho backend (OpenID credentials):

**Cách 1: Kubernetes Secret**
```powershell
# Create secret
kubectl create secret generic backend-secrets `
  --from-literal=OPENID_CLIENT_ID=mindx-onboarding `
  --from-literal=OPENID_CLIENT_SECRET=your-secret

# Update backend-deployment.yaml to use secret
```

**Cách 2: ConfigMap**
```powershell
# Create configmap
kubectl create configmap backend-config `
  --from-literal=OPENID_CLIENT_ID=mindx-onboarding

# Update backend-deployment.yaml to use configmap
```

## 🔄 Update Application

Khi có thay đổi code:

```powershell
# Build new image with tag
docker build -t your-acr-name.azurecr.io/week1-backend:v2 ./backend
docker push your-acr-name.azurecr.io/week1-backend:v2

# Update deployment
kubectl set image deployment/backend-deployment backend=your-acr-name.azurecr.io/week1-backend:v2

# Or rollout restart
kubectl rollout restart deployment/backend-deployment
```

## 📚 Tài liệu tham khảo

- [DEPLOY_HTTPS.md](./DEPLOY_HTTPS.md) - Chi tiết đầy đủ
- [Azure AKS Docs](https://docs.microsoft.com/en-us/azure/aks/)
- [Cert-Manager Docs](https://cert-manager.io/docs/)
- [Ingress-Nginx Docs](https://kubernetes.github.io/ingress-nginx/)
