# Week 1 Backend

Node.js/TypeScript Express Backend API for Week 1 full-stack application.

## Features

- Health check endpoint (`/health`)
- Hello World endpoint (`/`)
- API info endpoint (`/api/info`)
- TypeScript for type safety
- Docker containerization support
- Production-ready configuration

## Local Development

### Prerequisites

- Node.js 20+ 
- npm or yarn

### Installation

```bash
npm install
```

### Development

```bash
npm run dev
```

Server will start on `http://localhost:3000`

### Build

```bash
npm run build
npm start
```

## Docker

### Build Image

```bash
docker build -t week1-backend:latest .
```

### Run Container

```bash
docker run -p 3000:3000 week1-backend:latest
```

## Endpoints

- `GET /` - Hello World message
- `GET /health` - Health check endpoint
- `GET /api/info` - API information
- `POST /api/auth/token` - Exchange authorization code for tokens (OpenID Connect)
- `GET /api/auth/userinfo` - Get user information (requires Bearer token)

## Environment Variables

Create a `.env` file in the backend directory:

```env
PORT=3000
NODE_ENV=development

# OpenID Connect Configuration
OPENID_CLIENT_ID=mindx-onboarding
OPENID_CLIENT_SECRET=cHJldmVudGJvdW5kYmF0dHJlZWV4cGxvcmVjZWxsbmVydm91c3ZhcG9ydGhhbnN0ZWU=
```

- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production)
- `OPENID_CLIENT_ID` - OpenID Connect Client ID from MindX Identity Provider
- `OPENID_CLIENT_SECRET` - OpenID Connect Client Secret from MindX Identity Provider

## Authentication

The backend supports OpenID Connect authentication with MindX Identity Provider (`https://id-dev.mindx.edu.vn`).

### Test Account
- Email: `intern@mindx.com.vn`
- Password: `mindx1234`

