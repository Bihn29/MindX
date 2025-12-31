import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Hello world endpoint
app.get('/', (req: Request, res: Response) => {
  res.json({
    message: 'Hello World from Week1 API!',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// API info endpoint
app.get('/api/info', (req: Request, res: Response) => {
  res.json({
    name: 'Week1 API',
    version: '1.0.0',
    description: 'Full-stack application API for Week1',
    endpoints: {
      health: '/health',
      hello: '/',
      info: '/api/info'
    }
  });
});

// Authentication endpoints
app.post('/api/auth/token', async (req: Request, res: Response) => {
  try {
    const { code, code_verifier, redirect_uri } = req.body;

    if (!code || !code_verifier || !redirect_uri) {
      return res.status(400).json({ error: 'Missing required parameters' });
    }

    // Exchange authorization code for tokens
    const tokenEndpoint = 'https://id-dev.mindx.edu.vn/token';
    const clientId = process.env.OPENID_CLIENT_ID || '';
    const clientSecret = process.env.OPENID_CLIENT_SECRET || '';

    const tokenResponse = await fetch(tokenEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: redirect_uri,
        client_id: clientId,
        code_verifier: code_verifier,
        ...(clientSecret && { client_secret: clientSecret }),
      }),
    });

    if (!tokenResponse.ok) {
      const error = await tokenResponse.text();
      console.error('Token exchange error:', error);
      return res.status(tokenResponse.status).json({ error: 'Token exchange failed' });
    }

    const tokens = await tokenResponse.json();
    res.json(tokens);
  } catch (error) {
    console.error('Token endpoint error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// User info endpoint
app.get('/api/auth/userinfo', async (req: Request, res: Response) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid authorization header' });
    }

    const accessToken = authHeader.substring(7);

    // Get user info from OpenID provider
    const userInfoEndpoint = 'https://id-dev.mindx.edu.vn/me';
    
    const userInfoResponse = await fetch(userInfoEndpoint, {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    if (!userInfoResponse.ok) {
      return res.status(userInfoResponse.status).json({ error: 'Failed to get user info' });
    }

    const userInfo = await userInfoResponse.json();
    res.json(userInfo);
  } catch (error) {
    console.error('User info endpoint error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/health`);
  console.log(`📍 Hello World: http://localhost:${PORT}/`);
});

