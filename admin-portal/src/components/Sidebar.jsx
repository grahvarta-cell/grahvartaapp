import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Users, Star, FileText, Wallet, Bell, LogOut, ArrowDownCircle, MessageSquare, UserCheck, Gift, ShieldCheck } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import toast from 'react-hot-toast';

const navItems = [
  { to: '/',              icon: LayoutDashboard,  label: 'Dashboard',           permission: 'dashboard' },
  { to: '/users',         icon: Users,            label: 'Users',               permission: 'users' },
  { to: '/astrologers',   icon: Star,             label: 'Astrologers',         permission: 'astrologers' },
  { to: '/withdrawals',   icon: ArrowDownCircle,  label: 'Withdrawals',         permission: 'withdrawals' },
  { to: '/reports',       icon: FileText,         label: 'Reports',             permission: 'reports' },
  { to: '/transactions',  icon: Wallet,           label: 'Transactions',        permission: 'transactions' },
  { to: '/community',     icon: MessageSquare,    label: 'Community',           permission: 'community' },
  { to: '/notifications', icon: Bell,             label: 'Notifications',       permission: 'notifications' },
  { to: '/hirings',       icon: UserCheck,        label: 'Hirings',             permission: 'hirings' },
  { to: '/recharge-offers', icon: Gift,           label: 'Recharge Offers',    permission: 'recharge_offers' },
  { to: '/sub-admins',    icon: ShieldCheck,      label: 'Sub-admins',          permission: null }, // null = superadmin only
];

export default function Sidebar() {
  const { admin, logout, hasPermission } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    toast.success('Logged out');
    navigate('/login');
  };

  const visibleNavItems = navItems.filter(item => {
    if (item.permission === null) {
      return admin?.role === 'superadmin';
    }
    return hasPermission(item.permission);
  });

  return (
    <aside className="w-60 min-h-screen bg-surface border-r border-border flex flex-col shrink-0">
      <div className="px-6 py-5 border-b border-border">
        <span className="text-lg font-bold text-white">🔮 Grahvarta</span>
        <p className="text-xs text-text-muted mt-0.5">Admin Panel</p>
      </div>

      <nav className="flex-1 px-3 py-4 space-y-1">
        {visibleNavItems.map(({ to, icon: Icon, label, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-orange/15 text-orange'
                  : 'text-text-secondary hover:text-white hover:bg-surface-light'
              }`
            }
          >
            <Icon size={18} />
            {label}
          </NavLink>
        ))}
      </nav>

      <div className="px-3 py-4 border-t border-border">
        <div className="px-3 py-2 mb-2">
          <p className="text-sm font-medium text-white truncate">{admin?.name}</p>
          <p className="text-xs text-text-muted truncate">{admin?.email}</p>
        </div>
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-3 py-2.5 w-full rounded-xl text-sm font-medium text-text-secondary hover:text-error hover:bg-error/10 transition-colors"
        >
          <LogOut size={18} />
          Logout
        </button>
      </div>
    </aside>
  );
}
