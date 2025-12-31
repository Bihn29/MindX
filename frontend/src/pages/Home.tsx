import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'
import { authService, UserInfo } from '../services/authService'
import { logRedirectUriInfo } from '../utils/getRedirectUri'
import './Home.css'

function Home() {
  const navigate = useNavigate()
  const [apiAvailable, setApiAvailable] = useState<boolean>(false)
  const [environment, setEnvironment] = useState<string>('development')
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false)
  const [userInfo, setUserInfo] = useState<UserInfo | null>(null)
  const [loading, setLoading] = useState<boolean>(true)

  const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api'

  useEffect(() => {
    const initialize = async () => {
      // Log redirect URI info for admin registration
      const env = import.meta.env.MODE || 'development'
      logRedirectUriInfo()

      // Check API status
      try {
        const healthResponse = await axios.get(`${API_BASE_URL}/health`)
        setApiAvailable(true)
        setEnvironment(healthResponse.data?.environment || env)
      } catch (err) {
        setApiAvailable(false)
        setEnvironment(env)
        console.error('API Error:', err)
      }

      // Check authentication status
      const authenticated = authService.isAuthenticated()
      setIsAuthenticated(authenticated)

      if (authenticated) {
        // Get user info
        const user = await authService.getUserInfo()
        setUserInfo(user)
      }

      setLoading(false)
    }

    initialize()
  }, [API_BASE_URL])

  const handleLogin = async () => {
    try {
      await authService.initiateLogin()
    } catch (error) {
      console.error('Login error:', error)
      alert('Đã xảy ra lỗi khi đăng nhập. Vui lòng thử lại.')
    }
  }

  const handleLogout = () => {
    authService.logout()
    setIsAuthenticated(false)
    setUserInfo(null)
  }

  return (
    <div className="home-container">
      <div className="login-card">
        {/* Header Section with Blue Gradient */}
        <div className="card-header">
          <h1 className="portal-title">MindX Portal</h1>
          <p className="portal-subtitle">Azure Cloud Deployment • Week 1</p>
        </div>

        {/* Body Section */}
        <div className="card-body">
          {loading ? (
            <div className="loading-state">
              <div className="spinner-small"></div>
              <p>Đang kiểm tra...</p>
            </div>
          ) : isAuthenticated && userInfo ? (
            <div className="authenticated-state">
              <h2 className="login-title">Chào mừng!</h2>
              <div className="user-info">
                {userInfo.picture && (
                  <img 
                    src={userInfo.picture} 
                    alt="Avatar" 
                    className="user-avatar"
                  />
                )}
                <p className="user-name">{userInfo.name || userInfo.email || 'User'}</p>
                {userInfo.email && (
                  <p className="user-email">{userInfo.email}</p>
                )}
              </div>
              <button 
                className="logout-button"
                onClick={handleLogout}
              >
                Đăng xuất
              </button>
              <button 
                className="about-button"
                onClick={() => navigate('/about')}
                style={{ marginTop: '10px' }}
              >
                📚 Xem thông tin dự án
              </button>
            </div>
          ) : (
            <>
              <h2 className="login-title">Đăng nhập hệ thống</h2>
              <p className="login-instruction">
                Sử dụng tài khoản MindX ID của bạn
              </p>
              <p className="redirect-notice">
                Bạn sẽ được chuyển đến{' '}
                <a 
                  href="https://id-dev.mindx.edu.vn" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="mindx-link"
                >
                  id-dev.mindx.edu.vn
                </a>{' '}
                để đăng nhập
              </p>
              
              <button 
                className="login-button"
                onClick={handleLogin}
              >
                <span className="info-icon">ℹ</span>
                Login with MindX OpenID
              </button>

              <p className="auth-source">
                Authentication powered by{' '}
                <a 
                  href="https://id-dev.mindx.edu.vn" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="auth-link"
                >
                  id-dev.mindx.edu.vn
                </a>
              </p>
            </>
          )}
        </div>
      </div>

      {/* Status Information at Bottom */}
      <div className="status-info">
        <p className="status-line">
          MindX Engineer Onboarding • Lab Week 1
        </p>
        <p className="status-line">
          API Status:{' '}
          <span className={`api-status ${apiAvailable ? 'available' : 'unavailable'}`}>
            {apiAvailable ? '✓' : '✗'} API {apiAvailable ? 'Available' : 'Unavailable'}
          </span>
        </p>
        <p className="status-line">
          Environment: <span className="environment">{environment}</span>
        </p>
      </div>
    </div>
  )
}

export default Home
