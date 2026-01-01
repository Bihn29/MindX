# MindX Week 1 - Full-Stack Cloud Application

> Ứng dụng full-stack production-ready trên Azure Cloud với OpenID Connect authentication - Dự án tuần 1 chương trình MindX Engineer Onboarding

[![Azure](https://img.shields.io/badge/Azure-Cloud-blue)](https://azure.microsoft.com)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.33.5-326CE5)](https://kubernetes.io)
[![Node.js](https://img.shields.io/badge/Node.js-20-green)](https://nodejs.org)
[![React](https://img.shields.io/badge/React-18-61DAFB)](https://react.dev)
[![TypeScript](https://img.shields.io/badge/TypeScript-5-blue)](https://www.typescriptlang.org)

---

## 📖 Tổng Quan

Dự án triển khai **full-stack application** (React + Node.js/Express) lên **Azure Cloud** với:
- ✅ OpenID Connect authentication (PKCE flow)
- ✅ HTTPS enforcement cho tất cả endpoints
- ✅ Dual deployment: **Azure Web App** (production) + **AKS** (learning)
- ✅ Containerization với Docker + Azure Container Registry
- ✅ Infrastructure as Code với Kubernetes manifests

**Mục tiêu học tập:** Thực hành end-to-end cloud deployment từ containerization, authentication, đến Kubernetes orchestration trên Azure.

---

## 🚀 Live Deployments

### Production (Azure Web App) ✅
- **Frontend**: https://mindx-week1-frontend.azurewebsites.net
- **Backend**: https://mindx-week1-backend.azurewebsites.net
- **Status**: Fully functional với HTTPS hợp lệ

### Learning Environment (AKS) ⚠️
- **Cluster**: mindx-week1-aks (East Asia, k8s 1.33.5)
- **Pods**: 4/4 Running (2 backend + 2 frontend replicas)
- **Access**: Port-forward only (Azure NSG chặn public traffic)
- **URL**: http://localhost:8080 (sau khi chạy port-forward)
- **Hướng dẫn**: [FIX_CONNECTION_TIMEOUT.md](./FIX_CONNECTION_TIMEOUT.md) - Fix lỗi ERR_CONNECTION_TIMED_OUT

---

## 🏗️ Architecture

```
Internet Users
      │
      ▼ HTTPS
┌──────────────────┐
│ Azure LB/Ingress │
└────┬────────┬────┘
     │        │
     ▼        ▼
┌─────────┐ ┌──────────┐
│Frontend │ │ Backend  │
│ React   │◄┤ Express  │
│ :8080   │ │ :3000    │
└─────────┘ └──────────┘
              │
              ▼
     ┌─────────────────┐
     │ OpenID Provider │
     │ id-dev.mindx    │
     └─────────────────┘
```

**Deployment Flow:**
1. Code → Docker build → Push to ACR
2. Deploy to Azure Web App (production)
3. Deploy to AKS (learning/testing)

---

## 🛠️ Tech Stack

| Layer | Technologies |
|-------|-------------|
| **Frontend** | React 18 + TypeScript + Vite + React Router |
| **Backend** | Node.js 20 + Express + TypeScript + OpenID |
| **Infrastructure** | Docker + Azure ACR + Azure Web App + AKS |
| **Security** | OpenID Connect (PKCE) + JWT + HTTPS |
| **DevOps** | Kubernetes + nginx-ingress + cert-manager |

---

## 📦 Project Structure

```
Test-w1/
├── backend/                  # Node.js/Express API
│   ├── src/index.ts         # Main server + OpenID auth
│   └── Dockerfile           # Backend container
├── frontend/                # React App
│   ├── src/
│   │   ├── components/      # Layout, ProtectedRoute
│   │   ├── pages/           # Home, About, AuthCallback
│   │   └── services/        # authService (PKCE flow)
│   └── Dockerfile           # Frontend container (Nginx)
├── k8s/                     # Kubernetes manifests
│   ├── backend-deployment.yaml
│   ├── react-deployment.yaml
│   └── ingress-https-ip.yaml
├── scripts/                 # Deployment utilities
└── docker-compose.yml       # Local development
```

---

## 🚦 Quick Start

### Prerequisites
- Node.js 20+ | Docker Desktop | Azure CLI | kubectl
- Access to `mindxweek1acr` Azure Container Registry

### Local Development

```bash
# Clone và start với Docker Compose
git clone <repository-url>
cd Test-w1
docker-compose up --build

# Access:
# Frontend: http://localhost:5173
# Backend: http://localhost:3000
```

### Environment Variables

**backend/.env**
```env
PORT=3000
OPENID_CLIENT_ID=mindx-onboarding
OPENID_CLIENT_SECRET=<your-secret>
```

**frontend/.env**
```env
VITE_API_BASE_URL=http://localhost:3000/api
VITE_OPENID_CLIENT_ID=mindx-onboarding
VITE_OPENID_REDIRECT_URI=http://localhost:5173/auth/callback
```

---

## 🌐 Deployment

### Deploy to Azure Web App

```powershell
# 1. Login và build images
az login
az acr login --name mindxweek1acr

cd backend
docker build -t mindxweek1acr.azurecr.io/mindx-week1-backend:latest .
docker push mindxweek1acr.azurecr.io/mindx-week1-backend:latest

cd ../frontend
docker build -t mindxweek1acr.azurecr.io/mindx-week1-frontend:latest .
docker push mindxweek1acr.azurecr.io/mindx-week1-frontend:latest

# 2. Restart Web Apps
az webapp restart --name mindx-week1-backend --resource-group mindx-intern-03-rg
az webapp restart --name mindx-week1-frontend --resource-group mindx-intern-03-rg
```

### Deploy to AKS

```powershell
# 1. Connect to cluster
az aks get-credentials --resource-group mindx-intern-03-rg --name mindx-week1-aks

# 2. Build và push (different tags)
docker build -t mindxweek1acr.azurecr.io/week1-backend:latest ./backend
docker push mindxweek1acr.azurecr.io/week1-backend:latest

docker build -t mindxweek1acr.azurecr.io/week1-frontend:latest ./frontend
docker push mindxweek1acr.azurecr.io/week1-frontend:latest

# 3. Deploy
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/react-deployment.yaml
kubectl apply -f k8s/ingress-https-ip.yaml

# 4. Test locally (port-forward)
.\scripts\aks-port-forward.ps1
# Access: http://localhost:8080
```

---

## 🔐 Authentication

**Provider:** https://id-dev.mindx.edu.vn (OpenID Connect)  
**Flow:** Authorization Code with PKCE  
**Client ID:** mindx-onboarding

### Required Redirect URIs
- Production: `https://mindx-week1-frontend.azurewebsites.net/auth/callback`
- Local: `http://localhost:5173/auth/callback`

### API Endpoints

| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /health` | No | Health check |
| `POST /api/auth/token` | No | Exchange code for token |
| `GET /api/auth/userinfo` | Yes | Get user info (Bearer token) |
| `GET /api/protected` | Yes | Protected endpoint demo |

**Example:**
```bash
# Get user info
curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://mindx-week1-backend.azurewebsites.net/api/auth/userinfo
```

---

## 🧪 Testing

```bash
# Health check
curl https://mindx-week1-backend.azurewebsites.net/health

# Protected endpoint (should return 401)
curl https://mindx-week1-backend.azurewebsites.net/api/protected

# Frontend
curl -I https://mindx-week1-frontend.azurewebsites.net/
```

**End-to-End Test:**
1. Open frontend → Login → Redirects to OpenID provider
2. Authenticate → Callback with code → Token exchange
3. Access "About" page (protected) → Requires authentication
4. Logout → Token cleared

---

## 📊 Monitoring

```powershell
# Azure Web App logs
az webapp log tail --name mindx-week1-backend --resource-group mindx-intern-03-rg

# AKS pods
kubectl get pods
kubectl logs -f deployment/backend-deployment

# Full status
.\scripts\aks-status.ps1
```

---

## 🐛 Common Issues

### AKS External Access (ERR_CONNECTION_TIMED_OUT)
**Cause:** Ports 80/443 blocked by Azure NSG  
**Solution:** Use port-forward (`.\scripts\aks-port-forward.ps1`) hoặc Azure Web App endpoints

### Authentication Redirect Loop
**Cause:** Redirect URI mismatch  
**Solution:** Verify `VITE_OPENID_REDIRECT_URI` matches IdP configuration

### CORS Errors
**Solution:** Check backend CORS config includes frontend origin

Chi tiết: [AKS_LOCAL_ACCESS.md](./AKS_LOCAL_ACCESS.md)

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [DEPLOYMENT.md](./DEPLOYMENT.md) | Detailed deployment guide |
| [AKS_GUIDE.md](./AKS_GUIDE.md) | AKS commands reference |
| [tasks.md](./tasks.md) | Step-by-step guide (6 steps) |
| [architecture.md](./architecture.md) | Architecture details |

**Learning Resources:**
- [Docker Docs](https://docs.docker.com/) | [Kubernetes Docs](https://kubernetes.io/docs/)
- [Azure AKS](https://learn.microsoft.com/azure/aks/) | [OpenID Connect](https://openid.net/connect/)

---

## ✅ Completion Status

### Week 1 Requirements - ALL COMPLETED ✅

- ✅ Backend API deployed qua public HTTPS
- ✅ Frontend deployed qua public HTTPS domain
- ✅ HTTPS enforced cho tất cả endpoints
- ✅ OpenID authentication integrated
- ✅ Login/logout functional
- ✅ Protected routes implemented
- ✅ Backend validates OpenID tokens
- ✅ Services running trên Azure Cloud
- ✅ Deployment configs committed
- ✅ Complete documentation

### Bonus ✅
- ✅ AKS deployment với 2 replicas each
- ✅ Ingress controller + SSL certificates
- ✅ Automated scripts + comprehensive docs

---

## 🎓 Next Steps (Week 2+)

- [ ] Database integration (PostgreSQL/MongoDB)
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Let's Encrypt certificates (requires network access)
- [ ] Monitoring (Azure Monitor/Prometheus)
- [ ] Automated testing (unit + integration)
- [ ] API rate limiting
- [ ] Custom domain

---

## 👥 Contributors

**HuyNQ** (MindX Engineer) | **Cursor AI** (Development Assistant)

---

## 📞 Project Info

**Version:** 1.0.0  
**Status:** ✅ Production Ready  
**Last Updated:** January 1, 2026

**Live Endpoints:**
- 🌐 Frontend: https://mindx-week1-frontend.azurewebsites.net
- 🔧 Backend: https://mindx-week1-backend.azurewebsites.net

---

**🎉 Week 1 Complete! All objectives achieved.**
