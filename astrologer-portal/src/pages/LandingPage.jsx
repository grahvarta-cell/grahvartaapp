import { useNavigate } from 'react-router-dom'
import { Star, Wallet, Radio, MessageSquare, TrendingUp, Shield, Clock, ChevronRight, Users, Award, Zap } from 'lucide-react'

const FEATURES = [
  {
    icon: MessageSquare,
    title: 'Chat & Call Consultations',
    desc: 'Connect with users via real-time chat, voice calls, and video — all from one dashboard.',
    color: 'text-orange bg-orange/20',
  },
  {
    icon: Radio,
    title: 'Go Live',
    desc: 'Host live astrology sessions and broadcast to hundreds of users simultaneously.',
    color: 'text-gold bg-gold/20',
  },
  {
    icon: Wallet,
    title: 'Instant Earnings',
    desc: 'Earn per minute on every consultation. Track your balance and transactions in real-time.',
    color: 'text-success bg-success/20',
  },
  {
    icon: TrendingUp,
    title: 'Analytics Dashboard',
    desc: 'Monitor your performance, ratings, consultation history and earnings growth.',
    color: 'text-blue-400 bg-blue-400/20',
  },
  {
    icon: Shield,
    title: 'Verified Profile',
    desc: 'Build trust with a verified astrologer badge and showcase your specializations.',
    color: 'text-purple-400 bg-purple-400/20',
  },
  {
    icon: Clock,
    title: 'Flexible Schedule',
    desc: 'Go online or offline anytime. You are in full control of your availability.',
    color: 'text-pink-400 bg-pink-400/20',
  },
]

const STATS = [
  { value: '10,000+', label: 'Active Users' },
  { value: '500+', label: 'Astrologers' },
  { value: '4.8★', label: 'Average Rating' },
  { value: '₹50L+', label: 'Paid to Astrologers' },
]

const STEPS = [
  { step: '01', title: 'Create Account', desc: 'Register with your email and basic details.' },
  { step: '02', title: 'Setup Profile', desc: 'Add your specializations, languages, experience and rates.' },
  { step: '03', title: 'Go Online', desc: 'Toggle availability and start receiving consultation requests.' },
  { step: '04', title: 'Earn Money', desc: 'Get paid per minute directly to your wallet.' },
]

export default function LandingPage() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen bg-background text-text-primary">
      {/* Navbar */}
      <nav className="fixed top-0 left-0 right-0 z-50 border-b border-border bg-background/80 backdrop-blur-md">
        <div className="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl bg-orange/20 flex items-center justify-center">
              <Star className="w-4 h-4 text-orange fill-orange" />
            </div>
            <span className="font-bold text-lg">AstroVaak</span>
          </div>
          <div className="flex items-center gap-6">
            <button onClick={() => navigate('/about')} className="text-text-secondary hover:text-text-primary text-sm hidden md:block">About</button>
            <button onClick={() => navigate('/contact')} className="text-text-secondary hover:text-text-primary text-sm hidden md:block">Contact</button>
            <button onClick={() => navigate('/login')} className="btn-primary py-2 px-5 w-auto text-sm">
              Astrologer Login
            </button>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="pt-32 pb-20 px-6 relative overflow-hidden">
        {/* Glow effects */}
        <div className="absolute top-20 left-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-orange/10 rounded-full blur-[120px] pointer-events-none" />
        <div className="absolute top-40 left-1/4 w-[300px] h-[300px] bg-gold/10 rounded-full blur-[80px] pointer-events-none" />

        <div className="max-w-4xl mx-auto text-center relative">
          <div className="inline-flex items-center gap-2 bg-orange/10 border border-orange/30 rounded-full px-4 py-1.5 text-sm text-orange mb-8">
            <Zap size={14} className="fill-orange" />
            India's fastest growing astrology platform
          </div>

          <h1 className="text-4xl md:text-6xl font-bold leading-tight mb-6">
            Share Your Wisdom,{' '}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-orange to-gold">
              Earn Every Minute
            </span>
          </h1>

          <p className="text-text-secondary text-lg md:text-xl max-w-2xl mx-auto mb-10">
            Join thousands of astrologers on AstroVaak. Connect with users seeking guidance,
            host live sessions, and build a thriving practice — all from one powerful portal.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <button
              onClick={() => navigate('/register')}
              className="btn-primary w-auto px-8 py-3.5 text-base flex items-center gap-2"
            >
              Join as Astrologer <ChevronRight size={18} />
            </button>
            <button
              onClick={() => navigate('/login')}
              className="btn-outline w-auto px-8 py-3.5 text-base"
            >
              Sign In
            </button>
          </div>

          <p className="text-text-muted text-sm mt-6">Free to join · No monthly fees · Earn from day one</p>
        </div>
      </section>

      {/* Stats */}
      <section className="py-12 border-y border-border">
        <div className="max-w-5xl mx-auto px-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {STATS.map(s => (
              <div key={s.label} className="text-center">
                <p className="text-3xl font-bold text-orange">{s.value}</p>
                <p className="text-text-secondary text-sm mt-1">{s.label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="py-20 px-6">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-14">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">Everything You Need to Succeed</h2>
            <p className="text-text-secondary text-lg max-w-xl mx-auto">
              A complete platform built specifically for astrologers to grow and earn.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-5">
            {FEATURES.map(f => (
              <div key={f.title} className="card hover:border-orange/30 transition-colors group">
                <div className={`w-11 h-11 rounded-xl flex items-center justify-center mb-4 ${f.color}`}>
                  <f.icon size={22} />
                </div>
                <h3 className="font-semibold text-lg mb-2">{f.title}</h3>
                <p className="text-text-secondary text-sm leading-relaxed">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="py-20 px-6 bg-surface border-y border-border">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-14">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">How It Works</h2>
            <p className="text-text-secondary text-lg">Get started in minutes</p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {STEPS.map((s, i) => (
              <div key={s.step} className="relative">
                <div className="text-5xl font-bold text-orange/20 mb-3">{s.step}</div>
                <h3 className="font-semibold mb-2">{s.title}</h3>
                <p className="text-text-secondary text-sm">{s.desc}</p>
                {i < STEPS.length - 1 && (
                  <div className="hidden lg:block absolute top-8 right-0 translate-x-1/2 text-border">
                    <ChevronRight size={20} />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Earnings highlight */}
      <section className="py-20 px-6">
        <div className="max-w-5xl mx-auto">
          <div className="rounded-2xl bg-gradient-to-br from-orange/20 via-orange/5 to-background border border-orange/30 p-10 md:p-14 flex flex-col md:flex-row items-center gap-10">
            <div className="flex-1">
              <div className="flex items-center gap-2 text-gold mb-4">
                <Award size={20} />
                <span className="text-sm font-medium">Top Earning Astrologers</span>
              </div>
              <h2 className="text-3xl md:text-4xl font-bold mb-4">
                Earn up to{' '}
                <span className="text-orange">₹1,00,000/month</span>
              </h2>
              <p className="text-text-secondary mb-6">
                Set your own per-minute rates for chat, call and video consultations.
                The more you consult, the more you earn — with no platform caps.
              </p>
              <button onClick={() => navigate('/register')} className="btn-primary w-auto px-8 flex items-center gap-2">
                Start Earning <ChevronRight size={18} />
              </button>
            </div>
            <div className="flex flex-col gap-4 w-full md:w-64 shrink-0">
              {[
                { label: 'Chat Rate', value: '₹10–₹50/min' },
                { label: 'Call Rate', value: '₹15–₹80/min' },
                { label: 'Video Rate', value: '₹20–₹100/min' },
              ].map(r => (
                <div key={r.label} className="bg-surface border border-border rounded-xl px-5 py-4 flex justify-between items-center">
                  <span className="text-text-secondary text-sm">{r.label}</span>
                  <span className="font-semibold text-orange">{r.value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 px-6 text-center border-t border-border">
        <div className="max-w-2xl mx-auto">
          <div className="w-16 h-16 rounded-2xl bg-orange/20 flex items-center justify-center mx-auto mb-6">
            <Star className="w-8 h-8 text-orange fill-orange" />
          </div>
          <h2 className="text-3xl md:text-4xl font-bold mb-4">Ready to Get Started?</h2>
          <p className="text-text-secondary text-lg mb-8">
            Join the AstroVaak family and start your journey today.
          </p>
          <button onClick={() => navigate('/register')} className="btn-primary w-auto px-10 py-4 text-base flex items-center gap-2 mx-auto">
            Create Astrologer Account <ChevronRight size={18} />
          </button>
          <p className="text-text-muted text-sm mt-4">
            Already have an account?{' '}
            <button onClick={() => navigate('/login')} className="text-orange hover:text-orange-light">Sign in</button>
          </p>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-border py-8 px-6">
        <div className="max-w-5xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded-lg bg-orange/20 flex items-center justify-center">
              <Star className="w-3 h-3 text-orange fill-orange" />
            </div>
            <span className="font-semibold text-sm">AstroVaak</span>
          </div>
          <p className="text-text-muted text-sm">© 2026 AstroVaak. All rights reserved.</p>
          <div className="flex gap-4 text-sm text-text-muted">
            <button onClick={() => navigate('/about')} className="hover:text-text-secondary">About</button>
            <button onClick={() => navigate('/contact')} className="hover:text-text-secondary">Contact</button>
          </div>
        </div>
      </footer>
    </div>
  )
}
