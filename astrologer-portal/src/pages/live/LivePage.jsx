import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Radio, Play, Square, Users, Plus, Clock } from 'lucide-react'
import { liveAPI } from '../../services/api'
import { useAuth } from '../../context/AuthContext'
import { format, formatDistanceToNow } from 'date-fns'
import toast from 'react-hot-toast'

// ─── Main page ────────────────────────────────────────────────────────────────
export default function LivePage() {
  const { astrologer } = useAuth()
  const navigate = useNavigate()
  const [sessions, setSessions] = useState([])
  const [loading, setLoading] = useState(true)
  const [creating, setCreating] = useState(false)
  const [newTitle, setNewTitle] = useState('')
  const [newDesc, setNewDesc] = useState('')
  const [showForm, setShowForm] = useState(false)

  useEffect(() => {
    liveAPI.getSessions()
      .then(res => setSessions(res.data.data || []))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  async function createSession() {
    if (!newTitle.trim()) return
    setCreating(true)
    try {
      const res = await liveAPI.createSession({ title: newTitle, description: newDesc })
      setSessions(p => [res.data.data, ...p])
      setNewTitle('')
      setNewDesc('')
      setShowForm(false)
      toast.success('Session created!')
    } catch {
      toast.error('Failed to create session')
    } finally {
      setCreating(false)
    }
  }

  async function startSession(session) {
    try {
      await liveAPI.startSession(session.id)
      toast.success('You are now LIVE! 🔴')
      navigate(`/live/broadcast/${session.id}`)
    } catch {
      toast.error('Failed to start session')
    }
  }

  if (!astrologer) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-3">
        <Radio size={40} className="text-text-muted" />
        <p className="text-text-secondary">Complete your astrologer profile first</p>
      </div>
    )
  }

  const liveSessions = sessions.filter(s => s.status === 'live')
  const scheduled = sessions.filter(s => s.status === 'scheduled')
  const past = sessions.filter(s => s.status === 'ended')

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Live Sessions</h1>
          <p className="text-text-secondary text-sm mt-1">Broadcast to your audience in real-time</p>
        </div>
        <button onClick={() => setShowForm(true)} className="btn-primary w-auto px-5 flex items-center gap-2">
          <Plus size={18} /> New Session
        </button>
      </div>

      {/* Create Form */}
      {showForm && (
        <div className="card space-y-4">
          <h3 className="font-semibold">Create Live Session</h3>
          <input
            className="input-field"
            placeholder="Session title e.g. Daily Horoscope Reading"
            value={newTitle}
            onChange={e => setNewTitle(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && createSession()}
            autoFocus
          />
          <textarea
            className="input-field resize-none"
            placeholder="Description (optional)"
            rows={2}
            value={newDesc}
            onChange={e => setNewDesc(e.target.value)}
          />
          <div className="flex gap-3">
            <button onClick={() => setShowForm(false)} className="btn-ghost flex-1">Cancel</button>
            <button onClick={createSession} disabled={creating || !newTitle.trim()} className="btn-primary flex-1">
              {creating ? 'Creating...' : 'Create'}
            </button>
          </div>
        </div>
      )}

      {/* Live Now */}
      {liveSessions.length > 0 && (
        <section>
          <h3 className="text-sm font-semibold text-text-secondary uppercase tracking-wider mb-3">🔴 Live Now</h3>
          <div className="grid gap-4 sm:grid-cols-2">
            {liveSessions.map(s => (
              <SessionCard key={s.id} session={s} onGoLive={() => navigate(`/live/broadcast/${s.id}`)} onEnd={async () => { await liveAPI.endSession(s.id); setSessions(p => p.map(x => x.id === s.id ? { ...x, status: 'ended' } : x)) }} />
            ))}
          </div>
        </section>
      )}

      {/* Scheduled */}
      {scheduled.length > 0 && (
        <section>
          <h3 className="text-sm font-semibold text-text-secondary uppercase tracking-wider mb-3">📅 Scheduled</h3>
          <div className="grid gap-4 sm:grid-cols-2">
            {scheduled.map(s => (
              <SessionCard key={s.id} session={s} onGoLive={() => startSession(s)} onEnd={() => endSession(s.id)} />
            ))}
          </div>
        </section>
      )}

      {/* Past */}
      {past.length > 0 && (
        <section>
          <h3 className="text-sm font-semibold text-text-secondary uppercase tracking-wider mb-3">Past Sessions</h3>
          <div className="space-y-3">
            {past.map(s => (
              <SessionCard key={s.id} session={s} onGoLive={() => {}} onEnd={() => {}} />
            ))}
          </div>
        </section>
      )}

      {!loading && sessions.length === 0 && !showForm && (
        <div className="flex flex-col items-center justify-center py-16 gap-4">
          <div className="w-16 h-16 rounded-2xl bg-orange/20 flex items-center justify-center">
            <Radio size={28} className="text-orange" />
          </div>
          <p className="text-text-secondary text-center">No sessions yet.<br />Create your first live session!</p>
          <button onClick={() => setShowForm(true)} className="btn-primary w-auto px-8">Start Now</button>
        </div>
      )}
    </div>
  )
}

// ─── Session Card ─────────────────────────────────────────────────────────────
function SessionCard({ session, onGoLive, onEnd }) {
  const isLive = session.status === 'live'
  const isEnded = session.status === 'ended'

  return (
    <div className={`card overflow-hidden !p-0 ${isLive ? 'border-red-500/40' : ''}`}>
      {/* Thumbnail area */}
      <div className="relative h-36 flex items-center justify-center overflow-hidden rounded-t-2xl"
        style={{ background: isLive ? 'linear-gradient(135deg,#3a0d00,#1a0500)' : isEnded ? '#1a1a1a' : 'linear-gradient(135deg,#1a1500,#0d0d0d)' }}>
        {/* Star icon watermark */}
        <div className="text-orange/20 text-8xl select-none">✦</div>

        {/* LIVE badge */}
        {isLive && (
          <span className="absolute top-3 right-3 flex items-center gap-1.5 bg-red-600 text-white text-xs font-bold px-3 py-1.5 rounded-full">
            <span className="w-1.5 h-1.5 bg-white rounded-full animate-pulse" />
            LIVE
          </span>
        )}

        {/* Viewer count */}
        {isLive && session.viewer_count > 0 && (
          <span className="absolute top-3 left-3 flex items-center gap-1 bg-black/50 text-white/80 text-xs px-2 py-1 rounded-full">
            <Users size={10} /> {session.viewer_count}
          </span>
        )}

        {/* Scheduled time */}
        {!isLive && !isEnded && (
          <span className="absolute bottom-3 left-3 flex items-center gap-1 text-text-muted text-xs">
            <Clock size={10} /> Created {formatDistanceToNow(new Date(session.created_at), { addSuffix: true })}
          </span>
        )}

        {isEnded && (
          <span className="absolute inset-0 flex items-center justify-center text-text-muted text-sm font-medium bg-black/40">
            Session Ended
          </span>
        )}
      </div>

      {/* Info */}
      <div className="px-5 pt-4">
      <p className="font-semibold truncate">{session.title}</p>
      {session.description && <p className="text-text-muted text-sm mt-0.5 truncate">{session.description}</p>}
      <p className="text-xs text-text-muted mt-1">{format(new Date(session.created_at), 'MMM d, h:mm a')}</p>
      </div>

      {/* Actions */}
      <div className="flex gap-2 mt-4 px-5 pb-5">
        {isLive && (
          <>
            <button onClick={onGoLive}
              className="flex-1 flex items-center justify-center gap-2 bg-orange/20 text-orange py-2 rounded-xl text-sm font-medium hover:bg-orange/30 transition-colors">
              <Radio size={14} /> Open Broadcast
            </button>
            <button onClick={onEnd}
              className="flex items-center gap-1.5 bg-red-500/20 text-red-400 px-3 py-2 rounded-xl text-sm font-medium hover:bg-red-500/30 transition-colors">
              <Square size={14} /> End
            </button>
          </>
        )}
        {!isLive && !isEnded && (
          <button onClick={onGoLive}
            className="flex-1 flex items-center justify-center gap-2 bg-orange text-white py-2 rounded-xl text-sm font-bold hover:bg-orange/90 transition-colors">
            <Play size={14} /> Go Live
          </button>
        )}
        {isEnded && (
          <span className="text-xs text-text-muted flex items-center gap-1">
            <Clock size={12} /> Ended {formatDistanceToNow(new Date(session.created_at), { addSuffix: true })}
          </span>
        )}
      </div>
    </div>
  )
}

// ─── Immersive Broadcast View ────────────────────────────────────────────────
function BroadcastView({ session, onEnd, onViewerUpdate, onClose }) {
  const [messages, setMessages] = useState([])
  const [input, setInput] = useState('')
  const [viewerCount, setViewerCount] = useState(session.viewer_count || 0)
  const [tips, setTips] = useState(0)
  const [elapsed, setElapsed] = useState(0)
  const [ending, setEnding] = useState(false)
  const chatEndRef = useRef(null)
  const inputRef = useRef(null)

  // Timer
  useEffect(() => {
    const t = setInterval(() => setElapsed(s => s + 1), 1000)
    return () => clearInterval(t)
  }, [])

  // Socket listeners
  useEffect(() => {
    const socket = getSocket()
    if (!socket) return

    socket.emit('join_live', { session_id: session.id })

    socket.on('viewer_count', (data) => {
      setViewerCount(data.count ?? data)
      onViewerUpdate(data.count ?? data)
    })
    socket.on('live_chat_message', (data) => {
      setMessages(m => [...m, { type: 'chat', user: data.user || 'User', text: data.message || '', avatar: (data.user || 'U')[0].toUpperCase(), id: Date.now() + Math.random() }])
    })
    socket.on('new_tip', (data) => {
      const amount = data.amount || 0
      setTips(t => t + Number(amount))
      setMessages(m => [...m, { type: 'tip', user: data.user || 'User', text: `💎 sent ₹${amount} tip! ${data.message || ''}`, avatar: (data.user || 'U')[0].toUpperCase(), id: Date.now() + Math.random() }])
      toast(`💎 ${data.user} sent ₹${amount}!`, { icon: '🎁' })
    })

    return () => {
      socket.emit('leave_live', { session_id: session.id })
      socket.off('viewer_count')
      socket.off('live_chat_message')
      socket.off('new_tip')
    }
  }, [session.id])

  // Auto-scroll chat
  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  function sendMessage() {
    const text = input.trim()
    if (!text) return
    const socket = getSocket()
    socket?.emit('live_chat', { session_id: session.id, message: text })
    setMessages(m => [...m, { type: 'chat', user: 'You', text, avatar: 'Y', id: Date.now(), self: true }])
    setInput('')
    inputRef.current?.focus()
  }

  function formatTime(s) {
    const h = Math.floor(s / 3600)
    const m = Math.floor((s % 3600) / 60)
    const sec = s % 60
    if (h > 0) return `${h}:${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`
    return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`
  }

  async function handleEnd() {
    setEnding(true)
    await onEnd()
  }

  return (
    <div className="fixed inset-0 z-50 flex flex-col" style={{ background: 'linear-gradient(160deg, #3a0d00 0%, #1a0800 40%, #000 100%)' }}>
      {/* Decorative stars */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none select-none">
        {['top-10 left-20', 'top-24 right-32', 'top-40 left-1/3', 'top-16 left-2/3', 'top-60 right-20',
          'bottom-80 left-10', 'bottom-60 right-40', 'bottom-40 left-1/4'].map((pos, i) => (
          <span key={i} className={`absolute text-white/10 text-2xl ${pos}`}
            style={{ fontSize: [12, 16, 8, 20, 10, 14, 18, 9][i] }}>✦</span>
        ))}
      </div>

      {/* Top bar */}
      <div className="relative z-10 flex items-center gap-3 px-4 py-3 bg-black/40 backdrop-blur-sm border-b border-white/10">
        {/* LIVE badge */}
        <span className="flex items-center gap-1.5 bg-red-600 text-white text-xs font-bold px-3 py-1.5 rounded-full">
          <span className="w-2 h-2 bg-white rounded-full animate-pulse" />
          LIVE
        </span>

        {/* Duration */}
        <span className="flex items-center gap-1.5 bg-black/40 text-white/80 text-xs px-3 py-1.5 rounded-full font-mono">
          <Clock size={10} /> {formatTime(elapsed)}
        </span>

        {/* Viewer count */}
        <span className="flex items-center gap-1.5 bg-black/40 text-white/80 text-xs px-3 py-1.5 rounded-full">
          <Users size={10} /> {viewerCount} watching
        </span>

        {tips > 0 && (
          <span className="flex items-center gap-1.5 bg-yellow-500/20 text-yellow-400 text-xs px-3 py-1.5 rounded-full font-medium">
            💎 ₹{tips} tips
          </span>
        )}

        <div className="flex-1" />

        {/* Session title */}
        <p className="text-white/70 text-sm truncate max-w-xs hidden sm:block">{session.title}</p>

        {/* End button */}
        <button
          onClick={handleEnd}
          disabled={ending}
          className="flex items-center gap-2 bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-xl text-sm font-bold transition-colors disabled:opacity-60"
        >
          <Square size={14} /> {ending ? 'Ending...' : 'End Live'}
        </button>

        <button onClick={onClose} className="text-white/50 hover:text-white ml-1 transition-colors">
          <X size={20} />
        </button>
      </div>

      {/* Main area: broadcast preview + chat side by side on desktop, stacked on mobile */}
      <div className="flex-1 flex flex-col lg:flex-row min-h-0">

        {/* Broadcast preview panel */}
        <div className="relative flex-1 flex items-center justify-center">
          {/* Astrologer avatar / video placeholder */}
          <div className="flex flex-col items-center gap-4">
            <div className="w-32 h-32 rounded-full border-4 border-orange/60 flex items-center justify-center text-5xl font-bold text-orange"
              style={{ background: 'rgba(232,118,42,0.15)' }}>
              {session.astrologer_name?.[0] || 'A'}
            </div>
            <div className="text-center">
              <p className="text-white text-xl font-bold">{session.astrologer_name || 'You'}</p>
              <p className="text-white/60 text-sm mt-1">{session.title}</p>
            </div>
            <div className="flex items-center gap-2 mt-2">
              <span className="w-2 h-2 bg-red-500 rounded-full animate-pulse" />
              <span className="text-red-400 text-sm font-semibold">Broadcasting live</span>
            </div>
          </div>

          {/* Tips ticker at bottom of preview */}
          {tips > 0 && (
            <div className="absolute bottom-4 left-1/2 -translate-x-1/2 bg-yellow-500/20 backdrop-blur-sm border border-yellow-500/30 text-yellow-300 text-sm px-5 py-2 rounded-full font-medium">
              💎 Total tips: ₹{tips}
            </div>
          )}
        </div>

        {/* Chat panel */}
        <div className="flex flex-col w-full lg:w-80 xl:w-96 bg-black/50 backdrop-blur-sm border-t lg:border-t-0 lg:border-l border-white/10">
          {/* Chat header */}
          <div className="px-4 py-3 border-b border-white/10 flex items-center gap-2">
            <span className="text-white/70 text-sm font-semibold">Live Chat</span>
            <span className="text-xs text-white/40">{messages.length} messages</span>
          </div>

          {/* Messages */}
          <div className="flex-1 overflow-y-auto px-3 py-3 space-y-3 min-h-0" style={{ maxHeight: 'calc(100vh - 220px)' }}>
            {messages.length === 0 && (
              <div className="flex flex-col items-center justify-center h-32 gap-2 text-white/30">
                <Users size={24} />
                <p className="text-xs text-center">Chat messages will appear here<br />as viewers send them</p>
              </div>
            )}
            {messages.map(msg => (
              <ChatBubble key={msg.id} msg={msg} />
            ))}
            <div ref={chatEndRef} />
          </div>

          {/* Input */}
          <div className="p-3 border-t border-white/10">
            <div className="flex gap-2">
              <input
                ref={inputRef}
                value={input}
                onChange={e => setInput(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && sendMessage()}
                placeholder="Say something to viewers…"
                className="flex-1 bg-white/10 border border-white/15 text-white placeholder-white/30 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-orange/50"
              />
              <button onClick={sendMessage}
                className="bg-orange hover:bg-orange/90 text-white w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 transition-colors">
                <Send size={16} />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

function ChatBubble({ msg }) {
  const isTip = msg.type === 'tip'
  const isSelf = msg.self

  return (
    <div className={`flex items-start gap-2 ${isSelf ? 'flex-row-reverse' : ''}`}>
      <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0 ${
        isTip ? 'bg-yellow-500/80 text-black' : isSelf ? 'bg-orange text-white' : 'bg-white/20 text-white'
      }`}>
        {msg.avatar}
      </div>
      <div className={`max-w-[80%] rounded-2xl px-3 py-2 text-sm ${
        isTip ? 'bg-yellow-500/20 border border-yellow-500/30 text-yellow-200'
          : isSelf ? 'bg-orange/30 text-white'
          : 'bg-white/10 text-white'
      }`}>
        <span className={`font-semibold text-xs mr-1 ${isTip ? 'text-yellow-400' : isSelf ? 'text-orange' : 'text-orange/80'}`}>
          {msg.user}
        </span>
        {msg.text}
      </div>
    </div>
  )
}
