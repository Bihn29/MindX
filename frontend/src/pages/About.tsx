import { useEffect, useState } from 'react'
import { authService, UserInfo } from '../services/authService'
import './About.css'

function About() {
  const [userInfo, setUserInfo] = useState<UserInfo | null>(null)

  useEffect(() => {
    const fetchUserInfo = async () => {
      const user = await authService.getUserInfo()
      setUserInfo(user)
    }
    fetchUserInfo()
  }, [])

  return (
    <div className="about">
      <h1>About</h1>
      <div className="about-content">
        {userInfo && (
          <section className="user-section">
            <h2>Welcome, {userInfo.name || 'User'}!</h2>
            {userInfo.picture && (
              <img 
                src={userInfo.picture} 
                alt="User avatar" 
                style={{ 
                  width: '80px', 
                  height: '80px', 
                  borderRadius: '50%',
                  marginBottom: '1rem'
                }}
              />
            )}
            <p>Email: {userInfo.email}</p>
            <p>User ID: {userInfo.sub}</p>
          </section>
        )}

        <section>
          <h2>Week 1 Full-Stack Application</h2>
          <p>
            This is a full-stack application built for Week 1 of the MindX Engineer Onboarding program.
          </p>
        </section>

        <section>
          <h2>Technology Stack</h2>
          <div className="tech-stack">
            <div className="tech-item">
              <h3>Frontend</h3>
              <ul>
                <li>React 18</li>
                <li>TypeScript</li>
                <li>Vite</li>
                <li>React Router</li>
              </ul>
            </div>
            <div className="tech-item">
              <h3>Backend</h3>
              <ul>
                <li>Node.js</li>
                <li>TypeScript</li>
                <li>Express</li>
              </ul>
            </div>
            <div className="tech-item">
              <h3>Infrastructure</h3>
              <ul>
                <li>Azure Kubernetes Service (AKS)</li>
                <li>Azure Container Registry (ACR)</li>
                <li>Docker</li>
                <li>Kubernetes</li>
              </ul>
            </div>
          </div>
        </section>

        <section>
          <h2>Features</h2>
          <ul className="features-list">
            <li>✅ Containerized API and Frontend</li>
            <li>✅ Deployed to Azure Cloud</li>
            <li>✅ Kubernetes orchestration</li>
            <li>✅ Ingress-based routing</li>
            <li>✅ Authentication (OpenID)</li>
            <li>🔄 HTTPS/SSL - In Progress</li>
          </ul>
        </section>
      </div>
    </div>
  )
}

export default About

