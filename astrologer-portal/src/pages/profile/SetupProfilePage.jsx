import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Star, Plus, X } from 'lucide-react'
import { astrologerAPI } from '../../services/api'
import { useAuth } from '../../context/AuthContext'
import toast from 'react-hot-toast'

const SPECIALIZATIONS = ['Vedic Astrology', 'Tarot', 'Numerology', 'KP Astrology', 'Western Astrology', 'Face Reading', 'Vastu', 'Prashna']
const LANGUAGES = ['Hindi', 'English', 'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Bengali', 'Marathi', 'Gujarati']

export default function SetupProfilePage() {
  const [form, setForm] = useState({
    display_name: '', bio: '', experience_years: '',
    per_minute_rate_chat: 10, per_minute_rate_call: 15, per_minute_rate_video: 20,
    specializations: [], languages: [], expertise_areas: [],
  })
  const [newExpertise, setNewExpertise] = useState('')
  const [loading, setLoading] = useState(false)
  const { setAstrologer } = useAuth()
  const navigate = useNavigate()

  function set(key, val) {
    setForm(p => ({ ...p, [key]: val }))
  }

  function toggleItem(key, val) {
    setForm(p => ({
      ...p,
      [key]: p[key].includes(val) ? p[key].filter(x => x !== val) : [...p[key], val],
    }))
  }

  function addExpertise() {
    if (!newExpertise.trim()) return
    setForm(p => ({ ...p, expertise_areas: [...p.expertise_areas, newExpertise.trim()] }))
    setNewExpertise('')
  }

  async function handleSubmit(e) {
    e.preventDefault()
    if (!form.display_name || !form.bio || !form.experience_years) {
      toast.error('Please fill in all required fields')
      return
    }
    setLoading(true)
    try {
      const res = await astrologerAPI.register({
        ...form,
        experience_years: parseInt(form.experience_years),
      })
      setAstrologer(res.data.data)
      toast.success('Astrologer profile created!')
      navigate('/dashboard')
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to create profile')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold">Setup Astrologer Profile</h1>
        <p className="text-text-secondary text-sm mt-1">Complete your profile to start accepting consultations</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Basic Info */}
        <div className="card space-y-4">
          <h3 className="font-semibold text-text-primary">Basic Information</h3>
          <div>
            <label className="block text-sm text-text-secondary mb-1.5">Display Name *</label>
            <input className="input-field" placeholder="Name shown to clients" value={form.display_name}
              onChange={e => set('display_name', e.target.value)} required />
          </div>
          <div>
            <label className="block text-sm text-text-secondary mb-1.5">Bio *</label>
            <textarea className="input-field min-h-[100px] resize-none" placeholder="Tell clients about yourself, your expertise and approach..."
              value={form.bio} onChange={e => set('bio', e.target.value)} required />
          </div>
          <div>
            <label className="block text-sm text-text-secondary mb-1.5">Years of Experience *</label>
            <input type="number" min="0" max="60" className="input-field" placeholder="e.g. 5"
              value={form.experience_years} onChange={e => set('experience_years', e.target.value)} required />
          </div>
        </div>

        {/* Specializations */}
        <div className="card space-y-3">
          <h3 className="font-semibold">Specializations</h3>
          <div className="flex flex-wrap gap-2">
            {SPECIALIZATIONS.map(s => (
              <button key={s} type="button" onClick={() => toggleItem('specializations', s)}
                className={`px-3 py-1.5 rounded-xl text-sm font-medium transition-colors ${
                  form.specializations.includes(s)
                    ? 'bg-orange text-white'
                    : 'bg-surface-light text-text-secondary hover:text-text-primary border border-border'
                }`}>
                {s}
              </button>
            ))}
          </div>
        </div>

        {/* Languages */}
        <div className="card space-y-3">
          <h3 className="font-semibold">Languages</h3>
          <div className="flex flex-wrap gap-2">
            {LANGUAGES.map(l => (
              <button key={l} type="button" onClick={() => toggleItem('languages', l)}
                className={`px-3 py-1.5 rounded-xl text-sm font-medium transition-colors ${
                  form.languages.includes(l)
                    ? 'bg-orange text-white'
                    : 'bg-surface-light text-text-secondary hover:text-text-primary border border-border'
                }`}>
                {l}
              </button>
            ))}
          </div>
        </div>

        {/* Expertise Areas */}
        <div className="card space-y-3">
          <h3 className="font-semibold">Expertise Areas</h3>
          <div className="flex gap-2">
            <input className="input-field flex-1" placeholder="e.g. Marriage, Career, Health"
              value={newExpertise} onChange={e => setNewExpertise(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && (e.preventDefault(), addExpertise())} />
            <button type="button" onClick={addExpertise}
              className="w-12 h-12 bg-orange rounded-xl flex items-center justify-center shrink-0 hover:bg-orange-light transition-colors">
              <Plus size={20} className="text-white" />
            </button>
          </div>
          {form.expertise_areas.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {form.expertise_areas.map(a => (
                <span key={a} className="badge badge-orange">
                  {a}
                  <button type="button" onClick={() => set('expertise_areas', form.expertise_areas.filter(x => x !== a))}>
                    <X size={12} />
                  </button>
                </span>
              ))}
            </div>
          )}
        </div>

        {/* Rates */}
        <div className="card space-y-4">
          <h3 className="font-semibold">Per Minute Rates (₹)</h3>
          <div className="grid grid-cols-3 gap-4">
            {[
              { key: 'per_minute_rate_chat', label: 'Chat' },
              { key: 'per_minute_rate_call', label: 'Call' },
              { key: 'per_minute_rate_video', label: 'Video' },
            ].map(({ key, label }) => (
              <div key={key}>
                <label className="block text-sm text-text-secondary mb-1.5">{label}</label>
                <input type="number" min="1" className="input-field" value={form[key]}
                  onChange={e => set(key, parseInt(e.target.value))} />
              </div>
            ))}
          </div>
        </div>

        <button type="submit" disabled={loading} className="btn-primary w-full">
          {loading ? 'Creating Profile...' : 'Complete Setup'}
        </button>
      </form>
    </div>
  )
}
