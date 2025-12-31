# 📋 HTTPS Deployment Checklist

Sử dụng checklist này để theo dõi quá trình deploy ứng dụng từ localhost lên HTTPS trên Azure.

## Phase 1: Chuẩn bị (Prerequisites)

### Azure Resources
- [ ] Azure subscription active
- [ ] Resource Group đã được tạo
- [ ] Azure Container Registry (ACR) đã được tạo
- [ ] AKS cluster đã được tạo và running
- [ ] Có quyền truy cập vào các resources trên

### Domain & DNS
- [ ] Đã có domain name hoặc subdomain
- [ ] Có quyền truy cập DNS management console
- [ ] Biết cách tạo A record trong DNS settings

### Local Development Tools
- [ ] Azure CLI đã được cài đặt: `az --version`
- [ ] kubectl đã được cài đặt: `kubectl version --client`
- [ ] Helm đã được cài đặt: `helm version`
- [ ] Docker Desktop đã được cài đặt: `docker --version`
- [ ] PowerShell hoặc Terminal sẵn sàng

### Credentials & Access
- [ ] Đã login Azure CLI: `az login`
- [ ] Có ACR login credentials
- [ ] kubectl đã kết nối với AKS cluster
- [ ] Có email để đăng ký SSL certificate

---

## Phase 2: Build và Push Images

### Backend Image
- [ ] Backend code đã build thành công locally
- [ ] Backend Dockerfile không có lỗi
- [ ] Build backend image: `docker build -t <acr>.azurecr.io/week1-backend:latest ./backend`
- [ ] Push backend image: `docker push <acr>.azurecr.io/week1-backend:latest`
- [ ] Verify image trong ACR: `az acr repository list --name <acr>`

### Frontend Image
- [ ] Frontend code đã build thành công locally
- [ ] Frontend Dockerfile không có lỗi
- [ ] Build frontend image: `docker build -t <acr>.azurecr.io/week1-frontend:latest ./frontend`
- [ ] Push frontend image: `docker push <acr>.azurecr.io/week1-frontend:latest`
- [ ] Verify image trong ACR

---

## Phase 3: Kubernetes Infrastructure

### Cluster Connection
- [ ] kubectl context đã set đúng cluster
- [ ] Test connection: `kubectl get nodes`
- [ ] Nodes đều ở trạng thái Ready

### Ingress Controller
- [ ] Helm repo ingress-nginx đã được add
- [ ] Ingress controller đã được install
- [ ] Ingress controller pods đang running: `kubectl get pods -n ingress-nginx`
- [ ] LoadBalancer service đã có External IP
- [ ] Note External IP: ________________

### Cert-Manager
- [ ] Helm repo jetstack đã được add
- [ ] Cert-manager đã được install với CRDs
- [ ] Cert-manager pods đang running: `kubectl get pods -n cert-manager`
- [ ] ClusterIssuer đã được tạo: `kubectl get clusterissuer`

---

## Phase 4: DNS Configuration

### DNS Records
- [ ] Đã login vào DNS management console
- [ ] Tạo A record pointing to Ingress External IP
  - Type: A
  - Name: @ hoặc subdomain
  - Value: <External IP>
  - TTL: 300
- [ ] DNS record đã được save
- [ ] Đợi DNS propagate (5-30 phút)
- [ ] Test DNS resolution: `nslookup <domain>`
- [ ] DNS resolve đúng IP

---

## Phase 5: Deploy Application

### Update Configuration Files
- [ ] Update ACR name trong `k8s/backend-deployment.yaml`
- [ ] Update ACR name trong `k8s/react-deployment.yaml`
- [ ] Update email trong `k8s/cert-manager.yaml`
- [ ] Update domain trong `k8s/ingress-https.yaml` (2 chỗ)

### Deploy Backend
- [ ] Apply backend deployment: `kubectl apply -f k8s/backend-deployment.yaml`
- [ ] Backend pods đang running: `kubectl get pods -l app=backend`
- [ ] Backend service created: `kubectl get svc backend-service`
- [ ] Check backend logs không có lỗi: `kubectl logs -l app=backend`

### Deploy Frontend
- [ ] Apply frontend deployment: `kubectl apply -f k8s/react-deployment.yaml`
- [ ] Frontend pods đang running: `kubectl get pods -l app=react-app`
- [ ] Frontend service created: `kubectl get svc react-app-service`
- [ ] Check frontend logs không có lỗi: `kubectl logs -l app=react-app`

### Deploy ClusterIssuer
- [ ] Apply cert-manager ClusterIssuer: `kubectl apply -f k8s/cert-manager.yaml`
- [ ] ClusterIssuer ready: `kubectl get clusterissuer letsencrypt-prod`

### Deploy HTTPS Ingress
- [ ] Apply HTTPS ingress: `kubectl apply -f k8s/ingress-https.yaml`
- [ ] Ingress created: `kubectl get ingress`
- [ ] Ingress có đúng host và paths
- [ ] Certificate Request được tạo: `kubectl get certificaterequest`

---

## Phase 6: SSL Certificate

### Certificate Issuance
- [ ] Certificate object được tạo: `kubectl get certificate tls-secret`
- [ ] Certificate status = Ready (đợi 1-5 phút)
- [ ] Check certificate details: `kubectl describe certificate tls-secret`
- [ ] Certificate đã được issued thành công
- [ ] Secret chứa certificate: `kubectl get secret tls-secret`

### Troubleshooting (nếu certificate không issue)
- [ ] Check cert-manager logs: `kubectl logs -n cert-manager -l app=cert-manager`
- [ ] Check certificate events: `kubectl describe certificate tls-secret`
- [ ] Check DNS đã propagate
- [ ] Domain accessible từ internet
- [ ] Port 80 và 443 không bị block

---

## Phase 7: Testing & Verification

### HTTPS Access
- [ ] Test HTTP redirect: `curl -I http://<domain>`
- [ ] Test HTTPS: `curl -I https://<domain>`
- [ ] HTTPS status code = 200
- [ ] SSL certificate valid
- [ ] Open in browser: `https://<domain>`
- [ ] No SSL warnings trong browser

### Application Functionality
- [ ] Frontend loads successfully
- [ ] API status hiển thị "Available"
- [ ] Environment hiển thị đúng
- [ ] Console không có errors
- [ ] All CSS/JS files load

### Authentication Flow
- [ ] Login button hiển thị
- [ ] Click login redirects to id-dev.mindx.edu.vn
- [ ] Redirect URI trong URL đúng: `https://<domain>/auth/callback`
- [ ] Test login (nếu đã đăng ký Redirect URI)
- [ ] Callback works correctly
- [ ] User info hiển thị sau login

---

## Phase 8: OpenID Registration

### Prepare Information
- [ ] Note Redirect URI: `https://<domain>/auth/callback`
- [ ] Client ID: `mindx-onboarding`
- [ ] Environment: Production/Dev

### Send to Admin
- [ ] Email/message gửi cho admin với thông tin:
  - Client ID
  - Redirect URI
  - Environment
  - Application name
- [ ] Đợi admin confirm đã đăng ký
- [ ] Test authentication flow hoàn chỉnh

---

## Phase 9: Monitoring & Maintenance

### Health Checks
- [ ] Setup monitoring cho pods: `kubectl get pods --watch`
- [ ] Check pod restarts: `kubectl get pods`
- [ ] Review logs định kỳ: `kubectl logs`
- [ ] Certificate expiry monitoring (auto-renew by cert-manager)

### Documentation
- [ ] Document domain và credentials
- [ ] Save deployment commands
- [ ] Note External IP và DNS settings
- [ ] Document any custom configurations

---

## Phase 10: Post-Deployment

### Team Communication
- [ ] Inform team về production URL
- [ ] Share credentials nếu cần
- [ ] Document deployment process
- [ ] Setup alerts cho downtime

### Backup & Recovery
- [ ] Export current manifests
- [ ] Backup ACR images
- [ ] Document rollback procedure
- [ ] Test disaster recovery plan

---

## 🎉 Deployment Complete!

**Production URL:** https://_________________

**Deployed on:** ___/___/______

**Deployed by:** _________________

**Notes:**
```
[Add any special notes or configurations here]
```

---

## 📞 Support Contacts

**Azure Admin:** _________________
**DevOps Team:** _________________
**Domain Admin:** _________________
**OpenID Admin:** _________________

---

## 🔄 Update Checklist

Khi cần update application:

- [ ] Build new images with version tag
- [ ] Push to ACR
- [ ] Update deployment with new image tag
- [ ] Apply changes: `kubectl set image deployment/...`
- [ ] Verify deployment: `kubectl rollout status`
- [ ] Test functionality
- [ ] Monitor logs for errors

---

## 📚 References

- [HTTPS_QUICKSTART.md](./HTTPS_QUICKSTART.md)
- [DEPLOY_HTTPS.md](./DEPLOY_HTTPS.md)
- [README.md](./README.md)
- [Azure AKS Docs](https://docs.microsoft.com/en-us/azure/aks/)
