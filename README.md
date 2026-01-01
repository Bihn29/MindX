# Week 1 Full-Stack Application - MindX Engineer Onboarding

A production-ready full-stack application deployed on Azure Cloud with OpenID Connect authentication.

## 🚀 Live Deployments

### Production (Azure Web App - Recommended)
- **Frontend**: https://mindx-week1-frontend.azurewebsites.net
- **Backend API**: https://mindx-week1-backend.azurewebsites.net
- **Status**: ✅ Fully functional with HTTPS

### AKS Deployment (Learning Environment)
- **Ingress Domain**: https://20.24.116.192.nip.io
- **Status**: ⚠️ Limited external access (network restriction)

## 📋 Features

- ✅ **Full-Stack Application**: React frontend + Node.js/Express backend
- ✅ **OpenID Authentication**: Integration with https://id-dev.mindx.edu.vn
- ✅ **HTTPS Enforcement**: All services secured with SSL/TLS
- ✅ **Protected Routes**: Frontend routes requiring authentication
- ✅ **Token Validation**: Backend validates and authorizes OpenID tokens
- ✅ **Cloud Deployment**: Azure Web App + Azure Kubernetes Service
- ✅ **Container Registry**: Images stored in Azure Container Registry
- ✅ **Infrastructure as Code**: Kubernetes manifests and deployment scripts

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Internet Users                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │  Azure Load Balancer       │
        │  (HTTPS - Valid Cert)      │
        └─────┬──────────────────┬───┘
              │                  │
              ▼                  ▼
    ┌─────────────────┐  ┌─────────────────┐
    │  Frontend       │  │  Backend API    │
    │  (React App)    │  │  (Express)      │
    │  Port: 8080     │  │  Port: 3000     │
    └─────────────────┘  └─────────────────┘
              │                  │
              └──────┬───────────┘
                     ▼
            ┌────────────────────┐
            │  OpenID Provider   │
            │  id-dev.mindx.edu.vn│
            └────────────────────┘
```

## 🛠️ Technology Stack

### Frontend
- React 18 + TypeScript
- Vite (build tool)
- React Router (routing)
- OpenID Connect (authentication)

### Backend
- Node.js 20
- Express.js
- TypeScript
- OpenID Connect integration
- CORS enabled

### Infrastructure
- Azure Container Registry (ACR)
- Azure Web App for Containers
- Azure Kubernetes Service (AKS)
- nginx-ingress controller
- cert-manager (SSL certificates)

## 📦 Project Structure

```
Test-w1/
├── backend/                    # Backend API (Node.js/Express)
│   ├── src/
│   │   └── index.ts           # Main API server with OpenID endpoints
│   ├── Dockerfile             # Backend container image
│   ├── package.json
│   └── tsconfig.json
├── frontend/                   # Frontend React App
│   ├── src/
│   │   ├── components/        # React components
│   │   │   ├── Layout.tsx
│   │   │   └── ProtectedRoute.tsx
│   │   ├── pages/             # Page components
│   │   │   ├── Home.tsx
│   │   │   ├── About.tsx
│   │   │   └── AuthCallback.tsx
│   │   ├── services/
│   │   │   └── authService.ts # OpenID authentication logic
│   │   └── App.tsx
│   ├── Dockerfile             # Frontend container image
│   ├── nginx.conf             # Nginx configuration
│   ├── package.json
│   └── vite.config.ts
├── k8s/                        # Kubernetes manifests
│   ├── backend-deployment.yaml
│   ├── react-deployment.yaml
│   ├── ingress-https-ip.yaml
│   ├── cert-manager.yaml
│   └── self-signed-issuer.yaml
├── scripts/                    # Deployment scripts
│   ├── deploy-https.ps1
│   └── deploy-full-https.ps1
├── docker-compose.yml          # Local development
├── DEPLOYMENT.md              # Deployment guide
├── architecture.md            # Architecture documentation
├── tasks.md                   # Step-by-step guide
└── overview.md                # Project overview
```

## 🚦 Quick Start

### Prerequisites
- Node.js 20+
- Docker Desktop
- Azure CLI
- kubectl (for AKS deployment)
- Access to `mindxweek1acr` Azure Container Registry

### Local Development

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd Test-w1
   ```

2. **Start with Docker Compose**
   ```bash
   docker-compose up --build
   ```

3. **Access Locally**
   - Frontend: http://localhost:5173
   - Backend: http://localhost:3000

### Environment Variables

Create `.env` files for local development:

**backend/.env**
```env
PORT=3000
NODE_ENV=development
OPENID_CLIENT_ID=mindx-onboarding
OPENID_CLIENT_SECRET=<your-secret>
```

**frontend/.env**
```env
VITE_API_BASE_URL=/api
VITE_OPENID_CLIENT_ID=mindx-onboarding
VITE_OPENID_PROMPT=login
```

## 🌐 Deployment

### Deploy to Azure Web App

```powershell
# Login to Azure and ACR
az login
az acr login --name mindxweek1acr

# Build and push backend
cd backend
docker build -t mindxweek1acr.azurecr.io/mindx-week1-backend:latest .
docker push mindxweek1acr.azurecr.io/mindx-week1-backend:latest

# Build and push frontend
cd ../frontend
docker build -t mindxweek1acr.azurecr.io/mindx-week1-frontend:latest .
docker push mindxweek1acr.azurecr.io/mindx-week1-frontend:latest

# Restart Web Apps
az webapp restart --name mindx-week1-backend --resource-group mindx-intern-03-rg
az webapp restart --name mindx-week1-frontend --resource-group mindx-intern-03-rg
```

### Deploy to AKS

```powershell
# Get AKS credentials
az aks get-credentials --resource-group mindx-intern-03-rg --name mindx-week1-aks

# Build and push images (use week1-* tags)
docker build -t mindxweek1acr.azurecr.io/week1-backend:latest ./backend
docker push mindxweek1acr.azurecr.io/week1-backend:latest

docker build -t mindxweek1acr.azurecr.io/week1-frontend:latest ./frontend
docker push mindxweek1acr.azurecr.io/week1-frontend:latest

# Deploy to cluster
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/react-deployment.yaml
kubectl apply -f k8s/ingress-https-ip.yaml

# Verify
kubectl get pods,svc,ingress
```

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed deployment instructions.

## 🔐 Authentication

### OpenID Connect Configuration

- **Provider**: https://id-dev.mindx.edu.vn
- **Client ID**: `mindx-onboarding`
- **Flow**: Authorization Code with PKCE
- **Scopes**: `openid profile email`

### Required Redirect URIs

Configure these URIs in the OpenID provider admin panel:

- Production: `https://mindx-week1-frontend.azurewebsites.net/auth/callback`
- AKS: `https://20.24.116.192.nip.io/auth/callback` (when accessible)
- Local: `http://localhost:5173/auth/callback`

### Authentication Flow

1. User clicks "Login" on frontend
2. Frontend redirects to OpenID provider with PKCE challenge
3. User authenticates with provider
4. Provider redirects back with authorization code
5. Frontend sends code + verifier to backend `/api/auth/token`
6. Backend exchanges code for access token
7. Frontend stores token and makes authenticated API calls
8. Backend validates token on protected endpoints

## 📡 API Endpoints

### Public Endpoints
- `GET /health` - Health check
- `GET /` - Hello world
- `GET /api/info` - API information

### Authentication Endpoints
- `POST /api/auth/token` - Exchange authorization code for tokens
- `GET /api/auth/userinfo` - Get user information (requires Bearer token)

### Protected Endpoints
- `GET /api/protected` - Demonstrates token validation (requires Bearer token)

### Example API Call

```bash
# Get user info with access token
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
     https://mindx-week1-backend.azurewebsites.net/api/auth/userinfo

# Access protected endpoint
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
     https://mindx-week1-backend.azurewebsites.net/api/protected
```

## 🧪 Testing

### Backend Health Check
```bash
curl https://mindx-week1-backend.azurewebsites.net/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2026-01-01T12:00:00.000Z",
  "uptime": 12345.67,
  "environment": "production"
}
```

### Frontend Access
```bash
curl -I https://mindx-week1-frontend.azurewebsites.net/
```

Expected: HTTP 200 OK

### Protected Endpoint (No Token)
```bash
curl https://mindx-week1-backend.azurewebsites.net/api/protected
```

Expected: HTTP 401 Unauthorized

## 📊 Monitoring

### Azure Web App
```powershell
# View logs
az webapp log tail --name mindx-week1-backend --resource-group mindx-intern-03-rg

# Check status
az webapp show --name mindx-week1-backend --resource-group mindx-intern-03-rg --query state
```

### AKS
```powershell
# View pods
kubectl get pods -n default

# View logs
kubectl logs -l app=backend --tail=50
kubectl logs -l app=react-app --tail=50

# Check ingress
kubectl get ingress
```

## 🐛 Troubleshooting

### Common Issues

**Issue**: Login redirect not working
- **Solution**: Verify redirect URI is whitelisted in OpenID provider

**Issue**: Token exchange fails
- **Solution**: Check backend logs and verify OPENID_CLIENT_SECRET is correct

**Issue**: Protected endpoint returns 401
- **Solution**: Verify access token is valid and not expired

**Issue**: AKS ingress not accessible
- **Solution**: This is a known limitation due to network restrictions. Use Azure Web App endpoints instead.

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed troubleshooting steps.

## 📚 Documentation

- [DEPLOYMENT.md](./DEPLOYMENT.md) - Comprehensive deployment guide
- [architecture.md](./architecture.md) - Architecture documentation
- [tasks.md](./tasks.md) - Step-by-step implementation guide
- [overview.md](./overview.md) - Project objectives and acceptance criteria

## ✅ Acceptance Criteria Status

- ✅ Backend API deployed and accessible via public HTTPS endpoint
- ✅ Frontend React app deployed and accessible via public HTTPS domain
- ✅ HTTPS enforced for all endpoints (frontend and backend)
- ✅ Authentication integrated using OpenID with https://id-dev.mindx.edu.vn
- ✅ Users can log in and log out via frontend using OpenID
- ✅ Authenticated users can access protected routes/pages
- ✅ Backend API validates and authorizes requests using OpenID token
- ✅ All services running on Azure Cloud infrastructure
- ✅ Deployment scripts/configs committed to repository
- ✅ Documentation provided for setup, deployment, and authentication flow

## 🎯 Next Steps

### For Full AKS Production
1. Configure network security groups to allow public access to ingress IP
2. Migrate from self-signed to Let's Encrypt certificates
3. Configure custom domain and update DNS
4. Update OpenID redirect URIs with new domain

### For Enhanced Features
- Add user profile page
- Implement refresh token rotation
- Add API rate limiting
- Set up monitoring and alerting
- Configure auto-scaling

## 👥 Contributors

- HuyNQ (MindX)
- Cursor AI

## 📄 License

This project is part of the MindX Engineer Onboarding program.

---

**Last Updated**: January 1, 2026  
**Version**: 1.0.0  
**Status**: ✅ Production Ready (Azure Web App)
