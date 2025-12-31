#!/bin/bash

# Script to build Docker images for backend and frontend
# Usage: ./scripts/docker-build.sh [tag]

set -e

TAG=${1:-"latest"}

echo "🔨 Building Docker images with tag: $TAG"
echo ""

# Build backend
echo "📦 Building backend image..."
cd backend
docker build -t week1-backend:$TAG .
cd ..

# Build frontend
echo "📦 Building frontend image..."
cd frontend
docker build -t week1-frontend:$TAG .
cd ..

echo ""
echo "✅ Build complete!"
echo ""
echo "📋 Images created:"
echo "   - week1-backend:$TAG"
echo "   - week1-frontend:$TAG"
echo ""
echo "🚀 To run with Docker Compose:"
echo "   docker-compose up -d"

