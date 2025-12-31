# Hướng dẫn Deploy lên HTTPS

Hướng dẫn chi tiết để deploy ứng dụng lên Azure với HTTPS/SSL certificate.

## Prerequisites

- Azure subscription với permissions
- Domain name (hoặc subdomain)
- AKS cluster đã được tạo
- kubectl đã được cấu hình
- Azure CLI đã được cài đặt

## Bước 1: Deploy Backend và Frontend lên AKS

### 1.1 Build và Push Images lên ACR

```bash
# Build và push backend
.\scripts\build-and-push.ps1 -AcrName <acr-name> -ImageName week1-backend

# Build và push frontend
.\scripts\build-and-push-frontend.ps1 -AcrName <acr-name> -ImageName week1-frontend
```

### 1.2 Deploy Backend

```bash
# Update ACR name trong manifest
# Sau đó deploy
kubectl apply -f k8s/backend-deployment.yaml
```

### 1.3 Deploy Frontend

```bash
# Update ACR name trong manifest
# Sau đó deploy
kubectl apply -f k8s/react-deployment.yaml
```

## Bước 2: Setup Ingress Controller

### 2.1 Install Ingress Controller

```bash
# Add Helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

### 2.2 Get External IP

```bash
kubectl get service ingress-nginx-controller -n ingress-nginx
```

Đợi cho đến khi có EXTERNAL-IP (có thể mất vài phút).

## Bước 3: Configure DNS

### 3.1 Lấy External IP từ Ingress

```bash
EXTERNAL_IP=$(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "External IP: $EXTERNAL_IP"
```

### 3.2 Cấu hình DNS Record

**Option 1: A Record (Recommended)**
```
Type: A
Name: @ (hoặc subdomain như dev, app, etc.)
Value: <EXTERNAL_IP>
TTL: 300
```

**Option 2: CNAME Record**
```
Type: CNAME
Name: @ (hoặc subdomain)
Value: <your-aks-ingress-domain>.cloudapp.azure.com
TTL: 300
```

### 3.3 Verify DNS

```bash
# Kiểm tra DNS đã resolve chưa
nslookup your-domain.com
# hoặc
dig your-domain.com
```

## Bước 4: Install Cert-Manager

### 4.1 Install cert-manager

```bash
# Add cert-manager Helm repo
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

### 4.2 Verify Installation

```bash
kubectl get pods -n cert-manager
```

Đợi cho đến khi tất cả pods đều Running.

## Bước 5: Configure ClusterIssuer

### 5.1 Update cert-manager.yaml

Mở file `k8s/cert-manager.yaml` và cập nhật email:

```yaml
email: your-email@example.com  # Thay bằng email của bạn
```

### 5.2 Apply ClusterIssuer

```bash
kubectl apply -f k8s/cert-manager.yaml
```

### 5.3 Verify ClusterIssuer

```bash
kubectl get clusterissuer
```

## Bước 6: Deploy HTTPS Ingress

### 6.1 Update ingress-https.yaml

Mở file `k8s/ingress-https.yaml` và cập nhật:

1. Thay `<your-domain.com>` bằng domain của bạn
2. Đảm bảo ACR name đã được cập nhật trong backend và frontend deployments

### 6.2 Apply HTTPS Ingress

```bash
kubectl apply -f k8s/ingress-https.yaml
```

### 6.3 Verify Certificate

```bash
# Kiểm tra certificate đang được tạo
kubectl get certificate

# Kiểm tra certificate request
kubectl get certificaterequest

# Xem chi tiết certificate
kubectl describe certificate tls-secret
```

### 6.4 Check Certificate Status

```bash
# Xem logs của cert-manager
kubectl logs -n cert-manager -l app=cert-manager --tail=50
```

## Bước 7: Verify HTTPS Access

### 7.1 Test HTTPS

```bash
# Test từ command line
curl -I https://your-domain.com

# Hoặc mở browser và truy cập
# https://your-domain.com
```

### 7.2 Verify Redirect

Kiểm tra HTTP tự động redirect sang HTTPS:
```bash
curl -I http://your-domain.com
# Should return 308 Permanent Redirect to HTTPS
```

## Troubleshooting

### Certificate không được tạo

1. Kiểm tra DNS đã resolve đúng chưa:
   ```bash
   nslookup your-domain.com
   ```

2. Kiểm tra cert-manager logs:
   ```bash
   kubectl logs -n cert-manager -l app=cert-manager
   ```

3. Kiểm tra certificate status:
   ```bash
   kubectl describe certificate tls-secret
   ```

### Ingress không có external IP

1. Kiểm tra ingress controller:
   ```bash
   kubectl get pods -n ingress-nginx
   kubectl get service -n ingress-nginx
   ```

2. Nếu cần, tạo static IP:
   ```bash
   az network public-ip create \
     --resource-group <resource-group> \
     --name aks-ingress-ip \
     --sku Standard \
     --allocation-method static
   ```

### DNS không resolve

1. Đợi DNS propagation (có thể mất 5-30 phút)
2. Kiểm tra DNS record đã được tạo đúng chưa
3. Clear DNS cache:
   ```bash
   # Windows
   ipconfig /flushdns
   
   # Linux/Mac
   sudo systemd-resolve --flush-caches
   ```

## Checklist

- [ ] Backend và Frontend đã được deploy lên AKS
- [ ] Ingress controller đã được install và có external IP
- [ ] DNS record đã được cấu hình và resolve đúng
- [ ] cert-manager đã được install
- [ ] ClusterIssuer đã được tạo
- [ ] HTTPS Ingress đã được apply
- [ ] SSL certificate đã được tạo thành công
- [ ] HTTPS access hoạt động
- [ ] HTTP redirect sang HTTPS hoạt động

## Next Steps

Sau khi deploy thành công:

1. **Update Redirect URI:**
   - Lấy Redirect URI: `https://your-domain.com/auth/callback`
   - Gửi cho admin để thêm vào OpenID Provider

2. **Update Environment Variables:**
   - Frontend: `VITE_API_BASE_URL=/api`
   - Backend: Đảm bảo các biến môi trường đã được cấu hình

3. **Test Authentication:**
   - Test login flow với OpenID
   - Verify user info hiển thị đúng

## Support

Nếu gặp vấn đề, kiểm tra:
- [k8s/README.md](./k8s/README.md) - Kubernetes deployment guide
- [scripts/get-redirect-uri.md](./scripts/get-redirect-uri.md) - Redirect URI guide

