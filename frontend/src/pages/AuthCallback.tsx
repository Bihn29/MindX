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

      // Check for error from authorization server
      if (errorParam) {
        setStatus('error')
        setError(`Authorization error: ${errorParam}`)
        return
      }

      // Check for required parameters
      if (!code || !state) {
        setStatus('error')
        setError('Missing authorization code or state')
        return
      }

      try {
        // Exchange code for tokens
        await authService.handleCallback(code, state)
        setStatus('success')
        
        // Redirect to home after short delay
        setTimeout(() => {
          navigate('/')
        }, 2000)
      } catch (err) {
        setStatus('error')
        setError(err instanceof Error ? err.message : 'Authentication failed')
        console.error('Callback processing error:', err)
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

