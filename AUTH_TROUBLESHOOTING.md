# Authentication Troubleshooting Guide

## Common Issue: "CONSENT_ERROR" or "Invalid Redirect URI"

### Problem
You see an error like:
- "CONSENT_ERROR - getInteraction requires request/response context"
- "invalid_client" or "client authentication failed"
- Login button redirects but immediately shows error page

### Root Cause
The **Redirect URI** you're using is not whitelisted on the MindX Identity Provider (`id-dev.mindx.edu.vn`).

### How to Fix

#### Step 1: Identify Your Redirect URI

Your redirect URI depends on where you're running the app:

| Environment | Redirect URI |
|------------|--------------|
| Local Vite Dev Server | `http://localhost:5173/auth/callback` |
| Local Docker Compose | `http://localhost:8080/auth/callback` |
| Azure Web App | `https://YOUR-APP-NAME.azurewebsites.net/auth/callback` |
| Custom Domain | `https://your-domain.com/auth/callback` |

To see your current redirect URI:
1. Open the app in browser
2. Open Browser Console (F12)
3. Click the "Login with MindX OpenID" button
4. Look for the log: `📍 Redirect URI: ...`

#### Step 2: Request Whitelist from Admin

Contact your MindX admin/instructor and provide:

```
Client ID: mindx-onboarding
Redirect URI: [your-redirect-uri-from-step-1]
Environment: Development/Production
```

Example email:
```
Hi Admin,

Please whitelist the following redirect URI for OpenID authentication:
- Client ID: mindx-onboarding
- Redirect URI: http://localhost:8080/auth/callback
- Purpose: Week 1 development testing

Thank you!
```

#### Step 3: Verify Configuration

After admin whitelists your URI:
1. Clear browser cache and cookies for `id-dev.mindx.edu.vn`
2. Try login again
3. Check browser console for detailed logs

## Development Setup

### For Local Testing with Docker

1. Request admin to whitelist: `http://localhost:8080/auth/callback`
2. Run: `docker compose up -d`
3. Open: `http://localhost:8080`
4. Try login

### For Local Testing with Vite Dev Server

1. Request admin to whitelist: `http://localhost:5173/auth/callback`
2. Run: `npm run dev` in `frontend/` directory
3. Open: `http://localhost:5173`
4. Try login

### For Azure Production

1. Deploy app to Azure Web App
2. Note your app URL: `https://YOUR-APP.azurewebsites.net`
3. Request admin to whitelist: `https://YOUR-APP.azurewebsites.net/auth/callback`
4. Try login on production URL

## Client Authentication

### Public Client (PKCE) - Default

For single-page applications (SPAs), **do NOT set** `OPENID_CLIENT_SECRET`:

```bash
# backend/.env
OPENID_CLIENT_ID=mindx-onboarding
# OPENID_CLIENT_SECRET=    ← leave empty or don't set
```

The app uses PKCE (Proof Key for Code Exchange) which is secure without client secret.

### Confidential Client

If admin specifically provides a client secret, set it:

```bash
# backend/.env
OPENID_CLIENT_ID=mindx-onboarding
OPENID_CLIENT_SECRET=your_actual_secret_here
```

## Debug Checklist

- [ ] Redirect URI is whitelisted on IdP
- [ ] Client ID matches: `mindx-onboarding`
- [ ] Backend does NOT send client_secret (for PKCE public client)
- [ ] Browser can access `id-dev.mindx.edu.vn` (no firewall blocks)
- [ ] No browser extensions blocking OAuth flow
- [ ] Check browser console for detailed error logs

## Test Credentials

According to backend README:
- Email: `intern@mindx.com.vn`
- Password: `mindx1234`

## Still Having Issues?

1. Check browser console for detailed logs
2. Check backend logs: `docker compose logs backend`
3. Verify network tab in browser DevTools during login
4. Share the exact error message and redirect URI with instructor
