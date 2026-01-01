# AKS Local Access Guide

## ⚠️ External IP Blocked Issue

**Problem**: External IP `20.24.116.192` ports 80/443 are not accessible from internet due to Azure Network Security Group restrictions.

**Error**: `ERR_CONNECTION_TIMED_OUT` when accessing https://20.24.116.192.nip.io

**Root Cause**: Azure firewall/NSG blocking inbound traffic on ports 80 and 443 to the LoadBalancer IP.

---

## ✅ Solution: Use Port-Forward for Local Testing

### Quick Start (Recommended)

**Option 1: Automated Script**
```powershell
# Start port-forwarding for both services
.\scripts\aks-port-forward.ps1

# Then access:
# Frontend: http://localhost:8080
# Backend:  http://localhost:3000
```

**Option 2: Manual Port-Forward**
```powershell
# Terminal 1 - Backend
kubectl port-forward svc/backend-service 3000:3000

# Terminal 2 - Frontend  
kubectl port-forward svc/react-app-service 8080:8080

# Terminal 3 - Test
curl http://localhost:3000/health
start http://localhost:8080
```

---

## 🔧 Step-by-Step Testing Guide

### 1. Start Backend Port-Forward

Open PowerShell terminal:
```powershell
kubectl port-forward svc/backend-service 3000:3000
```

Leave this terminal running. You should see:
```
Forwarding from 127.0.0.1:3000 -> 3000
Forwarding from [::1]:3000 -> 3000
```

### 2. Test Backend API

Open a new PowerShell terminal:
```powershell
# Health check
curl http://localhost:3000/health

# Expected output:
# {
#   "status": "healthy",
#   "timestamp": "2026-01-01T...",
#   "uptime": 123.45,
#   "environment": "production"
# }

# Test protected endpoint (should return 401)
curl http://localhost:3000/api/protected

# Expected: 401 Unauthorized
```

### 3. Start Frontend Port-Forward

Open another PowerShell terminal:
```powershell
kubectl port-forward svc/react-app-service 8080:8080
```

### 4. Access Frontend Application

Open browser and navigate to:
```
http://localhost:8080
```

**Note**: Frontend will try to call backend at `/api/*` which will be proxied through nginx inside the container.

---

## 🌐 For Production Access

**Use Azure Web App endpoints instead of AKS:**

- **Frontend**: https://mindx-week1-frontend.azurewebsites.net
- **Backend**: https://mindx-week1-backend.azurewebsites.net

These endpoints have:
- ✅ Valid HTTPS certificates
- ✅ Public accessibility
- ✅ Full authentication flow
- ✅ All features working

---

## 🔍 Verify AKS Internal Connectivity

Even though external access is blocked, you can verify services are working internally:

### Method 1: Exec into Pod
```powershell
# Get a backend pod name
kubectl get pods -l app=backend

# Exec into the pod
kubectl exec -it <backend-pod-name> -- sh

# Inside the pod, test services:
wget -O- http://backend-service:3000/health
wget -O- http://react-app-service:8080
exit
```

### Method 2: Temporary Test Pod
```powershell
# Run a test pod
kubectl run test-curl --image=curlimages/curl --rm -it -- sh

# Inside the pod:
curl http://backend-service:3000/health
curl http://react-app-service:8080
exit
```

---

## 🛠️ Troubleshooting

### Port-Forward Not Working?

**Check if services exist:**
```powershell
kubectl get svc
```

Expected output should include:
- `backend-service` (ClusterIP, port 3000)
- `react-app-service` (ClusterIP, port 8080)

**Check if pods are running:**
```powershell
kubectl get pods
```

All pods should be in `Running` status.

**Restart port-forward:**
- Press `Ctrl+C` to stop current port-forward
- Run the command again

### Backend Returns Error?

**Check backend logs:**
```powershell
kubectl logs -l app=backend --tail=50
```

**Restart backend if needed:**
```powershell
kubectl rollout restart deployment/backend-deployment
kubectl rollout status deployment/backend-deployment
```

### Frontend Not Loading?

**Check frontend logs:**
```powershell
kubectl logs -l app=react-app --tail=50
```

**Restart frontend if needed:**
```powershell
kubectl rollout restart deployment/react-app-deployment
kubectl rollout status deployment/react-app-deployment
```

---

## 📋 Testing Checklist

- [ ] AKS cluster credentials configured (`kubectl get nodes` works)
- [ ] Backend port-forward running on localhost:3000
- [ ] Backend health check returns 200 OK
- [ ] Frontend port-forward running on localhost:8080  
- [ ] Frontend loads in browser
- [ ] Can navigate to different routes
- [ ] (Optional) Authentication flow works

---

## 🚀 Next Steps to Enable External Access

**If you need public access to AKS, contact Azure/Network admin to:**

1. **Configure Network Security Group (NSG)**
   - Allow inbound traffic on port 80 (HTTP)
   - Allow inbound traffic on port 443 (HTTPS)
   - Apply to LoadBalancer subnet/IP

2. **Verify with:**
   ```powershell
   Test-NetConnection -ComputerName 20.24.116.192 -Port 80
   Test-NetConnection -ComputerName 20.24.116.192 -Port 443
   ```
   
   Both should return `TcpTestSucceeded: True`

3. **Once accessible, enable Let's Encrypt:**
   ```powershell
   # Certificate will auto-issue via HTTP-01 challenge
   kubectl get certificate -w
   ```

---

## 💡 Summary

| Access Method | Status | Use Case |
|---------------|--------|----------|
| https://20.24.116.192.nip.io | ❌ Blocked | N/A - Network restricted |
| kubectl port-forward | ✅ Working | Local testing & development |
| Azure Web App | ✅ Working | **Production access** |

**Recommendation**: Use **Azure Web App** for production, **port-forward** for AKS testing.

---

## 📞 Quick Help Commands

```powershell
# Check everything is running
.\scripts\aks-status.ps1

# Start testing environment
.\scripts\aks-port-forward.ps1

# View comprehensive guide
Get-Content AKS_GUIDE.md

# Check this guide
Get-Content AKS_LOCAL_ACCESS.md
```

---

**Last Updated**: January 1, 2026  
**Issue**: External IP blocked by network security  
**Workaround**: Port-forwarding for local access  
**Production**: Use Azure Web App endpoints
