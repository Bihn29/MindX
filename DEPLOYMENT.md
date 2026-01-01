# Deployment Guide - Week 1 Full-Stack Application

## Overview
This document provides comprehensive deployment information for the Week 1 full-stack application, including both Azure Web App and Azure Kubernetes Service (AKS) deployments.

## Table of Contents
- [Deployed Services](#deployed-services)
- [Architecture](#architecture)
- [Authentication Configuration](#authentication-configuration)
- [Deployment Methods](#deployment-methods)
- [Testing & Verification](#testing--verification)
- [Troubleshooting](#troubleshooting)

---

## Deployed Services

### Azure Web App (Primary Production Endpoints)

#### Backend API
- **URL**: https://mindx-week1-backend.azurewebsites.net
- **Health Check**: https://mindx-week1-backend.azurewebsites.net/health
- **Protected Endpoint**: https://mindx-week1-backend.azurewebsites.net/api/protected
- **Image**: `mindxweek1acr.azurecr.io/mindx-week1-backend:latest`
- **Port**: 3000
- **Status**: Running with HTTPS enforced

#### Frontend Web App
- **URL**: https://mindx-week1-frontend.azurewebsites.net
- **Image**: `mindxweek1acr.azurecr.io/mindx-week1-frontend:latest`
- **Port**: 8080
- **Status**: Running with HTTPS enforced
- **API Base URL**: https://mindx-week1-backend.azurewebsites.net/api

### Azure Kubernetes Service (AKS)

#### Cluster Information
- **Cluster Name**: mindx-week1-aks
- **Resource Group**: mindx-intern-03-rg
- **Location**: East Asia
- **Kubernetes Version**: 1.33.5
- **Node Count**: 1

#### Ingress Configuration
- **Ingress Controller**: nginx-ingress (LoadBalancer)
- **External IP**: 20.24.116.192
- **Domain**: 20.24.116.192.nip.io
- **HTTPS**: Self-signed certificate (cert-manager with selfsigned-issuer)
- **Status**: ⚠️ External ports 80/443 not publicly accessible (network restriction)

#### Deployed Services
1. **Backend Deployment**
   - Name: `backend-deployment`
   - Replicas: 2
   - Image: `mindxweek1acr.azurecr.io/week1-backend:latest`
   - Service: `backend-service` (ClusterIP, port 3000)
   - Health: Running

2. **Frontend Deployment**
   - Name: `react-app-deployment`
   - Replicas: 2
   - Image: `mindxweek1acr.azurecr.io/week1-frontend:latest`
   - Service: `react-app-service` (ClusterIP, port 8080)
   - Health: Running

3. **Ingress Resource**
   - Name: `fullstack-ingress-https`
   - Routing:
     - `/` → React App (port 8080)
     - `/api/*` → Backend API (port 3000)
     - `/health` → Backend health check
   - TLS: Self-signed certificate (mindx-week1-tls-secret)

---

## Architecture

### Deployment Flow
```
Local Development
      ↓
  Docker Build
      ↓
  Push to ACR (mindxweek1acr.azurecr.io)
      ↓
  ┌───────────────────────────────────┐
  │                                   │
  ↓                                   ↓
Azure Web App              Azure Kubernetes Service (AKS)
(Production)                    (Alternative/Learning)
  │                                   │
  ↓                                   ↓
HTTPS Endpoints              Ingress Controller (nginx)
(Public Access)              (Currently restricted access)
```

### Authentication Flow
```
User → Frontend (React)
         ↓
    Login Request
         ↓
  OpenID Provider (id-dev.mindx.edu.vn)
         ↓
  Authorization Code (PKCE)
         ↓
    Frontend receives code
         ↓
  POST /api/auth/token (Backend)
         ↓
  Backend exchanges code for tokens
         ↓
  Access Token returned to Frontend
         ↓
  Protected API calls with Bearer token
         ↓
  Backend validates token via /me endpoint
```

---

## Authentication Configuration

### OpenID Connect Settings
- **Provider**: https://id-dev.mindx.edu.vn
- **Authorization Endpoint**: https://id-dev.mindx.edu.vn/auth
- **Token Endpoint**: https://id-dev.mindx.edu.vn/token
- **UserInfo Endpoint**: https://id-dev.mindx.edu.vn/me
- **Client ID**: `mindx-onboarding`
- **Flow**: Authorization Code with PKCE
- **Response Type**: `code`
- **Scopes**: `openid profile email`

### Required Redirect URIs (Whitelist on IdP)
Configure the following redirect URIs in the OpenID provider admin panel:

1. **Production (Azure Web App)**:
   - `https://mindx-week1-frontend.azurewebsites.net/auth/callback`

2. **AKS Deployment** (if/when public access is enabled):
   - `https://20.24.116.192.nip.io/auth/callback`

3. **Local Development**:
   - `http://localhost:5173/auth/callback`

### Environment Variables

#### Backend (Azure Web App)
```bash
OPENID_CLIENT_ID=mindx-onboarding
OPENID_CLIENT_SECRET=<base64-encoded-secret>
WEBSITES_PORT=3000
NODE_ENV=production
```

#### Frontend (Azure Web App)
```bash
VITE_API_BASE_URL=https://mindx-week1-backend.azurewebsites.net/api
VITE_OPENID_CLIENT_ID=mindx-onboarding
WEBSITES_PORT=8080
```

---

## Deployment Methods

### Method 1: Azure Web App (Recommended for Production)

#### Prerequisites
- Azure CLI installed and authenticated
- Docker installed
- Access to ACR: `mindxweek1acr.azurecr.io`

#### Deploy Backend
```powershell
# Login to ACR
az acr login --name mindxweek1acr

# Build and push backend
cd backend
docker build -t mindxweek1acr.azurecr.io/mindx-week1-backend:latest .
docker push mindxweek1acr.azurecr.io/mindx-week1-backend:latest

# Restart Web App to pull new image
az webapp restart --name mindx-week1-backend --resource-group mindx-intern-03-rg

# Verify
curl -I https://mindx-week1-backend.azurewebsites.net/health
```

#### Deploy Frontend
```powershell
# Build and push frontend
cd frontend
docker build -t mindxweek1acr.azurecr.io/mindx-week1-frontend:latest .
docker push mindxweek1acr.azurecr.io/mindx-week1-frontend:latest

# Restart Web App
az webapp restart --name mindx-week1-frontend --resource-group mindx-intern-03-rg

# Verify
curl -I https://mindx-week1-frontend.azurewebsites.net/
```

### Method 2: Azure Kubernetes Service (AKS)

#### Prerequisites
- kubectl installed
- Helm installed
- AKS credentials configured
- Access to ACR

#### Setup AKS Access
```powershell
# Get AKS credentials
az aks get-credentials --resource-group mindx-intern-03-rg --name mindx-week1-aks --overwrite-existing

# Verify connection
kubectl get nodes
```

#### Deploy to AKS
```powershell
# Build and push images (use week1-* tags for AKS)
docker build -t mindxweek1acr.azurecr.io/week1-backend:latest ./backend
docker push mindxweek1acr.azurecr.io/week1-backend:latest

docker build -t mindxweek1acr.azurecr.io/week1-frontend:latest ./frontend
docker push mindxweek1acr.azurecr.io/week1-frontend:latest

# Deploy backend
kubectl apply -f k8s/backend-deployment.yaml

# Deploy frontend
kubectl apply -f k8s/react-deployment.yaml

# Apply ingress
kubectl apply -f k8s/ingress-https-ip.yaml

# Check status
kubectl get pods,svc,ingress
```

#### Install Ingress Controller (if not installed)
```powershell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx `
    --namespace ingress-nginx `
    --create-namespace `
    --set controller.service.type=LoadBalancer
```

#### Install cert-manager (if not installed)
```powershell
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager `
    --namespace cert-manager `
    --create-namespace `
    --set installCRDs=true

# Apply self-signed issuer
kubectl apply -f k8s/self-signed-issuer.yaml
```

### Method 3: Automated Deployment Scripts

#### Full HTTPS Deployment
```powershell
.\scripts\deploy-full-https.ps1 `
    -AcrName "mindxweek1acr" `
    -DomainName "20.24.116.192.nip.io" `
    -Email "binhnt@mindx.com.vn" `
    -ResourceGroup "mindx-intern-03-rg" `
    -AksCluster "mindx-week1-aks" `
    -SkipIngressInstall `
    -SkipCertManager
```

---

## Testing & Verification

### Backend API Endpoints

#### Health Check
```powershell
# Azure Web App
curl https://mindx-week1-backend.azurewebsites.net/health

# Expected response:
{
  "status": "healthy",
  "timestamp": "2026-01-01T12:00:00.000Z",
  "uptime": 12345.67,
  "environment": "production"
}
```

#### Protected Endpoint (Requires Authentication)
```powershell
# Without token - should return 401
curl https://mindx-week1-backend.azurewebsites.net/api/protected

# With valid token
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" `
     https://mindx-week1-backend.azurewebsites.net/api/protected
```

#### Token Exchange
```powershell
# Exchange authorization code for tokens
curl -X POST https://mindx-week1-backend.azurewebsites.net/api/auth/token `
     -H "Content-Type: application/json" `
     -d '{
       "code": "authorization_code",
       "code_verifier": "verifier",
       "redirect_uri": "https://mindx-week1-frontend.azurewebsites.net/auth/callback"
     }'
```

#### User Info
```powershell
# Get user info with access token
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" `
     https://mindx-week1-backend.azurewebsites.net/api/auth/userinfo
```

### Frontend Application

#### Access Application
```powershell
# Open in browser
start https://mindx-week1-frontend.azurewebsites.net/

# Test home page
curl -I https://mindx-week1-frontend.azurewebsites.net/
```

#### Test Authentication Flow
1. Navigate to: https://mindx-week1-frontend.azurewebsites.net/
2. Click "Đăng nhập" button
3. Redirected to OpenID provider login
4. Login with credentials
5. Redirected back to `/auth/callback`
6. Access token stored in localStorage
7. Access protected route `/about`

### AKS Cluster Verification

#### Check Deployments
```powershell
# View all resources
kubectl get all -n default

# Check backend pods
kubectl get pods -l app=backend
kubectl logs -l app=backend --tail=50

# Check frontend pods
kubectl get pods -l app=react-app
kubectl logs -l app=react-app --tail=50

# Check ingress
kubectl get ingress fullstack-ingress-https
kubectl describe ingress fullstack-ingress-https
```

#### Port Forward Testing (if external access unavailable)
```powershell
# Port forward to backend
kubectl port-forward svc/backend-service 3000:3000

# Test in another terminal
curl http://localhost:3000/health

# Port forward to frontend
kubectl port-forward svc/react-app-service 8080:8080

# Open in browser
start http://localhost:8080
```

#### Certificate Status
```powershell
# Check certificate
kubectl get certificate -n default

# Check certificate details
kubectl describe certificate mindx-week1-tls

# View TLS secret
kubectl get secret mindx-week1-tls-secret -o yaml
```

---

## Troubleshooting

### Azure Web App Issues

#### Container Not Starting
```powershell
# View logs
az webapp log tail --name mindx-week1-backend --resource-group mindx-intern-03-rg

# Check configuration
az webapp config show --name mindx-week1-backend --resource-group mindx-intern-03-rg

# Check app settings
az webapp config appsettings list --name mindx-week1-backend --resource-group mindx-intern-03-rg
```

#### Image Pull Errors
```powershell
# Verify ACR access
az acr login --name mindxweek1acr

# List images
az acr repository list --name mindxweek1acr

# Check specific image tags
az acr repository show-tags --name mindxweek1acr --repository mindx-week1-backend
```

### AKS Issues

#### Pods Not Starting
```powershell
# Describe pod
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check image pull secret
kubectl get secret acr-secret -o yaml
```

#### Ingress Issues
```powershell
# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Get external IP
kubectl get svc ingress-nginx-controller -n ingress-nginx

# Test ingress rules
kubectl describe ingress fullstack-ingress-https
```

#### Certificate Issues
```powershell
# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Check certificate status
kubectl describe certificate mindx-week1-tls

# Check certificate request
kubectl get certificaterequest

# For Let's Encrypt (if using):
kubectl get order,challenge
```

### Authentication Issues

#### Login Redirect Not Working
- Verify redirect URI is whitelisted in OpenID provider
- Check browser console for errors
- Verify frontend environment variables:
  ```powershell
  az webapp config appsettings list --name mindx-week1-frontend `
      --resource-group mindx-intern-03-rg `
      --query "[?starts_with(name, 'VITE_')]"
  ```

#### Token Exchange Failing
- Check backend logs for detailed error
- Verify backend has correct OPENID_CLIENT_ID and OPENID_CLIENT_SECRET
- Test token endpoint manually:
  ```powershell
  curl https://id-dev.mindx.edu.vn/token
  ```

#### Protected Endpoint Returns 401
- Verify access token is valid
- Check token hasn't expired
- Test userinfo endpoint:
  ```powershell
  curl -H "Authorization: Bearer TOKEN" https://id-dev.mindx.edu.vn/me
  ```

---

## Rollback Procedures

### Azure Web App Rollback
```powershell
# List deployment history
az webapp deployment list --name mindx-week1-backend --resource-group mindx-intern-03-rg

# Rollback to specific image tag
# 1. Build/push older version with specific tag
# 2. Update Web App to use that tag
# 3. Restart
```

### AKS Rollback
```powershell
# Rollback deployment
kubectl rollout undo deployment/backend-deployment
kubectl rollout undo deployment/react-app-deployment

# Check rollout status
kubectl rollout status deployment/backend-deployment

# View rollout history
kubectl rollout history deployment/backend-deployment
```

---

## Next Steps for Full Production

### Enable Public Access to AKS Ingress
**Current Issue**: External IP 20.24.116.192 is not accessible from internet (ports 80/443 blocked)

**Required Actions**:
1. Contact Azure/Network admin to configure Network Security Group (NSG) rules
2. Allow inbound traffic on ports 80 and 443 to ingress LoadBalancer
3. Verify with: `Test-NetConnection -ComputerName 20.24.116.192 -Port 80`

### Migrate to Let's Encrypt (Valid SSL Certificate)
Once public access is enabled:

```powershell
# Apply Let's Encrypt ClusterIssuer
kubectl apply -f k8s/cert-manager.yaml

# Update ingress to use letsencrypt-prod
# Edit k8s/ingress-https-ip.yaml to add:
# cert-manager.io/cluster-issuer: "letsencrypt-prod"

kubectl apply -f k8s/ingress-https-ip.yaml

# Monitor certificate issuance
kubectl get certificate -w
```

### Configure Custom Domain
1. Purchase/configure custom domain
2. Add DNS A record pointing to ingress external IP
3. Update ingress host to use custom domain
4. Update OpenID redirect URIs with new domain
5. Reissue SSL certificate for new domain

---

## Summary

✅ **Completed Steps**:
- Backend API with OpenID authentication deployed
- Frontend React app with authentication flow deployed
- Both deployed to Azure Web App (HTTPS with valid certificates)
- Both deployed to AKS (HTTPS with self-signed certificates)
- Protected endpoints with token validation
- All services running on Azure Cloud

⚠️ **Limitations**:
- AKS ingress not publicly accessible (network restriction)
- AKS using self-signed certificates (cannot use Let's Encrypt without public access)

🎯 **Production Ready on Azure Web App**:
- Public HTTPS endpoints: ✅
- Authentication integration: ✅
- Token validation: ✅
- Protected routes: ✅

For production use, **Azure Web App deployment** is recommended until AKS ingress networking is resolved.
