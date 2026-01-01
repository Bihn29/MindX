import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { authService } from '../services/authService'
import './AuthCallback.css'

function AuthCallback() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const [status, setStatus] = useState<'processing' | 'success' | 'error'>('processing')
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const processCallback = async () => {
      const code = searchParams.get('code')
      const state = searchParams.get('state')
      const errorParam = searchParams.get('error')
      const errorDescription = searchParams.get('error_description')

      console.log('🔄 Processing OAuth callback...')
      console.log('📍 Current URL:', window.location.href)
      console.log('📋 Params:', { code: code ? '✓' : '✗', state: state ? '✓' : '✗', error: errorParam })

      // Check for error from authorization server
      if (errorParam) {
        setStatus('error')
        const fullError = errorDescription 
          ? `${errorParam}: ${errorDescription}` 
          : errorParam
        setError(`Authorization error: ${fullError}`)
        console.error('❌ OAuth error from IdP:', { errorParam, errorDescription })
        return
      }

      // Check for required parameters
      if (!code || !state) {
        setStatus('error')
        setError('Missing authorization code or state')
        console.error('❌ Missing required OAuth parameters')
        return
      }

      try {
        // Exchange code for tokens
        console.log('🔄 Exchanging code for tokens...')
        await authService.handleCallback(code, state)
        console.log('✅ Token exchange successful')
        setStatus('success')
        
        // Redirect to home after short delay
        setTimeout(() => {
          navigate('/')
        }, 2000)
      } catch (err) {
        setStatus('error')
        const errorMessage = err instanceof Error ? err.message : 'Authentication failed'
        setError(errorMessage)
        console.error('❌ Callback processing error:', err)
      }
    }

    processCallback()
  }, [searchParams, navigate])

  return (
    <div className="callback-container">
      <div className="callback-card">
        {status === 'processing' && (
          <>
            <div className="spinner"></div>
            <h2>Đang xử lý đăng nhập...</h2>
            <p>Vui lòng đợi trong giây lát</p>
          </>
        )}

        {status === 'success' && (
          <>
            <div className="success-icon">✓</div>
            <h2>Đăng nhập thành công!</h2>
            <p>Đang chuyển hướng...</p>
          </>
        )}

        {status === 'error' && (
          <>
            <div className="error-icon">✗</div>
            <h2>Đăng nhập thất bại</h2>
            <p className="error-message">{error}</p>
            <button 
              className="retry-button"
              onClick={() => navigate('/')}
            >
              Quay lại trang chủ
            </button>
          </>
        )}
      </div>
    </div>
  )
}

export default AuthCallback

