# Week 1: Full-Stack Application on Azure Cloud

This repository contains a full-stack application (React frontend + Node.js/TypeScript API backend) deployed on Azure Cloud infrastructure.

## Project Structure

```
.
├── backend/             # Backend API (Node.js/TypeScript Express)
├── frontend/            # React frontend application (to be added in Step 4)
├── k8s/                 # Kubernetes manifests (to be added in Step 2)
├── architecture.md     # Architecture documentation
├── overview.md         # Project overview and acceptance criteria
└── tasks.md            # Step-by-step implementation guide
```

## Architecture

See [architecture.md](./architecture.md) for detailed architecture documentation.

## Objectives

- Back-end API deployed and accessible via public HTTPS endpoint
- Front-end React web app deployed and accessible via public HTTPS domain
- HTTPS enforced for all endpoints
- Authentication integrated with OpenID (https://id-dev.mindx.edu.vn)
- All services running on Azure Cloud infrastructure

## Implementation Steps

### Step 1: API Foundation ✅
- [x] Create Node.js/TypeScript Express API
- [x] Containerize API with Docker
- [x] Create deployment scripts and documentation
- [ ] Setup Azure Container Registry (ACR) - Requires DevOps
- [ ] Build and push container image to ACR
- [ ] Deploy API to Azure Web App - Requires DevOps
- [ ] Verify API deployment

### Step 2: Kubernetes Foundation ✅
- [x] Create Kubernetes manifests for API
- [x] Create deployment scripts
- [ ] Create AKS cluster - Requires Sys Admin
- [ ] Configure cluster access - Requires DevOps
- [ ] Deploy API to AKS
- [ ] Verify internal deployment

### Step 3: External Access (Ingress) ✅
- [x] Create Ingress Resource manifests
- [ ] Install Ingress Controller - Requires DevOps
- [ ] Apply Ingress Resource for API
- [ ] Verify external API access

### Step 4: Full-Stack Application ✅
- [x] Create React Web Application
- [x] Containerize React app with Docker
- [x] Create Kubernetes manifests for React app
- [x] Create Ingress for full-stack routing
- [ ] Build and push React app to ACR
- [ ] Deploy React app to AKS
- [ ] Verify full-stack application

### Step 5: Authentication ✅
- [x] Choose authentication method (OpenID)
- [x] Update API for authentication
- [x] Update React app for auth UI
- [x] Configure authentication flow

### Step 6: Production-Ready Security ✅
- [x] Create HTTPS Ingress manifest
- [x] Create cert-manager configuration
- [ ] Domain configuration - Requires Sys Admin
- [ ] Install cert-manager - Requires DevOps
- [ ] Configure HTTPS/SSL
- [ ] Verify HTTPS access

## Local Development

### Prerequisites

1. **Backend Setup:**
   ```bash
   cd backend
   npm install
   cp .env.example .env  # Configure OPENID_CLIENT_ID and OPENID_CLIENT_SECRET
   npm run dev
   ```

2. **Frontend Setup:**
   ```bash
   cd frontend
   npm install
   cp .env.example .env  # Configure VITE_OPENID_CLIENT_ID
   npm run dev
   ```

### Configuration

**Backend `.env`:**
```env
PORT=3000
NODE_ENV=development
OPENID_CLIENT_ID=mindx-onboarding
OPENID_CLIENT_SECRET=cHJldmVudGJvdW5kYmF0dHJlZWV4cGxvcmVjZWxsbmVydm91c3ZhcG9ydGhhbnN0ZWU=
```

**Frontend `.env`:**
```env
VITE_API_BASE_URL=http://localhost:3000/api
VITE_OPENID_CLIENT_ID=mindx-onboarding
```

### Test Account

- Email: `intern@mindx.com.vn`
- Password: `mindx1234`

## Deployment - Redirect URI Configuration

Khi triển khai lên môi trường dev/production, bạn cần đăng ký Redirect URI với MindX Identity Provider.

### Cách lấy Redirect URI

**Redirect URI format:**
```
https://your-domain.com/auth/callback
```

**Ví dụ:**
- Dev: `https://dev.example.com/auth/callback`
- Production: `https://myapp.azurewebsites.net/auth/callback`

### Script để lấy Redirect URI

```bash
# Sử dụng script
node scripts/get-redirect-uri.js https://your-dev-domain.com

# Hoặc xem trong browser console khi deploy
# Redirect URI sẽ tự động được log ra console
```

### Thông tin gửi cho Admin

Khi gửi yêu cầu cho admin, cung cấp:

1. **Client ID:** `mindx-onboarding`
2. **Redirect URI:** `https://your-dev-domain.com/auth/callback`
3. **Environment:** Dev hoặc Production
4. **Application Name:** Week 1 Full-Stack Application

Xem chi tiết trong [scripts/get-redirect-uri.md](./scripts/get-redirect-uri.md)

## 🚀 Deploy lên HTTPS trên Azure (Production)

### Quick Start - Deploy Tự động

**Full Deployment (Khuyến nghị cho lần đầu):**
```powershell
# Deploy tất cả: Build images + Install Ingress + Cert-manager + HTTPS
.\scripts\deploy-full-https.ps1 `
  -AcrName "your-acr-name" `
  -DomainName "myapp.example.com" `
  -Email "your-email@example.com" `
  -ResourceGroup "your-rg" `
  -AksCluster "your-aks-cluster"
```

**Deploy nhanh (nếu đã có Ingress và Cert-manager):**
```powershell
.\scripts\deploy-https.ps1 `
  -AcrName "your-acr-name" `
  -DomainName "myapp.example.com" `
  -Email "your-email@example.com"
```

### 📋 Prerequisites

✅ **Bắt buộc:**
- Azure subscription với quyền tạo resources
- AKS cluster đã được tạo
- Azure Container Registry (ACR) đã được tạo
- Domain name hoặc subdomain
- Quyền cấu hình DNS A record

✅ **Tools cần cài đặt:**
- [Azure CLI](https://aka.ms/installazurecliwindows)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)
- [Helm](https://helm.sh/docs/intro/install/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop)

### 📖 Hướng dẫn chi tiết

Xem hướng dẫn đầy đủ trong:
- **[HTTPS_QUICKSTART.md](./HTTPS_QUICKSTART.md)** - Hướng dẫn nhanh deploy HTTPS
- **[DEPLOY_HTTPS.md](./DEPLOY_HTTPS.md)** - Hướng dẫn chi tiết từng bước

### ✅ Sau khi deploy thành công

1. **Kiểm tra deployment:**
   ```powershell
   kubectl get pods              # Pods đang chạy
   kubectl get certificate       # SSL certificate
   kubectl get ingress           # Ingress routing
   ```

2. **Test HTTPS:**
   ```powershell
   curl -I https://myapp.example.com
   start https://myapp.example.com
   ```

3. **Đăng ký Redirect URI với Admin:**
   - Client ID: `mindx-onboarding`
   - Redirect URI: `https://myapp.example.com/auth/callback`
   - Environment: Production

### Documentation

- [Backend README](./backend/README.md) - Backend development instructions
- [Frontend README](./frontend/README.md) - Frontend development instructions
- [Docker Deploy Guide](./DOCKER_DEPLOY.md) - Docker deployment instructions

## Docker Deployment

### Quick Start với Docker Compose

```bash
# Build và chạy tất cả services
docker-compose up --build

# Hoặc chạy ở background
docker-compose up -d --build
```

**Services sẽ chạy tại:**
- Frontend: http://localhost:8080
- Backend: http://localhost:3000

### Build Images

**Windows:**
```powershell
.\scripts\docker-build.ps1
```

**Linux/Mac:**
```bash
chmod +x scripts/docker-build.sh
./scripts/docker-build.sh
```

Xem hướng dẫn chi tiết trong [DOCKER_DEPLOY.md](./DOCKER_DEPLOY.md)

## Azure Deployment

### Prerequisites

- Azure subscription with appropriate permissions
- Docker installed locally
- Azure CLI installed and configured
- kubectl installed (for AKS deployment)
- Git repository access

### Collaboration Requirements

Some steps require collaboration with Sys Admin and DevOps teams:

- **Sys Admin**: Azure subscription, AKS cluster, DNS management
- **DevOps**: ACR, AKS access, Ingress controller, cert-manager

## Documentation

- [Architecture](./architecture.md) - Detailed architecture documentation
- [Overview](./overview.md) - Project objectives and acceptance criteria
- [Tasks](./tasks.md) - Step-by-step implementation guide

## License

ISC

