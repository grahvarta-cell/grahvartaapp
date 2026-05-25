import { useEffect, useState } from 'react'
import { Wallet, TrendingUp, ArrowDownLeft, ArrowUpRight, Clock } from 'lucide-react'
import { walletAPI } from '../../services/api'
import { format } from 'date-fns'

export default function WalletPage() {
  const [wallet, setWallet] = useState(null)
  const [transactions, setTransactions] = useState([])
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      walletAPI.getWallet(),
      walletAPI.getTransactions(),
      walletAPI.getStats(),
    ]).then(([w, t, s]) => {
      setWallet(w.data.data?.wallet)
      setTransactions(t.data.data || [])
      setStats(s.data.data?.stats)
    }).catch(() => {}).finally(() => setLoading(false))
  }, [])

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-2 border-orange border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Wallet & Earnings</h1>

      {/* Balance Card */}
      <div className="rounded-2xl bg-gradient-to-br from-orange/30 via-orange/10 to-surface border border-orange/30 p-6">
        <p className="text-text-secondary text-sm mb-1">Available Balance</p>
        <p className="text-4xl font-bold text-text-primary">₹{Number(wallet?.balance || 0).toFixed(2)}</p>
        <p className="text-text-muted text-sm mt-2">Lifetime earnings: ₹{Number(wallet?.total_earned || 0).toFixed(2)}</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
        <div className="stat-card">
          <div className="w-9 h-9 rounded-xl bg-success/20 flex items-center justify-center">
            <TrendingUp size={18} className="text-success" />
          </div>
          <p className="text-xl font-bold">₹{Number(stats?.this_month || 0).toFixed(0)}</p>
          <p className="text-text-secondary text-sm">This Month</p>
        </div>
        <div className="stat-card">
          <div className="w-9 h-9 rounded-xl bg-orange/20 flex items-center justify-center">
            <Wallet size={18} className="text-orange" />
          </div>
          <p className="text-xl font-bold">₹{Number(stats?.this_week || 0).toFixed(0)}</p>
          <p className="text-text-secondary text-sm">This Week</p>
        </div>
        <div className="stat-card col-span-2 lg:col-span-1">
          <div className="w-9 h-9 rounded-xl bg-gold/20 flex items-center justify-center">
            <Clock size={18} className="text-gold" />
          </div>
          <p className="text-xl font-bold">₹{Number(stats?.today || 0).toFixed(0)}</p>
          <p className="text-text-secondary text-sm">Today</p>
        </div>
      </div>

      {/* Transactions */}
      <div className="card">
        <h3 className="font-semibold mb-4">Transaction History</h3>
        {transactions.length === 0 ? (
          <p className="text-text-muted text-sm text-center py-8">No transactions yet</p>
        ) : (
          <div className="flex flex-col divide-y divide-divider">
            {transactions.map(t => (
              <div key={t.id} className="flex items-center justify-between py-3">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-full flex items-center justify-center bg-success/20">
                    <ArrowDownLeft size={16} className="text-success" />
                  </div>
                  <div>
                    <p className="text-sm font-medium">
                      {t.user_name ? `Consultation with ${t.user_name}` : 'Consultation Earning'}
                      {t.duration_seconds ? ` · ${Math.floor(t.duration_seconds / 60)}m ${t.duration_seconds % 60}s` : ''}
                    </p>
                    <p className="text-xs text-text-muted">{format(new Date(t.created_at), 'MMM d, yyyy · h:mm a')}</p>
                  </div>
                </div>
                <p className="text-sm font-semibold text-success">
                  +₹{Number(t.amount).toFixed(2)}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
