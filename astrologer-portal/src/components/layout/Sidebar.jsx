import { NavLink, useNavigate } from 'react-router-dom'
import { LayoutDashboard, User, Radio, Wallet, MessageSquare, Star, LogOut, ChevronRight, Users, ArrowUpFromLine } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import toast from 'react-hot-toast'

const NAV = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/profile', icon: User, label: 'My Profile' },
  { to: '/live', icon: Radio, label: 'Go Live' },
  { to: '/chat', icon: MessageSquare, label: 'Consultations' },
  { to: '/community', icon: Users, label: 'Community' },
  { to: '/wallet', icon: Wallet, label: 'Wallet' },
  { to: '/withdrawal', icon: ArrowUpFromLine, label: 'Withdraw' },
]

export default function Sidebar() {
  const { user, astrologer, logout } = useAuth()
  const navigate = useNavigate()

  function handleLogout() {
    logout()
    toast.success('Signed out')
    navigate('/login')
  }

  return (
    <aside className="hidden lg:flex flex-col w-64 min-h-screen bg-surface border-r border-border px-4 py-6 fixed left-0 top-0 bottom-0">
      {/* Logo */}
      <div className="flex items-center gap-3 px-2 mb-8">
        <div className="w-9 h-9 rounded-xl bg-orange/20 flex items-center justify-center">
          <Star className="w-5 h-5 text-orange fill-orange" />
        </div>
        <div>
          <p className="font-bold text-text-primary leading-none">AstroVaak</p>
          <p className="text-text-muted text-xs mt-0.5">Astrologer Portal</p>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex flex-col gap-1 flex-1">
        {NAV.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-orange/15 text-orange'
                  : 'text-text-secondary hover:text-text-primary hover:bg-surface-light'
              }`
            }
          >
            <Icon size={18} />
            {label}
          </NavLink>
        ))}
      </nav>

      {/* User card */}
      <div className="mt-4 pt-4 border-t border-border">
        <div className="flex items-center gap-3 px-2 mb-3">
          <div className="w-9 h-9 rounded-full bg-orange/20 flex items-center justify-center text-orange font-semibold text-sm shrink-0">
            {user?.name?.[0]?.toUpperCase()}
          </div>
          <div className="min-w-0">
            <p className="text-sm font-medium text-text-primary truncate">{user?.name}</p>
            <p className="text-xs text-text-muted truncate">{astrologer ? 'Astrologer' : 'Not registered'}</p>
          </div>
        </div>
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm text-text-secondary hover:text-error hover:bg-error/10 transition-colors w-full"
        >
          <LogOut size={18} />
          Sign Out
        </button>
      </div>
    </aside>
  )
}
