import { useAuth } from '../context/AuthContext'
import { Clock, XCircle, LogOut } from 'lucide-react'
import { useNavigate } from 'react-router-dom'

export default function PendingApprovalPage() {
  const { astrologer, logout } = useAuth()
  const navigate = useNavigate()
  const rejected = astrologer?.status === 'rejected'

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-background flex items-center justify-center px-4">
      <div className="max-w-md w-full text-center">

        <div className={`w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6 ${rejected ? 'bg-error/15' : 'bg-orange/15'}`}>
          {rejected
            ? <XCircle size={40} className="text-error" />
            : <Clock size={40} className="text-orange" />
          }
        </div>

        <h1 className="text-2xl font-bold text-white mb-3">
          {rejected ? 'Application Rejected' : 'Pending Approval'}
        </h1>

        <p className="text-text-secondary text-sm leading-relaxed mb-4">
          {rejected
            ? 'Unfortunately your astrologer application was not approved at this time.'
            : 'Your profile has been submitted and is currently under review by our team. You will be notified once approved.'
          }
        </p>

        {rejected && astrologer?.rejection_reason && (
          <div className="bg-error/10 border border-error/20 rounded-xl px-4 py-3 mb-6 text-left">
            <p className="text-xs text-text-muted mb-1">Reason</p>
            <p className="text-sm text-error">{astrologer.rejection_reason}</p>
          </div>
        )}

        {!rejected && (
          <div className="bg-surface border border-border rounded-xl px-4 py-3 mb-6 text-left space-y-2">
            <p className="text-xs text-text-muted uppercase tracking-wide mb-2">What happens next</p>
            {['Profile review by our team (1–2 business days)', 'You\'ll receive an email once approved', 'Login again to access your dashboard'].map((step, i) => (
              <div key={i} className="flex items-start gap-2 text-sm text-text-secondary">
                <span className="w-5 h-5 rounded-full bg-orange/20 text-orange text-xs flex items-center justify-center shrink-0 mt-0.5">{i + 1}</span>
                {step}
              </div>
            ))}
          </div>
        )}

        <button
          onClick={handleLogout}
          className="flex items-center gap-2 mx-auto text-sm text-text-muted hover:text-white transition-colors"
        >
          <LogOut size={16} /> Sign out
        </button>
      </div>
    </div>
  )
}
