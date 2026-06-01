import { useNavigate } from 'react-router-dom'
import { Star, Heart, Target, Eye, ChevronRight, ArrowLeft } from 'lucide-react'

const TEAM = [
  { name: 'Prateek Sharma', role: 'Founder & CEO', initials: 'PS' },
  { name: 'Astrology Team', role: 'Content & Curation', initials: 'AT' },
  { name: 'Tech Team', role: 'Engineering', initials: 'TT' },
]

const VALUES = [
  { icon: Heart, title: 'Empathy First', desc: 'We believe every person deserves compassionate, thoughtful guidance through life\'s challenges.' },
  { icon: Target, title: 'Accuracy Matters', desc: 'We hold our astrologers to the highest standards of knowledge, skill, and ethical practice.' },
  { icon: Eye, title: 'Transparency', desc: 'Clear pricing, honest reviews, and no hidden fees — ever. What you see is what you get.' },
]

export default function AboutPage() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen bg-background text-text-primary">
      {/* Navbar */}
      <nav className="fixed top-0 left-0 right-0 z-50 border-b border-border bg-background/80 backdrop-blur-md">
        <div className="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
          <button onClick={() => navigate('/')} className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl bg-orange/20 flex items-center justify-center">
              <Star className="w-4 h-4 text-orange fill-orange" />
            </div>
            <span className="font-bold text-lg">Grahvarta</span>
          </button>
          <div className="flex items-center gap-6">
            <button onClick={() => navigate('/about')} className="text-orange text-sm font-medium">About</button>
            <button onClick={() => navigate('/contact')} className="text-text-secondary hover:text-text-primary text-sm">Contact</button>
            <button onClick={() => navigate('/login')} className="btn-primary py-2 px-5 w-auto text-sm">Login</button>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="pt-32 pb-16 px-6 text-center relative overflow-hidden">
        <div className="absolute top-20 left-1/2 -translate-x-1/2 w-[500px] h-[300px] bg-orange/10 rounded-full blur-[100px] pointer-events-none" />
        <div className="max-w-3xl mx-auto relative">
          <h1 className="text-4xl md:text-5xl font-bold mb-6">
            Connecting Seekers with{' '}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-orange to-gold">
              True Wisdom
            </span>
          </h1>
          <p className="text-text-secondary text-lg leading-relaxed">
            Grahvarta was born from a simple belief — that ancient astrological wisdom should be
            accessible to everyone, and that talented astrologers deserve a modern platform to
            share their gifts and build sustainable livelihoods.
          </p>
        </div>
      </section>

      {/* Mission */}
      <section className="py-16 px-6 border-y border-border bg-surface">
        <div className="max-w-5xl mx-auto grid md:grid-cols-2 gap-12 items-center">
          <div>
            <h2 className="text-3xl font-bold mb-4">Our Mission</h2>
            <p className="text-text-secondary leading-relaxed mb-4">
              We're on a mission to democratize access to astrological guidance. Whether you're
              facing career decisions, relationship challenges, or simply seeking clarity — our
              platform connects you with verified, experienced astrologers in minutes.
            </p>
            <p className="text-text-secondary leading-relaxed">
              For astrologers, we provide the tools, technology, and audience to build a
              thriving practice without the overhead of running their own business.
            </p>
          </div>
          <div className="grid grid-cols-2 gap-4">
            {[
              { label: 'Founded', value: '2024' },
              { label: 'Astrologers', value: '500+' },
              { label: 'Users Helped', value: '10,000+' },
              { label: 'Cities', value: '100+' },
            ].map(s => (
              <div key={s.label} className="card text-center">
                <p className="text-2xl font-bold text-orange">{s.value}</p>
                <p className="text-text-secondary text-sm mt-1">{s.label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Values */}
      <section className="py-16 px-6">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-3xl font-bold text-center mb-12">Our Values</h2>
          <div className="grid md:grid-cols-3 gap-6">
            {VALUES.map(v => (
              <div key={v.title} className="card text-center">
                <div className="w-12 h-12 rounded-2xl bg-orange/20 flex items-center justify-center mx-auto mb-4">
                  <v.icon size={22} className="text-orange" />
                </div>
                <h3 className="font-semibold text-lg mb-2">{v.title}</h3>
                <p className="text-text-secondary text-sm leading-relaxed">{v.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Team */}
      <section className="py-16 px-6 border-t border-border bg-surface">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-3xl font-bold text-center mb-12">The Team</h2>
          <div className="flex flex-wrap justify-center gap-6">
            {TEAM.map(t => (
              <div key={t.name} className="card text-center w-48">
                <div className="w-16 h-16 rounded-full bg-orange/20 flex items-center justify-center mx-auto mb-4 text-orange font-bold text-xl">
                  {t.initials}
                </div>
                <p className="font-semibold">{t.name}</p>
                <p className="text-text-muted text-sm mt-1">{t.role}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-16 px-6 text-center border-t border-border">
        <h2 className="text-2xl font-bold mb-4">Join Our Growing Community</h2>
        <p className="text-text-secondary mb-8">Be part of India's most trusted astrology platform.</p>
      </section>

      {/* Footer */}
      <footer className="border-t border-border py-8 px-6">
        <div className="max-w-5xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded-lg bg-orange/20 flex items-center justify-center">
              <Star className="w-3 h-3 text-orange fill-orange" />
            </div>
            <span className="font-semibold text-sm">Grahvarta</span>
          </div>
          <p className="text-text-muted text-sm">© 2026 Grahvarta. All rights reserved.</p>
          <div className="flex gap-4 text-sm text-text-muted">
            <button onClick={() => navigate('/about')} className="hover:text-text-secondary">About</button>
            <button onClick={() => navigate('/contact')} className="hover:text-text-secondary">Contact</button>
          </div>
        </div>
      </footer>
    </div>
  )
}
