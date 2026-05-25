import { createContext, useContext, useState, useEffect } from 'react'
import { authAPI, astrologerAPI } from '../services/api'
import { connectSocket, disconnectSocket } from '../services/socket'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('user')
    return saved ? JSON.parse(saved) : null
  })
  const [astrologer, setAstrologer] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const token = localStorage.getItem('token')
    if (token) {
      connectSocket(token)
      fetchProfile()
    } else {
      setLoading(false)
    }
  }, [])

  async function fetchProfile() {
    try {
      const res = await authAPI.getProfile()
      const userData = res.data.data
      setUser(userData)
      localStorage.setItem('user', JSON.stringify(userData))

      // Try to fetch astrologer profile
      try {
        const dash = await astrologerAPI.getDashboard()
        setAstrologer(dash.data.data.astrologer)
      } catch {
        // Not an astrologer yet
      }
    } catch {
      logout()
    } finally {
      setLoading(false)
    }
  }

  async function login(email, password) {
    const res = await authAPI.login({ email, password, login_as: 'astrologer' })
    const { user: userData, token } = res.data.data
    localStorage.setItem('token', token)
    localStorage.setItem('user', JSON.stringify(userData))
    setUser(userData)
    connectSocket(token)

    try {
      const dash = await astrologerAPI.getDashboard()
      setAstrologer(dash.data.data.astrologer)
    } catch {
      // Not yet registered as astrologer
    }

    return userData
  }

  async function register(data) {
    const res = await authAPI.register(data)
    const { user: userData, token } = res.data.data
    localStorage.setItem('token', token)
    localStorage.setItem('user', JSON.stringify(userData))
    setUser(userData)
    connectSocket(token)
    return userData
  }

  function logout() {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    setUser(null)
    setAstrologer(null)
    disconnectSocket()
  }

  return (
    <AuthContext.Provider value={{ user, astrologer, setAstrologer, loading, login, register, logout, fetchProfile }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
