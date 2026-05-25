import { useRef, useState } from 'react'
import { Star, Edit2, Save, X, Camera, Loader } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import { authAPI } from '../../services/api'
import toast from 'react-hot-toast'
import { useNavigate } from 'react-router-dom'

export default function ProfilePage() {
  const { user, astrologer, fetchProfile } = useAuth()
  const [editing, setEditing] = useState(false)
  const [loading, setLoading] = useState(false)
  const [avatarUploading, setAvatarUploading] = useState(false)
  const [avatarPreview, setAvatarPreview] = useState(null)
  const [form, setForm] = useState({ name: user?.name || '', birth_place: user?.birth_place || '' })
  const fileInputRef = useRef(null)
  const navigate = useNavigate()

  async function saveProfile() {
    setLoading(true)
    try {
      await authAPI.updateProfile(form)
      await fetchProfile()
      setEditing(false)
      toast.success('Profile updated')
    } catch {
      toast.error('Update failed')
    } finally {
      setLoading(false)
    }
  }

  async function handleAvatarChange(e) {
    const file = e.target.files?.[0]
    if (!file) return
    if (file.size > 5 * 1024 * 1024) { toast.error('Image must be under 5MB'); return }

    // Show local preview instantly
    setAvatarPreview(URL.createObjectURL(file))
    setAvatarUploading(true)
    try {
      await authAPI.uploadAvatar(file)
      await fetchProfile()
      toast.success('Profile photo updated!')
    } catch {
      toast.error('Upload failed')
      setAvatarPreview(null)
    } finally {
      setAvatarUploading(false)
    }
  }

  if (!astrologer) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-4">
        <Star size={40} className="text-orange" />
        <p className="text-text-secondary">You haven't set up your astrologer profile yet.</p>
        <button onClick={() => navigate('/setup-profile')} className="btn-primary w-auto px-8">
          Setup Profile
        </button>
      </div>
    )
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">My Profile</h1>
        {!editing
          ? <button onClick={() => setEditing(true)} className="btn-ghost flex items-center gap-2 py-2"><Edit2 size={16} /> Edit</button>
          : <div className="flex gap-2">
              <button onClick={() => setEditing(false)} className="btn-ghost flex items-center gap-2 py-2"><X size={16} /> Cancel</button>
              <button onClick={saveProfile} disabled={loading} className="btn-primary py-2 px-4 w-auto flex items-center gap-2">
                <Save size={16} />{loading ? 'Saving...' : 'Save'}
              </button>
            </div>
        }
      </div>

      {/* Avatar + Name */}
      <div className="card flex items-center gap-4">
        {/* Avatar with upload overlay */}
        <div className="relative shrink-0 group">
          <div className="w-20 h-20 rounded-full overflow-hidden bg-orange/20 flex items-center justify-center text-orange font-bold text-3xl">
            {(avatarPreview || user?.avatar_url)
              ? <img src={avatarPreview || user.avatar_url} alt="avatar" className="w-full h-full object-cover" />
              : <span>{user?.name?.[0]?.toUpperCase()}</span>
            }
          </div>
          {/* Upload overlay */}
          <button
            onClick={() => fileInputRef.current?.click()}
            disabled={avatarUploading}
            className="absolute inset-0 rounded-full bg-black/50 flex flex-col items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer"
          >
            {avatarUploading
              ? <Loader size={18} className="text-white animate-spin" />
              : <><Camera size={18} className="text-white" /><span className="text-white text-xs mt-1">Change</span></>
            }
          </button>
          <input ref={fileInputRef} type="file" accept="image/*" className="hidden" onChange={handleAvatarChange} />
          {/* Small camera badge */}
          {!avatarUploading && (
            <button
              onClick={() => fileInputRef.current?.click()}
              className="absolute bottom-0 right-0 w-6 h-6 bg-orange rounded-full flex items-center justify-center border-2 border-card"
            >
              <Camera size={12} className="text-white" />
            </button>
          )}
        </div>

        <div className="flex-1">
          {editing
            ? <input className="input-field mb-2" value={form.name} onChange={e => setForm(p => ({ ...p, name: e.target.value }))} />
            : <h2 className="text-xl font-semibold">{user?.name}</h2>
          }
          <p className="text-text-secondary text-sm">{user?.email}</p>
          <div className="flex items-center gap-3 mt-2 flex-wrap">
            <span className={`badge ${astrologer.is_available ? 'badge-online' : 'badge-offline'}`}>
              {astrologer.is_available ? '● Online' : '● Offline'}
            </span>
            {user?.sun_sign && <span className="badge badge-orange">☀ {user.sun_sign}</span>}
          </div>
        </div>
      </div>

      {/* Astrologer Info */}
      <div className="card space-y-4">
        <h3 className="font-semibold">Astrologer Details</h3>
        <Row label="Display Name" value={astrologer.display_name} />
        <Row label="Experience" value={`${astrologer.experience_years} years`} />
        <Row label="Rating" value={`${Number(astrologer.rating || 0).toFixed(1)} ★ (${astrologer.review_count || 0} reviews)`} />
        <Row label="Total Consultations" value={astrologer.total_consultations || 0} />
        <div>
          <p className="text-sm text-text-secondary mb-1">Bio</p>
          <p className="text-text-primary text-sm">{astrologer.bio || '—'}</p>
        </div>
      </div>

      {/* Rates */}
      <div className="card">
        <h3 className="font-semibold mb-4">Per Minute Rates</h3>
        <div className="grid grid-cols-3 gap-4">
          <RateCard label="Chat" value={astrologer.per_minute_rate_chat} />
          <RateCard label="Call" value={astrologer.per_minute_rate_call} />
          <RateCard label="Video" value={astrologer.per_minute_rate_video} />
        </div>
      </div>

      {/* Specializations */}
      {astrologer.specializations?.length > 0 && (
        <div className="card">
          <h3 className="font-semibold mb-3">Specializations</h3>
          <div className="flex flex-wrap gap-2">
            {astrologer.specializations.map(s => (
              <span key={s} className="badge badge-orange">{s}</span>
            ))}
          </div>
        </div>
      )}

      {/* Languages */}
      {astrologer.languages?.length > 0 && (
        <div className="card">
          <h3 className="font-semibold mb-3">Languages</h3>
          <div className="flex flex-wrap gap-2">
            {astrologer.languages.map(l => (
              <span key={l} className="px-3 py-1 bg-surface-light border border-border rounded-xl text-sm text-text-secondary">{l}</span>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

function Row({ label, value }) {
  return (
    <div className="flex justify-between items-center">
      <span className="text-sm text-text-secondary">{label}</span>
      <span className="text-sm font-medium text-text-primary">{value}</span>
    </div>
  )
}

function RateCard({ label, value }) {
  return (
    <div className="bg-surface-light border border-border rounded-xl p-3 text-center">
      <p className="text-xl font-bold text-orange">₹{value}</p>
      <p className="text-xs text-text-muted mt-1">{label}/min</p>
    </div>
  )
}
