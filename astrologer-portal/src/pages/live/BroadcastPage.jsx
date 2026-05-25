import { useEffect, useRef, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { Clock, Users, Send, Square, X, Video, VideoOff, Mic, MicOff } from 'lucide-react'
import AgoraRTC from 'agora-rtc-sdk-ng'
import { liveAPI, agoraAPI } from '../../services/api'
import { getSocket } from '../../services/socket'
import { useAuth } from '../../context/AuthContext'
import toast from 'react-hot-toast'

export default function BroadcastPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const [session, setSession] = useState(null)
  const [messages, setMessages] = useState([])
  const [input, setInput] = useState('')
  const [viewerCount, setViewerCount] = useState(0)
  const [tips, setTips] = useState(0)
  const [elapsed, setElapsed] = useState(0)
  const [ending, setEnding] = useState(false)
  const [videoEnabled, setVideoEnabled] = useState(false)
  const [micEnabled, setMicEnabled] = useState(false)
  const [agoraJoined, setAgoraJoined] = useState(false)

  const chatEndRef = useRef(null)
  const inputRef = useRef(null)
  const localVideoRef = useRef(null)
  const clientRef = useRef(null)
  const localAudioTrackRef = useRef(null)
  const localVideoTrackRef = useRef(null)

  // Load session
  useEffect(() => {
    liveAPI.getSessions()
      .then(res => {
        const found = (res.data.data || []).find(s => String(s.id) === String(id))
        if (found) { setSession(found); setViewerCount(found.viewer_count || 0) }
      })
      .catch(() => toast.error('Could not load session'))
  }, [id])

  // Init Agora client as host
  useEffect(() => {
    const client = AgoraRTC.createClient({ mode: 'live', codec: 'vp8' })
    clientRef.current = client
    client.setClientRole('host')

    agoraAPI.getToken(id, 1)
      .then(async res => {
        const { token, app_id } = res.data
        await client.join(app_id, String(id), token || null, 1)
        setAgoraJoined(true)
      })
      .catch(e => {
        console.error('Agora join error:', e)
        toast.error('Could not join broadcast channel')
      })

    return () => {
      localAudioTrackRef.current?.close()
      localVideoTrackRef.current?.close()
      client.leave().catch(() => {})
    }
  }, [id])

  // Timer
  useEffect(() => {
    const t = setInterval(() => setElapsed(s => s + 1), 1000)
    return () => clearInterval(t)
  }, [])

  // Socket — ignore own messages using user display name
  useEffect(() => {
    const socket = getSocket()
    if (!socket) return

    socket.emit('join_live', { session_id: id })

    socket.on('viewer_count', (data) => setViewerCount(data.count ?? data))

    socket.on('live_chat_message', (data) => {
      const senderName = data.user || ''
      const myName = user?.name || ''
      if (senderName === myName || senderName === 'You') return
      setMessages(m => [...m, {
        type: 'chat',
        user: senderName,
        text: data.message || '',
        avatar: senderName[0]?.toUpperCase() || '?',
        id: Date.now() + Math.random()
      }])
    })

    socket.on('new_tip', (data) => {
      const amount = data.amount || 0
      setTips(t => t + Number(amount))
      setMessages(m => [...m, {
        type: 'tip',
        user: data.user || 'User',
        text: `💎 sent ₹${amount} tip! ${data.message || ''}`,
        avatar: (data.user || 'U')[0].toUpperCase(),
        id: Date.now() + Math.random()
      }])
      toast(`💎 ${data.user} sent ₹${amount}!`, { icon: '🎁' })
    })

    return () => {
      socket.emit('leave_live', { session_id: id })
      socket.off('viewer_count')
      socket.off('live_chat_message')
      socket.off('new_tip')
    }
  }, [id, user])

  // Auto-scroll
  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  function formatTime(s) {
    const h = Math.floor(s / 3600)
    const m = Math.floor((s % 3600) / 60)
    const sec = s % 60
    if (h > 0) return `${h}:${String(m).padStart(2, '0')}:${String(sec).padStart(2, '00')}`
    return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`
  }

  async function toggleVideo() {
    if (!agoraJoined) return toast.error('Connecting to channel…')
    if (videoEnabled) {
      await clientRef.current.unpublish(localVideoTrackRef.current)
      localVideoTrackRef.current?.close()
      localVideoTrackRef.current = null
      setVideoEnabled(false)
    } else {
      try {
        const track = await AgoraRTC.createCameraVideoTrack()
        localVideoTrackRef.current = track
        track.play(localVideoRef.current)
        await clientRef.current.publish(track)
        setVideoEnabled(true)
      } catch {
        toast.error('Could not access camera')
      }
    }
  }

  async function toggleMic() {
    if (!agoraJoined) return toast.error('Connecting to channel…')
    if (micEnabled) {
      await clientRef.current.unpublish(localAudioTrackRef.current)
      localAudioTrackRef.current?.close()
      localAudioTrackRef.current = null
      setMicEnabled(false)
    } else {
      try {
        const track = await AgoraRTC.createMicrophoneAudioTrack()
        localAudioTrackRef.current = track
        await clientRef.current.publish(track)
        setMicEnabled(true)
      } catch {
        toast.error('Could not access microphone')
      }
    }
  }

  function sendMessage() {
    const text = input.trim()
    if (!text) return
    const socket = getSocket()
    socket?.emit('live_chat', { session_id: id, message: text })
    setMessages(m => [...m, {
      type: 'chat', user: 'You', text,
      avatar: user?.name?.[0]?.toUpperCase() || 'Y',
      id: Date.now(), self: true
    }])
    setInput('')
    inputRef.current?.focus()
  }

  async function handleEnd() {
    setEnding(true)
    localAudioTrackRef.current?.close()
    localVideoTrackRef.current?.close()
    await clientRef.current?.leave().catch(() => {})
    try {
      await liveAPI.endSession(id)
      toast.success('Session ended')
      navigate('/live')
    } catch {
      toast.error('Failed to end session')
      setEnding(false)
    }
  }

  if (!session) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-black">
        <div className="w-10 h-10 border-2 border-orange border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  return (
    <div className="fixed inset-0 flex flex-col" style={{ background: 'linear-gradient(160deg, #3a0d00 0%, #1a0800 40%, #000 100%)' }}>

      {/* Top bar */}
      <div className="relative z-10 flex items-center gap-3 px-4 py-3 bg-black/40 backdrop-blur-sm border-b border-white/10 flex-shrink-0">
        <span className="flex items-center gap-1.5 bg-red-600 text-white text-xs font-bold px-3 py-1.5 rounded-full">
          <span className="w-2 h-2 bg-white rounded-full animate-pulse" /> LIVE
        </span>
        <span className="flex items-center gap-1.5 bg-black/40 text-white/80 text-xs px-3 py-1.5 rounded-full font-mono">
          <Clock size={10} /> {formatTime(elapsed)}
        </span>
        <span className="flex items-center gap-1.5 bg-black/40 text-white/80 text-xs px-3 py-1.5 rounded-full">
          <Users size={10} /> {viewerCount} watching
        </span>
        {tips > 0 && (
          <span className="flex items-center gap-1.5 bg-yellow-500/20 text-yellow-400 text-xs px-3 py-1.5 rounded-full font-medium">
            💎 ₹{tips} tips
          </span>
        )}
        <div className="flex-1" />
        <p className="text-white/60 text-sm truncate max-w-xs hidden sm:block">{session.title}</p>
        <button onClick={handleEnd} disabled={ending}
          className="flex items-center gap-2 bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-xl text-sm font-bold transition-colors disabled:opacity-60">
          <Square size={14} /> {ending ? 'Ending...' : 'End Live'}
        </button>
        <button onClick={() => navigate('/live')} className="text-white/50 hover:text-white ml-1 transition-colors">
          <X size={20} />
        </button>
      </div>

      {/* Main content */}
      <div className="flex-1 flex flex-col lg:flex-row min-h-0">

        {/* Broadcast preview */}
        <div className="relative flex-1 flex items-center justify-center overflow-hidden">
          {/* Agora local video — always rendered, hidden when off */}
          <div
            ref={localVideoRef}
            className={`w-full h-full ${videoEnabled ? 'block' : 'hidden'}`}
            style={{ position: 'absolute', inset: 0 }}
          />

          {/* Placeholder shown when camera off */}
          {!videoEnabled && (
            <div className="flex flex-col items-center gap-4 text-center px-4">
              <div className="w-32 h-32 rounded-full border-4 border-orange/60 flex items-center justify-center text-5xl font-bold text-orange"
                style={{ background: 'rgba(232,118,42,0.15)' }}>
                {session.astrologer_name?.[0] || 'A'}
              </div>
              <div>
                <p className="text-white text-xl font-bold">{session.astrologer_name || 'You'}</p>
                <p className="text-white/60 text-sm mt-1">{session.title}</p>
              </div>
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 bg-red-500 rounded-full animate-pulse" />
                <span className="text-red-400 text-sm font-semibold">Broadcasting live</span>
              </div>
              <p className="text-white/30 text-xs">Click the camera button below to share your video</p>
            </div>
          )}

          {/* Camera / Mic controls at bottom of preview */}
          <div className="absolute bottom-6 left-1/2 -translate-x-1/2 flex items-center gap-3 z-10">
            <button onClick={toggleMic}
              className={`w-12 h-12 rounded-full flex items-center justify-center transition-colors ${micEnabled ? 'bg-orange' : 'bg-black/60 border border-white/20'}`}>
              {micEnabled ? <Mic size={18} className="text-white" /> : <MicOff size={18} className="text-white/60" />}
            </button>
            <button onClick={toggleVideo}
              className={`w-12 h-12 rounded-full flex items-center justify-center transition-colors ${videoEnabled ? 'bg-orange' : 'bg-black/60 border border-white/20'}`}>
              {videoEnabled ? <Video size={18} className="text-white" /> : <VideoOff size={18} className="text-white/60" />}
            </button>
          </div>

          {tips > 0 && (
            <div className="absolute top-4 left-1/2 -translate-x-1/2 bg-yellow-500/20 backdrop-blur-sm border border-yellow-500/30 text-yellow-300 text-sm px-5 py-2 rounded-full z-10">
              💎 Total tips: ₹{tips}
            </div>
          )}
        </div>

        {/* Chat panel */}
        <div className="flex flex-col w-full lg:w-80 xl:w-96 bg-black/50 backdrop-blur-sm border-t lg:border-t-0 lg:border-l border-white/10" style={{ minHeight: 0 }}>
          <div className="px-4 py-3 border-b border-white/10 flex items-center gap-2 flex-shrink-0">
            <span className="text-white/70 text-sm font-semibold">Live Chat</span>
            <span className="text-xs text-white/40">{messages.length} messages</span>
          </div>
          <div className="flex-1 overflow-y-auto px-3 py-3 space-y-3">
            {messages.length === 0 && (
              <div className="flex flex-col items-center justify-center h-32 gap-2 text-white/30">
                <Users size={24} />
                <p className="text-xs text-center">Viewer messages appear here</p>
              </div>
            )}
            {messages.map(msg => <ChatBubble key={msg.id} msg={msg} />)}
            <div ref={chatEndRef} />
          </div>
          <div className="p-3 border-t border-white/10 flex-shrink-0">
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
