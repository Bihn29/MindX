# Hướng dẫn Deploy với Docker

Hướng dẫn deploy ứng dụng Week 1 Full-Stack sử dụng Docker và Docker Compose.

## Prerequisites

- Docker Desktop hoặc Docker Engine đã được cài đặt
- Docker Compose đã được cài đặt (thường đi kèm với Docker Desktop)

## Quick Start

### 1. Local Development với Docker Compose

```bash
# Clone repository (nếu chưa có)
# cd vào thư mục project

# Tạo file .env (optional, có thể dùng giá trị mặc định)
# Copy từ .env.example nếu có

# Build và chạy tất cả services
docker-compose up --build

# Hoặc chạy ở background
docker-compose up -d --build
```

**Services sẽ chạy tại:**
- Frontend: http://localhost:8080
- Backend: http://localhost:3000
- API Health: http://localhost:3000/health

### 2. Stop Services

```bash
# Stop services
docker-compose down

# Stop và xóa volumes
docker-compose down -v
```

## Build Images Riêng Lẻ

### Build Backend Image

```bash
cd backend
docker build -t week1-backend:latest .
docker run -p 3000:3000 \
  -e OPENID_CLIENT_ID=mindx-onboarding \
  -e OPENID_CLIENT_SECRET=cHJldmVudGJvdW5kYmF0dHJlZWV4cGxvcmVjZWxsbmVydm91c3ZhcG9ydGhhbnN0ZWU= \
  week1-backend:latest
```

### Build Frontend Image

```bash
cd frontend
docker build -t week1-frontend:latest .
docker run -p 8080:8080 \
  -e VITE_API_BASE_URL=http://localhost:3000/api \
  week1-frontend:latest
```

## Environment Variables

Tạo file `.env` trong thư mục root (optional):

```env
# Backend
OPENID_CLIENT_ID=mindx-onboarding
OPENID_CLIENT_SECRET=cHJldmVudGJvdW5kYmF0dHJlZWV4cGxvcmVjZWxsbmVydm91c3ZhcG9ydGhhbnN0ZWU=

# Frontend (cho production)
# VITE_API_BASE_URL=/api
```

## Docker Compose Commands

### Xem logs

```bash
# Tất cả services
docker-compose logs

# Chỉ backend
docker-compose logs backend

# Chỉ frontend
docker-compose logs frontend

# Follow logs
docker-compose logs -f
```

### Restart services

```bash
# Restart tất cả
docker-compose restart

# Restart một service
docker-compose restart backend
```

### Rebuild sau khi thay đổi code

```bash
# Rebuild và restart
docker-compose up --build -d

# Rebuild một service cụ thể
docker-compose build backend
docker-compose up -d backend
```

### Xem status

```bash
# List running containers
docker-compose ps

# Xem resource usage
docker stats
```

## Production Deployment

### Option 1: Docker Compose trên Server

1. **Copy files lên server:**
   ```bash
   scp -r . user@server:/path/to/app
   ```

2. **SSH vào server:**
   ```bash
   ssh user@server
   cd /path/to/app
   ```

3. **Tạo .env file với production values:**
   ```env
   OPENID_CLIENT_ID=mindx-onboarding
   OPENID_CLIENT_SECRET=your-secret
   ```

4. **Deploy:**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d --build
   ```

5. **Setup reverse proxy (nginx/traefik) với SSL**

### Option 2: Deploy lên Azure Container Instances (ACI)

```bash
# Login to Azure
az login

# Create resource group
az group create --name week1-rg --location eastus

# Create container registry (nếu chưa có)
az acr create --resource-group week1-rg --name <acr-name> --sku Basic

# Build and push images
docker build -t <acr-name>.azurecr.io/week1-backend:latest ./backend
docker build -t <acr-name>.azurecr.io/week1-frontend:latest ./frontend

az acr login --name <acr-name>
docker push <acr-name>.azurecr.io/week1-backend:latest
docker push <acr-name>.azurecr.io/week1-frontend:latest

# Deploy backend
az container create \
  --resource-group week1-rg \
  --name week1-backend \
  --image <acr-name>.azurecr.io/week1-backend:latest \
  --registry-login-server <acr-name>.azurecr.io \
  --ip-address Public \
  --ports 3000 \
  --environment-variables \
    OPENID_CLIENT_ID=mindx-onboarding \
    OPENID_CLIENT_SECRET=your-secret

# Deploy frontend
az container create \
  --resource-group week1-rg \
  --name week1-frontend \
  --image <acr-name>.azurecr.io/week1-frontend:latest \
  --registry-login-server <acr-name>.azurecr.io \
  --ip-address Public \
  --ports 8080 \
  --environment-variables \
    VITE_API_BASE_URL=/api
```

## Troubleshooting

### Container không start

```bash
# Xem logs
docker-compose logs <service-name>

# Kiểm tra container status
docker-compose ps

# Xem chi tiết container
docker inspect <container-name>
```

### Port đã được sử dụng

```bash
# Kiểm tra port đang được sử dụng
# Windows
netstat -ano | findstr :3000
netstat -ano | findstr :8080

# Linux/Mac
lsof -i :3000
lsof -i :8080

# Thay đổi port trong docker-compose.yml nếu cần
```

### Build fails

```bash
# Clean build (không dùng cache)
docker-compose build --no-cache

# Xóa images cũ
docker-compose down --rmi all
```

### Network issues giữa containers

```bash
# Kiểm tra network
docker network ls
docker network inspect week1-network

# Frontend có thể kết nối backend qua service name
# Ví dụ: http://backend:3000/api
```

## Health Checks

Cả hai services đều có health checks:

```bash
# Check backend health
curl http://localhost:3000/health

# Check frontend health
curl http://localhost:8080/health
```

## Cleanup

```bash
# Stop và xóa containers
docker-compose down

# Xóa containers, networks, và volumes
docker-compose down -v

# Xóa images
docker-compose down --rmi all

# Xóa tất cả (containers, images, volumes, networks)
docker system prune -a --volumes
```

## Next Steps

Sau khi deploy thành công với Docker:

1. **Setup Reverse Proxy** (nginx/traefik) với SSL
2. **Configure Domain** trỏ về server
3. **Setup SSL Certificate** (Let's Encrypt)
4. **Update Redirect URI** cho OpenID:
   ```
   https://your-domain.com/auth/callback
   ```

## Tips

- Sử dụng `.env` file để quản lý environment variables
- Sử dụng `docker-compose.override.yml` cho local development overrides
- Monitor logs thường xuyên: `docker-compose logs -f`
- Backup volumes nếu có persistent data
- Sử dụng Docker secrets cho sensitive data trong production

