# Week 1 Frontend

React/TypeScript frontend application for Week 1 full-stack application.

## Features

- React 18 with TypeScript
- Vite for fast development and building
- React Router for navigation
- API integration with backend
- Responsive design
- Docker containerization support

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

Application will start on `http://localhost:5173`

### Environment Variables

Create a `.env` file in the frontend directory:

```env
# API Base URL
# For production (using ingress routing):
VITE_API_BASE_URL=/api

# For local development with separate API:
# VITE_API_BASE_URL=http://localhost:3000/api

# OpenID Connect Configuration
VITE_OPENID_CLIENT_ID=mindx-onboarding
```

- `VITE_API_BASE_URL` - Backend API base URL
- `VITE_OPENID_CLIENT_ID` - OpenID Connect Client ID from MindX Identity Provider

### Test Account
- Email: `intern@mindx.com.vn`
- Password: `mindx1234`

### Build

```bash
npm run build
```

Build output will be in `dist/` directory.

### Preview Production Build

```bash
npm run preview
```

## Docker

### Build Image

```bash
docker build -t week1-frontend:latest .
```

### Run Container

```bash
docker run -p 8080:8080 week1-frontend:latest
```

Application will be available at `http://localhost:8080`

## Project Structure

```
frontend/
├── src/
│   ├── components/     # React components
│   ├── pages/          # Page components
│   ├── App.tsx         # Main app component
│   └── main.tsx        # Entry point
├── public/             # Static assets
├── dist/               # Build output
├── Dockerfile          # Docker configuration
└── vite.config.ts      # Vite configuration
```

## Pages

- `/` - Home page with API status and information
- `/about` - About page with project information

## API Integration

The frontend communicates with the backend API through the `/api` endpoint. The API base URL can be configured via environment variable `VITE_API_BASE_URL`.

## Deployment

See main [DEPLOYMENT.md](../DEPLOYMENT.md) for deployment instructions to AKS.

