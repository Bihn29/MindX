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

async function validateAccessToken(accessToken: string): Promise<any> {
  const userInfoEndpoint = 'https://id-dev.mindx.edu.vn/me';

  const userInfoResponse = await fetch(userInfoEndpoint, {
    headers: {
      'Authorization': `Bearer ${accessToken}`,
    },
  });

  if (!userInfoResponse.ok) {
    const rawBody = await userInfoResponse.text();
    return {
      ok: false,
      status: userInfoResponse.status,
      body: rawBody.slice(0, 500),
    };
  }

  const userInfo = await userInfoResponse.json();
  return { ok: true, userInfo };
}

function requireBearerToken(req: Request, res: Response): string | null {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid authorization header' });
    return null;
  }
  return authHeader.substring(7);
}

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Health check alias under /api for reverse-proxy setups
app.get('/api/health', (req: Request, res: Response) => {
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

// Protected endpoint to demonstrate token validation/authorization
app.get('/api/protected', async (req: Request, res: Response) => {
  try {
    const accessToken = requireBearerToken(req, res);
    if (!accessToken) return;

    const validation = await validateAccessToken(accessToken);
    if (!validation.ok) {
      return res.status(401).json({
        error: 'Invalid access token',
        idp_status: validation.status,
        idp_body: validation.body,
      });
    }

    return res.json({
      message: '✅ Access granted',
      user: validation.userInfo,
    });
  } catch (error) {
    console.error('Protected endpoint error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
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
    const clientId = process.env.OPENID_CLIENT_ID || 'mindx-onboarding';
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
      const rawBody = await tokenResponse.text();
      let parsedBody: unknown = rawBody;
      try {
        parsedBody = JSON.parse(rawBody);
      } catch {
        // keep rawBody as-is
      }

      console.error('Token exchange error', {
        status: tokenResponse.status,
        clientId,
        redirectUri: redirect_uri,
        body: typeof parsedBody === 'string' ? parsedBody.slice(0, 2000) : parsedBody,
      });

      // Return a useful (but bounded) error to the frontend for debugging.
      return res.status(tokenResponse.status).json({
        error: 'Token exchange failed',
        idp_status: tokenResponse.status,
        idp_error: (typeof parsedBody === 'object' && parsedBody && 'error' in (parsedBody as any)) ? (parsedBody as any).error : undefined,
        idp_error_description: (typeof parsedBody === 'object' && parsedBody && 'error_description' in (parsedBody as any)) ? (parsedBody as any).error_description : undefined,
        idp_body: typeof parsedBody === 'string' ? parsedBody.slice(0, 500) : parsedBody,
      });
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
    const accessToken = requireBearerToken(req, res);
    if (!accessToken) return;

    const validation = await validateAccessToken(accessToken);
    if (!validation.ok) {
      return res.status(401).json({
        error: 'Invalid access token',
        idp_status: validation.status,
        idp_body: validation.body,
      });
    }

    res.json(validation.userInfo);
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

