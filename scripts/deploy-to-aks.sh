#!/bin/bash

# Script to deploy API to AKS
# Usage: ./scripts/deploy-to-aks.sh <acr-name>

set -e

ACR_NAME=${1:-"myregistry"}

if [ -z "$ACR_NAME" ]; then
    echo "Error: ACR name is required"
    echo "Usage: ./scripts/deploy-to-aks.sh <acr-name>"
    exit 1
fi

echo "📝 Updating Kubernetes manifests with ACR name..."
sed -i.bak "s/<ACR_NAME>/${ACR_NAME}/g" k8s/backend-deployment.yaml
rm -f k8s/backend-deployment.yaml.bak

echo "🚀 Deploying Backend to AKS..."
kubectl apply -f k8s/backend-deployment.yaml

echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/backend-deployment

echo "✅ Deployment complete!"
echo ""
echo "📋 Deployment status:"
kubectl get deployments
kubectl get pods -l app=backend
kubectl get services -l app=backend

echo ""
echo "🔍 To test the Backend, use port-forwarding:"
echo "   kubectl port-forward service/backend-service 3000:3000"
echo "   curl http://localhost:3000/health"

