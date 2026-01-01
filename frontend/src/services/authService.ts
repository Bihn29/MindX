// OpenID Connect Configuration
const OPENID_CONFIG = {
  issuer: 'https://id-dev.mindx.edu.vn',
  authorizationEndpoint: 'https://id-dev.mindx.edu.vn/auth',
  tokenEndpoint: 'https://id-dev.mindx.edu.vn/token',
  userInfoEndpoint: 'https://id-dev.mindx.edu.vn/me',
  clientId: import.meta.env.VITE_OPENID_CLIENT_ID || 'mindx-onboarding',
  redirectUri: `${window.location.origin}/auth/callback`,
  responseType: 'code',
  scope: 'openid profile email',
  codeChallengeMethod: 'S256',
}

// Generate code verifier and challenge for PKCE
function generateCodeVerifier(): string {
  const array = new Uint8Array(32)
  crypto.getRandomValues(array)
  return btoa(String.fromCharCode(...array))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

async function generateCodeChallenge(verifier: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(verifier)
  const digest = await crypto.subtle.digest('SHA-256', data)
  return btoa(String.fromCharCode(...new Uint8Array(digest)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

// Generate state for CSRF protection
function generateState(): string {
  const array = new Uint8Array(16)
  crypto.getRandomValues(array)
  return btoa(String.fromCharCode(...array))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

export interface AuthTokens {
  access_token: string
  id_token: string
  refresh_token?: string
  expires_in: number
}

export interface UserInfo {
  sub: string
  email?: string
  name?: string
  picture?: string
}

class AuthService {
  private storageKey = 'mindx_auth'

  // Initiate login flow
  async initiateLogin(): Promise<void> {
    try {
      const codeVerifier = generateCodeVerifier()
      const codeChallenge = await generateCodeChallenge(codeVerifier)
      const state = generateState()

      // Store code verifier and state in session storage
      sessionStorage.setItem('code_verifier', codeVerifier)
      sessionStorage.setItem('oauth_state', state)

      // Generate nonce for additional security
      const nonce = generateState()
      sessionStorage.setItem('oauth_nonce', nonce)

      console.log('🔐 OAuth Login Flow')
      console.log('📍 Redirect URI:', OPENID_CONFIG.redirectUri)
      console.log('📋 Client ID:', OPENID_CONFIG.clientId)
      console.log('⚠️  Make sure this Redirect URI is whitelisted on IdP!')

      // Build authorization URL with additional parameters
      const params = new URLSearchParams({
        client_id: OPENID_CONFIG.clientId,
        redirect_uri: OPENID_CONFIG.redirectUri,
        response_type: OPENID_CONFIG.responseType,
        scope: OPENID_CONFIG.scope,
        state: state,
        nonce: nonce,
        code_challenge: codeChallenge,
        code_challenge_method: OPENID_CONFIG.codeChallengeMethod,
        prompt: 'login',
        response_mode: 'query',
      })

      const authUrl = `${OPENID_CONFIG.authorizationEndpoint}?${params.toString()}`
      
      // Redirect to authorization server
      window.location.href = authUrl
    } catch (error) {
      console.error('❌ Login initiation failed:', error)
      throw error
    }
  }

  // Handle callback from authorization server
  async handleCallback(code: string, state: string): Promise<AuthTokens> {
    // Verify state
    const storedState = sessionStorage.getItem('oauth_state')
    if (!storedState || storedState !== state) {
      console.error('❌ State mismatch - possible CSRF attack')
      throw new Error('Invalid state parameter')
    }

    const codeVerifier = sessionStorage.getItem('code_verifier')
    if (!codeVerifier) {
      console.error('❌ Code verifier not found in session storage')
      throw new Error('Code verifier not found')
    }

    // Exchange authorization code for tokens
    const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'
    
    try {
      const response = await fetch(`${API_BASE_URL}/auth/token`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          code,
          code_verifier: codeVerifier,
          redirect_uri: OPENID_CONFIG.redirectUri,
        }),
      })

      if (!response.ok) {
        const contentType = response.headers.get('content-type') || ''
        let errorPayload: any = null

        try {
          if (contentType.includes('application/json')) {
            errorPayload = await response.json()
          } else {
            errorPayload = await response.text()
          }
        } catch {
          // ignore parse errors
        }

        console.error('❌ Token exchange failed:', errorPayload)

        const message =
          (errorPayload && typeof errorPayload === 'object' && (errorPayload.idp_error_description || errorPayload.error))
            ? (errorPayload.idp_error_description || errorPayload.error)
            : (typeof errorPayload === 'string' && errorPayload.trim() ? errorPayload : 'Failed to exchange code for tokens')

        throw new Error(message)
      }

      const tokens: AuthTokens = await response.json()
      
      // Store tokens
      this.setTokens(tokens)
      
      // Clean up session storage
      sessionStorage.removeItem('code_verifier')
      sessionStorage.removeItem('oauth_state')
      
      return tokens
    } catch (error) {
      console.error('❌ Token exchange error:', error)
      throw error
    }
  }

  // Get user info
  async getUserInfo(): Promise<UserInfo | null> {
    const tokens = this.getTokens()
    if (!tokens) {
      return null
    }

    const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'
    
    try {
      const response = await fetch(`${API_BASE_URL}/auth/userinfo`, {
        headers: {
          'Authorization': `Bearer ${tokens.access_token}`,
        },
      })

      if (!response.ok) {
        throw new Error('Failed to get user info')
      }

      return await response.json()
    } catch (error) {
      console.error('Get user info error:', error)
      return null
    }
  }

  // Check if user is authenticated
  isAuthenticated(): boolean {
    const tokens = this.getTokens()
    if (!tokens) {
      return false
    }

    // Check if token is expired
    const expiresAt = localStorage.getItem('token_expires_at')
    if (expiresAt && Date.now() > parseInt(expiresAt)) {
      this.logout()
      return false
    }

    return true
  }

  // Get stored tokens
  getTokens(): AuthTokens | null {
    const stored = localStorage.getItem(this.storageKey)
    if (!stored) {
      return null
    }
    return JSON.parse(stored)
  }

  // Store tokens
  private setTokens(tokens: AuthTokens): void {
    localStorage.setItem(this.storageKey, JSON.stringify(tokens))
    const expiresAt = Date.now() + (tokens.expires_in * 1000)
    localStorage.setItem('token_expires_at', expiresAt.toString())
  }

  // Logout
  logout(): void {
    localStorage.removeItem(this.storageKey)
    localStorage.removeItem('token_expires_at')
    sessionStorage.removeItem('code_verifier')
    sessionStorage.removeItem('oauth_state')
  }
}

export const authService = new AuthService()

