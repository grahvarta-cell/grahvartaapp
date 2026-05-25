import { useEffect, useRef, useState } from 'react'
import { Mic, MicOff, Video, VideoOff, PhoneOff, Clock } from 'lucide-react'
import AgoraRTC from 'agora-rtc-sdk-ng'
import api from '../../services/api'
import toast from 'react-hot-toast'

const AGORA_APP_ID = 'e2e9d562aa754dcca16a5219e557b133'

export default function CallScreen({ consultation, onEnd }) {
  const [muted, setMuted] = useState(false)
  const [videoOff, setVideoOff] = useState(false)
  const [duration, setDuration] = useState(0)
  const [status, setStatus] = useState('connecting')

  const clientRef = useRef(null)
  const localAudioRef = useRef(null)
  const localVideoRef = useRef(null)
  const remoteVideoRef = useRef(null)

  const isVideo = consultation.type === 'video'
  const channelName = String(consultation.id)

  useEffect(() => {
    let timer
    if (status === 'active') {
      timer = setInterval(() => setDuration(d => d + 1), 1000)
    }
    return () => clearInterval(timer)
  }, [status])

  useEffect(() => {
    startCall()
    return () => cleanup()
  }, [])

  async function startCall() {
    try {
      // Fetch token from backend
      const res = await api.get(`/agora/token?channel=${channelName}&uid=1`)
      const { token, app_id } = res.data

      const client = AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' })
      clientRef.current = client

      // Handle remote user publishing tracks
      client.on('user-published', async (user, mediaType) => {
        await client.subscribe(user, mediaType)
        if (mediaType === 'video' && remoteVideoRef.current) {
          user.videoTrack?.play(remoteVideoRef.current)
        }
        if (mediaType === 'audio') {
          user.audioTrack?.play()
        }
        setStatus('active')
      })

      client.on('user-unpublished', () => {})
      client.on('user-left', () => {
        setStatus('ended')
        onEnd?.()
      })

      await client.join(app_id || AGORA_APP_ID, channelName, token || null, 1)

      // Create and publish local tracks
      if (isVideo) {
        const [audioTrack, videoTrack] = await AgoraRTC.createMicrophoneAndCameraTracks()
        localAudioRef.current = audioTrack
        localVideoRef.current = videoTrack
        videoTrack.play(document.getElementById('local-video'))
        await client.publish([audioTrack, videoTrack])
      } else {
        const audioTrack = await AgoraRTC.createMicrophoneAudioTrack()
        localAudioRef.current = audioTrack
        await client.publish([audioTrack])
      }

      setStatus('active')
    } catch (err) {
      console.error('Agora call error:', err)
      toast.error('Failed to connect call')
      setStatus('ended')
    }
  }

  async function cleanup() {
    localAudioRef.current?.close()
    localVideoRef.current?.close()
    if (clientRef.current) {
      await clientRef.current.leave()
    }
  }

  async function toggleMute() {
    if (localAudioRef.current) {
      await localAudioRef.current.setEnabled(muted)
      setMuted(m => !m)
    }
  }

  async function toggleVideo() {
    if (localVideoRef.current) {
      await localVideoRef.current.setEnabled(videoOff)
      setVideoOff(v => !v)
    }
  }

  async function endCall() {
    await cleanup()
    consultation.socket?.emit('end_consultation', { consultation_id: consultation.id })
    setStatus('ended')
    onEnd?.()
  }

  const formatDuration = (s) => `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`

  return (
    <div className="fixed inset-0 z-50 bg-black flex flex-col">
      {/* Remote video / audio */}
      <div className="flex-1 relative flex items-center justify-center">
        {isVideo ? (
          <div ref={remoteVideoRef} className="w-full h-full" />
        ) : (
          <div className="flex flex-col items-center gap-4">
            <div className="w-24 h-24 rounded-full bg-orange/20 flex items-center justify-center text-4xl text-orange font-bold">
              {consultation.user_name?.[0]?.toUpperCase()}
            </div>
            <p className="text-white text-xl font-semibold">{consultation.user_name}</p>
            <p className="text-white/60 text-sm">
              {status === 'connecting' ? 'Connecting…' : status === 'active' ? 'Voice Call' : 'Call Ended'}
            </p>
          </div>
        )}

        {/* Duration badge */}
        <div className="absolute top-6 left-0 right-0 flex justify-center">
          <div className="flex items-center gap-2 bg-black/50 rounded-full px-4 py-1.5">
            <Clock size={14} className="text-white/70" />
            <span className="text-white text-sm font-mono">
              {status === 'connecting' ? 'Connecting…' : formatDuration(duration)}
            </span>
          </div>
        </div>

        {/* Local video PiP */}
        {isVideo && (
          <div className="absolute bottom-6 right-6 w-32 h-24 rounded-xl overflow-hidden border-2 border-white/20 bg-black">
            <div id="local-video" className="w-full h-full" />
            {videoOff && (
              <div className="absolute inset-0 bg-surface flex items-center justify-center">
                <VideoOff size={20} className="text-text-muted" />
              </div>
            )}
          </div>
        )}
      </div>

      {/* Controls */}
      <div className="flex items-center justify-center gap-6 py-8 bg-gradient-to-t from-black/80 to-transparent">
        <button
          onClick={toggleMute}
          className={`w-14 h-14 rounded-full flex items-center justify-center transition-colors ${muted ? 'bg-red-600' : 'bg-white/20 hover:bg-white/30'}`}
        >
          {muted ? <MicOff size={22} className="text-white" /> : <Mic size={22} className="text-white" />}
        </button>

        {isVideo && (
          <button
            onClick={toggleVideo}
            className={`w-14 h-14 rounded-full flex items-center justify-center transition-colors ${videoOff ? 'bg-red-600' : 'bg-white/20 hover:bg-white/30'}`}
          >
            {videoOff ? <VideoOff size={22} className="text-white" /> : <Video size={22} className="text-white" />}
          </button>
        )}

        <button
          onClick={endCall}
          className="w-16 h-16 rounded-full bg-red-600 flex items-center justify-center hover:bg-red-700 transition-colors"
        >
          <PhoneOff size={24} className="text-white" />
        </button>
      </div>
    </div>
  )
}
