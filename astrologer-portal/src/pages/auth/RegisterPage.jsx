import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Star, Eye, EyeOff } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import toast from 'react-hot-toast'

export default function RegisterPage() {
  const [showPass, setShowPass] = useState(false)
  const [loading, setLoading] = useState(false)
  const [form, setForm] = useState({ name: '', emailUser: '', password: '' })
  const { register } = useAuth()
  const navigate = useNavigate()

  function set(key, val) {
    setForm(p => ({ ...p, [key]: val }))
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setLoading(true)
    try {
      await register({ ...form, email: `${form.emailUser}@astrovaak.online` })
      toast.success('Account created!')
      navigate('/setup-profile')
    } catch (err) {
      toast.error(err.response?.data?.message || 'Registration failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-background">
      <div className="w-full max-w-md">
        <div className="flex flex-col items-center mb-10">
          <div className="w-16 h-16 rounded-2xl bg-orange/20 flex items-center justify-center mb-4">
            <Star className="w-8 h-8 text-orange fill-orange" />
          </div>
          <h1 className="text-2xl font-bold text-text-primary">AstroVaak</h1>
          <p className="text-text-secondary text-sm mt-1">Astrologer Portal</p>
        </div>

        <div className="card">
          <h2 className="text-xl font-semibold mb-1">Create Account</h2>
          <p className="text-text-secondary text-sm mb-6">Join as an astrologer on AstroVaak</p>

          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div>
              <label className="block text-sm text-text-secondary mb-1.5">Full Name</label>
              <input className="input-field" placeholder="Your name" value={form.name}
                onChange={e => set('name', e.target.value)} required />
            </div>
            <div>
              <label className="block text-sm text-text-secondary mb-1.5">Email</label>
              <div className="flex items-center bg-surface border border-border rounded-xl overflow-hidden focus-within:border-orange transition-colors">
                <input
                  type="text"
                  className="flex-1 bg-transparent px-4 py-2.5 text-sm text-white placeholder-text-muted focus:outline-none"
                  placeholder="yourname"
                  value={form.emailUser}
                  onChange={e => set('emailUser', e.target.value.replace(/[^a-zA-Z0-9._\-]/g, ''))}
                  required
                />
                <span className="px-3 py-2.5 text-sm text-text-muted bg-surface-light border-l border-border select-none whitespace-nowrap">
                  @astrovaak.online
                </span>
              </div>
            </div>
            <div>
              <label className="block text-sm text-text-secondary mb-1.5">Password</label>
              <div className="relative">
                <input type={showPass ? 'text' : 'password'} className="input-field pr-11"
                  placeholder="Min 8 characters" value={form.password}
                  onChange={e => set('password', e.target.value)} required minLength={8} />
                <button type="button" onClick={() => setShowPass(p => !p)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-secondary">
                  {showPass ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>
            <button type="submit" disabled={loading} className="btn-primary mt-2">
              {loading ? 'Creating...' : 'Create Account'}
            </button>
          </form>

          <p className="text-center text-text-secondary text-sm mt-6">
            Already have an account?{' '}
            <Link to="/login" className="text-orange hover:text-orange-light font-medium">Sign in</Link>
          </p>
        </div>
      </div>
    </div>
  )
}
