import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'
import { AuthProvider, useAuth } from './context/AuthContext'
import AppLayout from './components/layout/AppLayout'
import LandingPage from './pages/LandingPage'
import LoginPage from './pages/auth/LoginPage'
import RegisterPage from './pages/auth/RegisterPage'
import PendingApprovalPage from './pages/PendingApprovalPage'
import DashboardPage from './pages/dashboard/DashboardPage'
import ProfilePage from './pages/profile/ProfilePage'
import SetupProfilePage from './pages/profile/SetupProfilePage'
import LivePage from './pages/live/LivePage'
import BroadcastPage from './pages/live/BroadcastPage'
import WalletPage from './pages/wallet/WalletPage'
import WithdrawalPage from './pages/wallet/WithdrawalPage'
import ChatPage from './pages/chat/ChatPage'
import CommunityPage from './pages/community/CommunityPage'
import AboutPage from './pages/AboutPage'
import ContactPage from './pages/ContactPage'

function ProtectedRoute({ children }) {
  const { user, astrologer, loading } = useAuth()
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="w-10 h-10 border-2 border-orange border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }
  if (!user) return <Navigate to="/login" replace />
  if (astrologer && astrologer.status !== 'approved') return <Navigate to="/pending" replace />
  return children
}

function PublicRoute({ children }) {
  const { user, loading } = useAuth()
  if (loading) return null
  return user ? <Navigate to="/dashboard" replace /> : children
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<LandingPage />} />
      <Route path="/about" element={<AboutPage />} />
      <Route path="/contact" element={<ContactPage />} />

      <Route path="/login" element={<PublicRoute><LoginPage /></PublicRoute>} />
      <Route path="/register" element={<PublicRoute><RegisterPage /></PublicRoute>} />
      <Route path="/pending" element={<PendingApprovalPage />} />

      <Route path="/live/broadcast/:id" element={<ProtectedRoute><BroadcastPage /></ProtectedRoute>} />

      <Route element={<ProtectedRoute><AppLayout /></ProtectedRoute>}>
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/profile" element={<ProfilePage />} />
        <Route path="/setup-profile" element={<SetupProfilePage />} />
        <Route path="/live" element={<LivePage />} />
        <Route path="/wallet" element={<WalletPage />} />
        <Route path="/withdrawal" element={<WithdrawalPage />} />
        <Route path="/chat" element={<ChatPage />} />
        <Route path="/community" element={<CommunityPage />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <AppRoutes />
        <Toaster
          position="top-right"
          toastOptions={{
            style: {
              background: '#1E1E1E',
              color: '#FFFFFF',
              border: '1px solid #2A2A2A',
              borderRadius: '12px',
            },
            success: { iconTheme: { primary: '#43A047', secondary: '#fff' } },
            error: { iconTheme: { primary: '#E53935', secondary: '#fff' } },
          }}
        />
      </AuthProvider>
    </BrowserRouter>
  )
}
