import { useEffect, useState, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { Users, Star, TrendingUp, Clock, ToggleLeft, ToggleRight, ArrowRight, Phone, Video, MessageSquare, X, Check } from 'lucide-react'
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'
import { astrologerAPI } from '../../services/api'
import { useAuth } from '../../context/AuthContext'
import { getSocket } from '../../services/socket'
import { format } from 'date-fns'
import toast from 'react-hot-toast'
import CallScreen from '../call/CallScreen'

const TYPE_ICON = { chat: MessageSquare, voice: Phone, video: Video }

export default function DashboardPage() {
  const { user, astrologer, setAstrologer } = useAuth()
  const [dashboard, setDashboard] = useState(null)
  const [loading, setLoading] = useState(true)
  const [toggling, setToggling] = useState(false)
  const [incomingRequest, setIncomingRequest] = useState(null) // { consultation_id, user, type, rate }
  const [activeCall, setActiveCall] = useState(null) // { id, type, user_name, socket }
  const ringtoneRef = useRef(null)
  const navigate = useNavigate()

  // Listen for incoming consultation requests
  useEffect(() => {
    const socket = getSocket()
    if (!socket) return

    const handler = (data) => {
      setIncomingRequest(data)
      try {
        const ctx = new AudioContext()
        const osc = ctx.createOscillator()
        osc.connect(ctx.destination)
        osc.frequency.value = 880
        osc.start()
        osc.stop(ctx.currentTime + 0.3)
      } catch (_) {}
    }

    // Attach immediately and also re-attach on reconnect
    socket.on('new_consultation_request', handler)
    socket.on('connect', () => {
      socket.emit('set_role', { role: 'astrologer' })
    })

    // If already connected, ensure role is set
    if (socket.connected) {
      socket.emit('set_role', { role: 'astrologer' })
    }

    return () => {
      socket.off('new_consultation_request', handler)
      socket.off('connect')
    }
  }, [])

  function acceptRequest() {
    const socket = getSocket()
    if (!socket || !incomingRequest) return
    socket.emit('accept_consultation', { consultation_id: incomingRequest.consultation_id })
    toast.success(`Consultation accepted with ${incomingRequest.user?.name}`)
    const req = incomingRequest
    setIncomingRequest(null)
    if (req.type === 'chat') {
      navigate('/chat')
    } else {
      setActiveCall({
        id: req.consultation_id,
        type: req.type,
        user_name: req.user?.name,
        socket,
      })
    }
  }

  function declineRequest() {
    const socket = getSocket()
    if (!socket || !incomingRequest) return
    socket.emit('reject_consultation', { consultation_id: incomingRequest.consultation_id })
    setIncomingRequest(null)
    toast('Request declined')
  }

  useEffect(() => {
    astrologerAPI.getDashboard()
      .then(res => setDashboard(res.data.data))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  async function toggleAvailability() {
    if (!astrologer) return
    setToggling(true)
    try {
      const next = !astrologer.is_available
      await astrologerAPI.updateAvailability(next)
      setAstrologer(p => ({ ...p, is_available: next }))
      toast.success(next ? 'You are now available' : 'You are now offline')
    } catch {
      toast.error('Failed to update availability')
    } finally {
      setToggling(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-2 border-orange border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  if (!astrologer) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-4">
        <div className="w-16 h-16 rounded-2xl bg-orange/20 flex items-center justify-center">
          <Star className="w-8 h-8 text-orange" />
        </div>
        <div className="text-center">
          <h2 className="text-xl font-semibold mb-2">Complete Your Astrologer Profile</h2>
          <p className="text-text-secondary text-sm mb-6">Set up your profile to start accepting consultations</p>
          <button onClick={() => navigate('/setup-profile')} className="btn-primary w-auto px-8">
            Get Started
          </button>
        </div>
      </div>
    )
  }

  const stats = dashboard?.stats || {}
  const recentConsultations = dashboard?.recent_consultations || []
  const earningsChart = dashboard?.earnings_chart || []

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-bold">Welcome, {user?.name?.split(' ')[0]} ✨</h1>
          <p className="text-text-secondary text-sm mt-1">Here's your performance overview</p>
        </div>
        <button
          onClick={toggleAvailability}
          disabled={toggling}
          className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-medium text-sm transition-colors ${
            astrologer.is_available
              ? 'bg-success/20 text-success hover:bg-success/30'
              : 'bg-border text-text-secondary hover:bg-surface-light'
          }`}
        >
          {astrologer.is_available
            ? <><ToggleRight size={20} /> Online</>
            : <><ToggleLeft size={20} /> Offline</>
          }
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="stat-card">
          <div className="w-9 h-9 rounded-xl bg-orange/20 flex items-center justify-center">
            <Users size={18} className="text-orange" />
          </div>
          <p className="text-2xl font-bold">{stats.total || 0}</p>
          <p className="text-text-secondary text-sm">Total Consultations</p>
        </div>
        <div className="stat-card">
          <div className="w-9 h-9 rounded-xl bg-gold/20 flex items-center justify-center">
            <Star size={18} className="text-gold" />
          </div>
          <p className="text-2xl font-bold">{Number(astrologer.rating || 0).toFixed(1)}</p>
          <p className="text-text-secondary text-sm">Rating ({astrologer.review_count || 0} reviews)</p>
        </div>
        <div className="stat-card">
          <div className="w-9 h-9 rounded-xl bg-success/20 flex items-center justify-center">
            <TrendingUp size={18} className="text-success" />
          </div>
          <p className="text-2xl font-bold">₹{Number(stats.total_revenue || 0).toFixed(0)}</p>
          <p className="text-text-secondary text-sm">Total Earnings</p>
        </div>
        <div className="stat-card">
          <div className="w-9 h-9 rounded-xl bg-blue-500/20 flex items-center justify-center">
            <Clock size={18} className="text-blue-400" />
          </div>
          <p className="text-2xl font-bold">{Math.round((stats.avg_duration || 0) / 60)}m</p>
          <p className="text-text-secondary text-sm">Avg Duration</p>
        </div>
      </div>

      {/* Earnings Chart */}
      {earningsChart.length > 0 && (
        <div className="card">
          <h3 className="font-semibold mb-4">Earnings (Last 30 Days)</h3>
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={earningsChart}>
              <defs>
                <linearGradient id="earningsGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#E8762A" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#E8762A" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey="date" tick={{ fill: '#666', fontSize: 11 }}
                tickFormatter={d => format(new Date(d), 'MMM d')} />
              <YAxis tick={{ fill: '#666', fontSize: 11 }} />
              <Tooltip
                contentStyle={{ background: '#1E1E1E', border: '1px solid #2A2A2A', borderRadius: 8 }}
                labelStyle={{ color: '#AAA' }}
                itemStyle={{ color: '#E8762A' }}
              />
              <Area type="monotone" dataKey="daily_earning" stroke="#E8762A" fill="url(#earningsGrad)" strokeWidth={2} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      )}

      {/* Recent Consultations */}
      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold">Recent Consultations</h3>
          <button onClick={() => navigate('/chat')} className="text-orange text-sm flex items-center gap-1 hover:text-orange-light">
            View all <ArrowRight size={14} />
          </button>
        </div>

        {recentConsultations.length === 0 ? (
          <p className="text-text-muted text-sm text-center py-6">No consultations yet</p>
        ) : (
          <div className="flex flex-col divide-y divide-divider">
            {recentConsultations.slice(0, 5).map(c => (
              <div key={c.id} className="flex items-center justify-between py-3">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-full bg-orange/20 flex items-center justify-center text-orange font-semibold text-sm">
                    {c.user_name?.[0]?.toUpperCase()}
                  </div>
                  <div>
                    <p className="text-sm font-medium">{c.user_name}</p>
                    <p className="text-xs text-text-muted capitalize">{c.type} · {Math.round((c.duration_seconds || 0) / 60)}m</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm font-semibold text-success">₹{Number(c.total_amount || 0).toFixed(0)}</p>
                  <p className="text-xs text-text-muted">{format(new Date(c.created_at), 'MMM d')}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
      {/* Active call screen */}
      {activeCall && (
        <CallScreen
          consultation={activeCall}
          onEnd={() => setActiveCall(null)}
        />
      )}

      {/* Incoming request modal */}
      {incomingRequest && (() => {
        const Icon = TYPE_ICON[incomingRequest.type] || MessageSquare
        return (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70">
            <div className="bg-surface rounded-2xl p-8 w-full max-w-sm mx-4 border border-orange/40 shadow-2xl animate-pulse-once">
              <div className="flex flex-col items-center gap-4 text-center">
                <div className="w-16 h-16 rounded-full bg-orange/20 flex items-center justify-center">
                  <Icon size={28} className="text-orange" />
                </div>
                <div>
                  <p className="text-xs text-text-muted uppercase tracking-wider mb-1">Incoming {incomingRequest.type} consultation</p>
                  <h2 className="text-xl font-bold">{incomingRequest.user?.name || 'User'}</h2>
                  <p className="text-text-secondary text-sm mt-1">₹{incomingRequest.rate}/min</p>
                </div>
                <div className="flex gap-4 w-full mt-2">
                  <button onClick={declineRequest} className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-red-500/20 text-red-400 hover:bg-red-500/30 font-semibold transition-colors">
                    <X size={18} /> Decline
                  </button>
                  <button onClick={acceptRequest} className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-success/20 text-success hover:bg-success/30 font-semibold transition-colors">
                    <Check size={18} /> Accept
                  </button>
                </div>
              </div>
            </div>
          </div>
        )
      })()}
    </div>
  )
}
