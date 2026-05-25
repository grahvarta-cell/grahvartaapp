import { NavLink } from 'react-router-dom'
import { LayoutDashboard, User, Radio, Wallet, MessageSquare, Users } from 'lucide-react'

const NAV = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Home' },
  { to: '/live', icon: Radio, label: 'Live' },
  { to: '/community', icon: Users, label: 'Community' },
  { to: '/chat', icon: MessageSquare, label: 'Chats' },
  { to: '/wallet', icon: Wallet, label: 'Wallet' },
]

export default function MobileNav() {
  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 bg-surface border-t border-border px-2 py-2 z-50">
      <div className="flex items-center justify-around">
        {NAV.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) =>
              `flex flex-col items-center gap-1 px-3 py-1.5 rounded-xl transition-colors ${
                isActive ? 'text-orange' : 'text-text-muted'
              }`
            }
          >
            <Icon size={20} />
            <span className="text-xs font-medium">{label}</span>
          </NavLink>
        ))}
      </div>
    </nav>
  )
}
