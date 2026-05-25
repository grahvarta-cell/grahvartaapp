import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Star, Mail, MessageCircle, Phone, Send, ChevronRight } from 'lucide-react'
import toast from 'react-hot-toast'

const FAQS = [
  { q: 'How do I join as an astrologer?', a: 'Click "Join as Astrologer", create your account, then complete your astrologer profile with your specializations and rates. You can start accepting consultations immediately.' },
  { q: 'When do I get paid?', a: 'Earnings are credited to your wallet in real-time after each consultation. You can request a withdrawal anytime.' },
  { q: 'Is there a fee to join?', a: 'No. Joining Grahvarta is completely free. We only take a small platform fee from each consultation.' },
  { q: 'Can I set my own rates?', a: 'Yes. You set your own per-minute rates for chat, call, and video consultations independently.' },
  { q: 'How are users matched to me?', a: 'Users browse astrologers by specialization, language, and rating. They can initiate a consultation directly from your profile.' },
]

export default function ContactPage() {
  const navigate = useNavigate()
  const [form, setForm] = useState({ name: '', email: '', subject: '', message: '' })
  const [openFaq, setOpenFaq] = useState(null)

  function handleSubmit(e) {
    e.preventDefault()
    toast.success('Message sent! We\'ll get back to you within 24 hours.')
    setForm({ name: '', email: '', subject: '', message: '' })
  }

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
            <button onClick={() => navigate('/about')} className="text-text-secondary hover:text-text-primary text-sm">About</button>
            <button onClick={() => navigate('/contact')} className="text-orange text-sm font-medium">Contact</button>
            <button onClick={() => navigate('/login')} className="btn-primary py-2 px-5 w-auto text-sm">Login</button>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="pt-32 pb-12 px-6 text-center">
        <div className="max-w-2xl mx-auto">
          <h1 className="text-4xl md:text-5xl font-bold mb-4">Get in Touch</h1>
          <p className="text-text-secondary text-lg">
            Have questions? We'd love to hear from you. Send us a message and we'll respond within 24 hours.
          </p>
        </div>
      </section>

      {/* Contact Info + Form */}
      <section className="py-12 px-6">
        <div className="max-w-5xl mx-auto grid md:grid-cols-2 gap-10">
          {/* Contact info */}
          <div className="space-y-6">
            <h2 className="text-2xl font-bold">Contact Information</h2>
            <p className="text-text-secondary">
              Reach out to us for support, partnership inquiries, or any questions about the platform.
            </p>

            <div className="space-y-4">
              <div className="flex items-center gap-4 p-4 bg-surface border border-border rounded-xl">
                <div className="w-10 h-10 rounded-xl bg-orange/20 flex items-center justify-center shrink-0">
                  <Mail size={18} className="text-orange" />
                </div>
                <div>
                  <p className="text-sm text-text-secondary">Email</p>
                  <p className="font-medium">support@grahvarta.com</p>
                </div>
              </div>

              <div className="flex items-center gap-4 p-4 bg-surface border border-border rounded-xl">
                <div className="w-10 h-10 rounded-xl bg-gold/20 flex items-center justify-center shrink-0">
                  <MessageCircle size={18} className="text-gold" />
                </div>
                <div>
                  <p className="text-sm text-text-secondary">WhatsApp Support</p>
                  <p className="font-medium">+91 98765 43210</p>
                </div>
              </div>

              <div className="flex items-center gap-4 p-4 bg-surface border border-border rounded-xl">
                <div className="w-10 h-10 rounded-xl bg-success/20 flex items-center justify-center shrink-0">
                  <Phone size={18} className="text-success" />
                </div>
                <div>
                  <p className="text-sm text-text-secondary">Business Hours</p>
                  <p className="font-medium">Mon–Sat, 10am–7pm IST</p>
                </div>
              </div>
            </div>
          </div>

          {/* Form */}
          <div className="card">
            <h3 className="font-semibold text-lg mb-5">Send a Message</h3>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-text-secondary mb-1.5">Name</label>
                  <input className="input-field" placeholder="Your name" value={form.name}
                    onChange={e => setForm(p => ({ ...p, name: e.target.value }))} required />
                </div>
                <div>
                  <label className="block text-sm text-text-secondary mb-1.5">Email</label>
                  <input type="email" className="input-field" placeholder="you@example.com" value={form.email}
                    onChange={e => setForm(p => ({ ...p, email: e.target.value }))} required />
                </div>
              </div>
              <div>
                <label className="block text-sm text-text-secondary mb-1.5">Subject</label>
                <input className="input-field" placeholder="What is this about?" value={form.subject}
                  onChange={e => setForm(p => ({ ...p, subject: e.target.value }))} required />
              </div>
              <div>
                <label className="block text-sm text-text-secondary mb-1.5">Message</label>
                <textarea className="input-field min-h-[120px] resize-none" placeholder="Your message..."
                  value={form.message} onChange={e => setForm(p => ({ ...p, message: e.target.value }))} required />
              </div>
              <button type="submit" className="btn-primary flex items-center justify-center gap-2">
                <Send size={16} /> Send Message
              </button>
            </form>
          </div>
        </div>
      </section>

      {/* FAQs */}
      <section className="py-16 px-6 border-t border-border bg-surface">
        <div className="max-w-3xl mx-auto">
          <h2 className="text-3xl font-bold text-center mb-10">Frequently Asked Questions</h2>
          <div className="space-y-3">
            {FAQS.map((faq, i) => (
              <div key={i} className="card cursor-pointer" onClick={() => setOpenFaq(openFaq === i ? null : i)}>
                <div className="flex items-center justify-between gap-4">
                  <p className="font-medium">{faq.q}</p>
                  <ChevronRight size={18} className={`text-text-muted shrink-0 transition-transform ${openFaq === i ? 'rotate-90' : ''}`} />
                </div>
                {openFaq === i && (
                  <p className="text-text-secondary text-sm mt-3 leading-relaxed">{faq.a}</p>
                )}
              </div>
            ))}
          </div>
        </div>
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
