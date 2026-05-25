import { useEffect, useState } from 'react'
import { Wallet, Building2, Smartphone, ArrowRight, Clock, CheckCircle, XCircle, AlertCircle } from 'lucide-react'
import api from '../../services/api'

const STATUS_STYLE = {
  pending:    { cls: 'bg-orange/20 text-orange',  icon: Clock,        label: 'Pending' },
  processing: { cls: 'bg-blue-500/20 text-blue-400', icon: Clock,     label: 'Processing' },
  completed:  { cls: 'bg-success/20 text-success', icon: CheckCircle, label: 'Completed' },
  rejected:   { cls: 'bg-error/20 text-error',    icon: XCircle,      label: 'Rejected' },
  on_hold:    { cls: 'bg-yellow-500/20 text-yellow-400', icon: AlertCircle, label: 'On Hold' },
}

export default function WithdrawalPage() {
  const [wallet, setWallet]           = useState(null)
  const [payoutDetails, setPayoutDetails] = useState(null)
  const [history, setHistory]         = useState([])
  const [tab, setTab]                 = useState('withdraw') // 'withdraw' | 'details' | 'history'
  const [method, setMethod]           = useState('upi')
  const [form, setForm]               = useState({ upi_id: '', paytm_number: '', bank_account_number: '', bank_ifsc: '', bank_account_name: '', bank_name: '' })
  const [amount, setAmount]           = useState('')
  const [loading, setLoading]         = useState(false)
  const [msg, setMsg]                 = useState(null)

  useEffect(() => {
    Promise.all([
      api.get('/astrologers/me/wallet'),
      api.get('/withdrawal/payout-details'),
      api.get('/withdrawal/history'),
    ]).then(([w, p, h]) => {
      setWallet(w.data.data?.wallet)
      setPayoutDetails(p.data.data)
      if (p.data.data) {
        setMethod(p.data.data.method)
        setForm({
          upi_id: p.data.data.upi_id || '',
          paytm_number: p.data.data.paytm_number || '',
          bank_account_number: p.data.data.bank_account_number || '',
          bank_ifsc: p.data.data.bank_ifsc || '',
          bank_account_name: p.data.data.bank_account_name || '',
          bank_name: p.data.data.bank_name || '',
        })
      }
      setHistory(h.data.data || [])
    }).catch(() => {})
  }, [])

  async function saveDetails() {
    setLoading(true); setMsg(null)
    try {
      await api.post('/withdrawal/payout-details', { method, ...form })
      setMsg({ type: 'success', text: 'Payout details saved successfully' })
      const p = await api.get('/withdrawal/payout-details')
      setPayoutDetails(p.data.data)
    } catch (e) {
      setMsg({ type: 'error', text: e.response?.data?.message || 'Failed to save details' })
    }
    setLoading(false)
  }

  async function requestWithdrawal() {
    if (!amount || isNaN(amount)) return
    setLoading(true); setMsg(null)
    try {
      const res = await api.post('/withdrawal/request', { amount: parseFloat(amount) })
      setMsg({ type: 'success', text: res.data.message })
      setAmount('')
      const [w, h] = await Promise.all([api.get('/astrologers/me/wallet'), api.get('/withdrawal/history')])
      setWallet(w.data.data?.wallet)
      setHistory(h.data.data || [])
    } catch (e) {
      setMsg({ type: 'error', text: e.response?.data?.message || 'Withdrawal failed' })
    }
    setLoading(false)
  }

  const available = (wallet?.balance || 0)

  return (
    <div className="space-y-6 max-w-2xl">
      <h1 className="text-2xl font-bold">Withdraw Earnings</h1>

      {/* Balance card */}
      <div className="rounded-2xl bg-gradient-to-br from-orange/30 via-orange/10 to-surface border border-orange/30 p-6">
        <p className="text-text-secondary text-sm mb-1">Available to Withdraw</p>
        <p className="text-4xl font-bold text-text-primary">₹{Number(available).toFixed(2)}</p>
        <p className="text-xs text-text-muted mt-2">Minimum withdrawal: ₹10 · Once per week · 48h settlement</p>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 bg-surface rounded-xl p-1">
        {[['withdraw', 'Withdraw'], ['details', 'Payout Details'], ['history', 'History']].map(([key, label]) => (
          <button key={key} onClick={() => { setTab(key); setMsg(null) }}
            className={`flex-1 py-2 rounded-lg text-sm font-medium transition-colors ${tab === key ? 'bg-orange text-white' : 'text-text-secondary hover:text-text-primary'}`}>
            {label}
          </button>
        ))}
      </div>

      {msg && (
        <div className={`p-4 rounded-xl text-sm ${msg.type === 'success' ? 'bg-success/15 text-success border border-success/30' : 'bg-error/15 text-error border border-error/30'}`}>
          {msg.text}
        </div>
      )}

      {/* ── Withdraw Tab ── */}
      {tab === 'withdraw' && (
        <div className="card space-y-4">
          {!payoutDetails ? (
            <div className="text-center py-6">
              <p className="text-text-secondary mb-3">Add your payout details first</p>
              <button onClick={() => setTab('details')} className="btn-primary">Add Payout Details</button>
            </div>
          ) : (
            <>
              <div className="flex items-center gap-3 p-3 bg-surface-light rounded-xl">
                {payoutDetails.method === 'upi' && <Smartphone size={18} className="text-orange" />}
                {payoutDetails.method === 'bank' && <Building2 size={18} className="text-orange" />}
                {payoutDetails.method === 'paytm' && <Smartphone size={18} className="text-orange" />}
                <div>
                  <p className="text-sm font-medium capitalize">{payoutDetails.method}</p>
                  <p className="text-xs text-text-muted">
                    {payoutDetails.method === 'upi' && payoutDetails.upi_id}
                    {payoutDetails.method === 'paytm' && payoutDetails.paytm_number}
                    {payoutDetails.method === 'bank' && `****${payoutDetails.bank_account_number?.slice(-4)} · ${payoutDetails.bank_ifsc}`}
                  </p>
                </div>
                <button onClick={() => setTab('details')} className="ml-auto text-xs text-orange hover:underline">Change</button>
              </div>

              <div>
                <label className="text-sm text-text-secondary mb-1 block">Amount (₹)</label>
                <input
                  type="number"
                  className="input-field w-full"
                  placeholder="Min ₹10"
                  value={amount}
                  onChange={e => setAmount(e.target.value)}
                  min={10}
                  max={available}
                />
                <p className="text-xs text-text-muted mt-1">Available: ₹{Number(available).toFixed(2)}</p>
              </div>

              <div className="bg-surface-light rounded-xl p-3 text-xs text-text-muted space-y-1">
                <p>⏳ Amount will be held for 48 hours before processing</p>
                <p>📅 Withdrawals allowed once per week</p>
                <p>✅ Funds credited within 1–3 business days after processing</p>
              </div>

              <button onClick={requestWithdrawal} disabled={loading || !amount || parseFloat(amount) < 10 || parseFloat(amount) > available}
                className="btn-primary w-full flex items-center justify-center gap-2 disabled:opacity-40">
                {loading ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> : <ArrowRight size={16} />}
                Request Withdrawal
              </button>

            </>
          )}
        </div>
      )}

      {/* ── Payout Details Tab ── */}
      {tab === 'details' && (
        <div className="card space-y-4">
          <div className="flex gap-2">
            {[['upi', '📲 UPI'], ['bank', '🏦 Bank'], ['paytm', '💙 Paytm']].map(([m, label]) => (
              <button key={m} onClick={() => setMethod(m)}
                className={`flex-1 py-2 rounded-xl text-sm border transition-colors ${method === m ? 'border-orange bg-orange/10 text-orange font-medium' : 'border-border text-text-secondary hover:border-orange/40'}`}>
                {label}
              </button>
            ))}
          </div>

          {method === 'upi' && (
            <div>
              <label className="text-sm text-text-secondary mb-1 block">UPI ID</label>
              <input className="input-field w-full" placeholder="yourname@upi" value={form.upi_id}
                onChange={e => setForm(f => ({ ...f, upi_id: e.target.value }))} />
            </div>
          )}

          {method === 'paytm' && (
            <div>
              <label className="text-sm text-text-secondary mb-1 block">Paytm Mobile Number</label>
              <input className="input-field w-full" placeholder="10-digit number" value={form.paytm_number}
                onChange={e => setForm(f => ({ ...f, paytm_number: e.target.value }))} />
            </div>
          )}

          {method === 'bank' && (
            <div className="space-y-3">
              <div>
                <label className="text-sm text-text-secondary mb-1 block">Account Holder Name</label>
                <input className="input-field w-full" placeholder="Full name as per bank" value={form.bank_account_name}
                  onChange={e => setForm(f => ({ ...f, bank_account_name: e.target.value }))} />
              </div>
              <div>
                <label className="text-sm text-text-secondary mb-1 block">Account Number</label>
                <input className="input-field w-full" placeholder="Account number" value={form.bank_account_number}
                  onChange={e => setForm(f => ({ ...f, bank_account_number: e.target.value }))} />
              </div>
              <div>
                <label className="text-sm text-text-secondary mb-1 block">IFSC Code</label>
                <input className="input-field w-full" placeholder="IFSC" value={form.bank_ifsc}
                  onChange={e => setForm(f => ({ ...f, bank_ifsc: e.target.value.toUpperCase() }))} />
              </div>
              <div>
                <label className="text-sm text-text-secondary mb-1 block">Bank Name</label>
                <input className="input-field w-full" placeholder="e.g. SBI, HDFC" value={form.bank_name}
                  onChange={e => setForm(f => ({ ...f, bank_name: e.target.value }))} />
              </div>
            </div>
          )}

          <button onClick={saveDetails} disabled={loading}
            className="btn-primary w-full flex items-center justify-center gap-2 disabled:opacity-40">
            {loading ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> : null}
            Save Payout Details
          </button>
        </div>
      )}

      {/* ── History Tab ── */}
      {tab === 'history' && (
        <div className="card">
          {history.length === 0 ? (
            <p className="text-text-muted text-sm text-center py-8">No withdrawal requests yet</p>
          ) : (
            <div className="divide-y divide-divider">
              {history.map(w => {
                const s = STATUS_STYLE[w.status] || STATUS_STYLE.pending
                const Icon = s.icon
                return (
                  <div key={w.id} className="py-3 flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium">₹{Number(w.amount).toFixed(2)} · <span className="capitalize">{w.method}</span></p>
                      <p className="text-xs text-text-muted">{new Date(w.requested_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}</p>
                      {w.remarks && <p className="text-xs text-error mt-0.5">{w.remarks}</p>}
                      {w.status === 'pending' && (
                        <p className="text-xs text-text-muted mt-0.5">
                          Processes after {new Date(w.process_after).toLocaleString('en-IN', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}
                        </p>
                      )}
                    </div>
                    <span className={`flex items-center gap-1 text-xs px-2 py-1 rounded-full ${s.cls}`}>
                      <Icon size={12} /> {s.label}
                    </span>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      )}
    </div>
  )
}
