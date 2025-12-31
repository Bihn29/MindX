# Kubernetes Manifests

This directory contains Kubernetes manifests for deploying the application to Azure Kubernetes Service (AKS).

## Files

- `backend-deployment.yaml` - Deployment and Service for the Backend
- `ingress.yaml` - Ingress configuration (to be added in Step 3)
- `react-deployment.yaml` - Deployment and Service for React app (to be added in Step 4)

## Usage

### Prerequisites

- AKS cluster created and configured
- kubectl configured to access the cluster
- Azure Container Registry (ACR) with images pushed
- ACR integrated with AKS for image pull authentication

### Deploy Backend

1. Update the image reference in `backend-deployment.yaml`:
   ```yaml
   image: <ACR_NAME>.azurecr.io/week1-backend:latest
   ```

2. Apply the deployment:
   ```bash
   kubectl apply -f backend-deployment.yaml
   ```

3. Verify deployment:
   ```bash
   kubectl get deployments
   kubectl get pods
   kubectl get services
   ```

4. Test via port-forwarding:
   ```bash
   kubectl port-forward service/backend-service 3000:3000
   curl http://localhost:3000/health
   ```

## ACR Integration

To allow AKS to pull images from ACR, ensure ACR is attached to AKS:

```bash
az aks update -n <aks-cluster-name> -g <resource-group> --attach-acr <acr-name>
```

Or manually configure image pull secrets if needed.

