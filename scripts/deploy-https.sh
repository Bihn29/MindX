#!/bin/bash

# Script to deploy application with HTTPS on AKS
# Usage: ./scripts/deploy-https.sh <acr-name> <domain-name> <email>

set -e

ACR_NAME=${1:-""}
DOMAIN_NAME=${2:-""}
EMAIL=${3:-""}

if [ -z "$ACR_NAME" ] || [ -z "$DOMAIN_NAME" ] || [ -z "$EMAIL" ]; then
    echo "Error: Missing required parameters"
    echo "Usage: ./scripts/deploy-https.sh <acr-name> <domain-name> <email>"
    echo ""
    echo "Example:"
    echo "  ./scripts/deploy-https.sh myregistry dev.example.com admin@example.com"
    exit 1
fi

echo "🚀 Starting HTTPS deployment..."
echo "ACR Name: $ACR_NAME"
echo "Domain: $DOMAIN_NAME"
echo "Email: $EMAIL"
echo ""

# Step 1: Update manifests with ACR name
echo "📝 Updating manifests with ACR name..."
sed -i.bak "s/<ACR_NAME>/$ACR_NAME/g" k8s/backend-deployment.yaml
sed -i.bak "s/<ACR_NAME>/$ACR_NAME/g" k8s/react-deployment.yaml
rm -f k8s/*.bak

# Step 2: Update cert-manager with email
echo "📝 Updating cert-manager with email..."
sed -i.bak "s/<your-email@example.com>/$EMAIL/g" k8s/cert-manager.yaml
rm -f k8s/cert-manager.yaml.bak

# Step 3: Update ingress-https with domain
echo "📝 Updating ingress-https with domain..."
sed -i.bak "s|<your-domain.com>|$DOMAIN_NAME|g" k8s/ingress-https.yaml
rm -f k8s/ingress-https.yaml.bak

# Step 4: Deploy backend and frontend
echo "🚀 Deploying backend and frontend..."
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/react-deployment.yaml

# Step 5: Apply cert-manager ClusterIssuer
echo "🔐 Applying cert-manager ClusterIssuer..."
kubectl apply -f k8s/cert-manager.yaml

# Step 6: Apply HTTPS ingress
echo "🌐 Applying HTTPS ingress..."
kubectl apply -f k8s/ingress-https.yaml

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. Configure DNS A record pointing to Ingress external IP:"
echo "   kubectl get service ingress-nginx-controller -n ingress-nginx"
echo ""
echo "2. Wait for certificate to be issued (may take a few minutes):"
echo "   kubectl get certificate"
echo ""
echo "3. Test HTTPS access:"
echo "   curl -I https://$DOMAIN_NAME"
echo ""
echo "4. Get Redirect URI for admin:"
echo "   https://$DOMAIN_NAME/auth/callback"

