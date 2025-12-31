#!/bin/bash

# Script to build and push Docker image to Azure Container Registry
# Usage: ./scripts/build-and-push.sh <acr-name> <image-name> <tag>

set -e

ACR_NAME=${1:-"myregistry"}
IMAGE_NAME=${2:-"week1-backend"}
TAG=${3:-"latest"}

if [ -z "$ACR_NAME" ]; then
    echo "Error: ACR name is required"
    echo "Usage: ./scripts/build-and-push.sh <acr-name> <image-name> <tag>"
    exit 1
fi

ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"
FULL_IMAGE_NAME="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${TAG}"

echo "🔨 Building Docker image..."
cd backend
docker build -t ${IMAGE_NAME}:${TAG} .

echo "🏷️  Tagging image for ACR..."
docker tag ${IMAGE_NAME}:${TAG} ${FULL_IMAGE_NAME}

echo "🔐 Logging in to Azure Container Registry..."
az acr login --name ${ACR_NAME}

echo "📤 Pushing image to ACR..."
docker push ${FULL_IMAGE_NAME}

echo "✅ Successfully pushed ${FULL_IMAGE_NAME}"
echo "📋 Image details:"
az acr repository show-tags --name ${ACR_NAME} --repository ${IMAGE_NAME} --output table

