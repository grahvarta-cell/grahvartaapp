import React, { useEffect, useState, useCallback } from 'react';
import { ChevronLeft, ChevronRight, Check, X, Edit2 } from 'lucide-react';
import { format } from 'date-fns';
import api from '../services/api';
import PageHeader from '../components/PageHeader';
import { TableShimmer } from '../components/Shimmer';
import toast from 'react-hot-toast';

const fmt = (n) => `₹${new Intl.NumberFormat('en-IN').format(parseFloat(n) || 0)}`;

function RatesModal({ astrologer, onClose, onSaved }) {
  const [chat, setChat]   = useState(astrologer.per_minute_rate_chat);
  const [call, setCall]   = useState(astrologer.per_minute_rate_call);
  const [video, setVideo] = useState(astrologer.per_minute_rate_video);
  const [loading, setLoading] = useState(false);

  const save = async () => {
    setLoading(true);
    try {
      await api.put(`/astrologers/${astrologer.id}/rates`, {
        per_minute_rate_chat: parseFloat(chat),
        per_minute_rate_call: parseFloat(call),
        per_minute_rate_video: parseFloat(video),
      });
      toast.success('Rates updated');
      onSaved();
      onClose();
    } catch {
      toast.error('Failed to update rates');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
      <div className="card w-full max-w-sm">
        <h3 className="font-semibold text-white mb-4">Set Rates — {astrologer.display_name}</h3>
        {[['Chat (₹/min)', chat, setChat], ['Call (₹/min)', call, setCall], ['Video (₹/min)', video, setVideo]].map(([label, val, set]) => (
          <div key={label} className="mb-3">
            <label className="text-xs text-text-secondary mb-1 block">{label}</label>
            <input type="number" className="input" value={val} onChange={(e) => set(e.target.value)} min="1" />
          </div>
        ))}
        <div className="flex gap-2 mt-4">
          <button onClick={onClose} className="btn-ghost flex-1">Cancel</button>
          <button onClick={save} disabled={loading} className="btn-primary flex-1">{loading ? 'Saving…' : 'Save'}</button>
        </div>
      </div>
    </div>
  );
}

export default function AstrologersPage() {
  const [astrologers, setAstrologers] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const [loading, setLoading] = useState(false);
  const [ratesModal, setRatesModal] = useState(null);
  const limit = 20;

  const fetchAstrologers = useCallback(() => {
    setLoading(true);
    api.get('/astrologers', { params: { page, limit, status: statusFilter || undefined } })
      .then((r) => { setAstrologers(r.data.data); setTotal(r.data.total); })
      .finally(() => setLoading(false));
  }, [page, statusFilter]);

  useEffect(() => { fetchAstrologers(); }, [fetchAstrologers]);

  const approve = async (id) => {
    try { await api.post(`/astrologers/${id}/approve`); toast.success('Approved'); fetchAstrologers(); }
    catch { toast.error('Failed'); }
  };

  const reject = async (id) => {
    const reason = prompt('Rejection reason (optional):');
    try { await api.post(`/astrologers/${id}/reject`, { reason }); toast.success('Rejected'); fetchAstrologers(); }
    catch { toast.error('Failed'); }
  };

  const toggleOnline = async (id) => {
    try { await api.post(`/astrologers/${id}/toggle-online`); fetchAstrologers(); }
    catch { toast.error('Failed'); }
  };

  const totalPages = Math.ceil(total / limit);

  const statusBadge = (s) => {
    if (s === 'approved') return 'badge-success';
    if (s === 'rejected') return 'badge-error';
    return 'badge-warning';
  };

  return (
    <div className="p-8">
      {ratesModal && <RatesModal astrologer={ratesModal} onClose={() => setRatesModal(null)} onSaved={fetchAstrologers} />}

      <PageHeader title="Astrologers" subtitle={`${total} total`} />

      <div className="flex gap-3 mb-6">
        {['', 'pending', 'approved', 'rejected'].map((s) => (
          <button
            key={s}
            onClick={() => { setStatusFilter(s); setPage(1); }}
            className={`px-4 py-2 rounded-xl text-sm font-medium transition-colors ${statusFilter === s ? 'bg-orange text-white' : 'bg-surface-light text-text-secondary hover:text-white'}`}
          >
            {s === '' ? 'All' : s.charAt(0).toUpperCase() + s.slice(1)}
          </button>
        ))}
      </div>

      <div className="card p-0 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-text-muted text-xs uppercase">
              <th className="px-4 py-3 text-left">Astrologer</th>
              <th className="px-4 py-3 text-left">Specializations</th>
              <th className="px-4 py-3 text-right">Earnings</th>
              <th className="px-4 py-3 text-right">Consultations</th>
              <th className="px-4 py-3 text-left">Status</th>
              <th className="px-4 py-3 text-left">Online</th>
              <th className="px-4 py-3 text-left">Joined</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <TableShimmer rows={8} cols={8} />
            ) : astrologers.length === 0 ? (
              <tr><td colSpan={8} className="text-center py-12 text-text-muted">No astrologers found</td></tr>
            ) : astrologers.map((a) => (
              <tr key={a.id} className="border-b border-divider hover:bg-surface-light/50">
                <td className="px-4 py-3">
                  <p className="font-medium text-white">{a.display_name}</p>
                  <p className="text-text-muted text-xs">{a.email}</p>
                </td>
                <td className="px-4 py-3 text-text-secondary text-xs">{(a.specializations || []).slice(0, 2).join(', ') || '—'}</td>
                <td className="px-4 py-3 text-right text-text-secondary">{fmt(a.total_earnings)}</td>
                <td className="px-4 py-3 text-right text-text-secondary">{a.total_consultations}</td>
                <td className="px-4 py-3"><span className={statusBadge(a.status)}>{a.status ? a.status.charAt(0).toUpperCase() + a.status.slice(1) : '—'}</span></td>
                <td className="px-4 py-3">
                  <button onClick={() => toggleOnline(a.id)} className={`w-10 h-5 rounded-full transition-colors ${a.is_online ? 'bg-success' : 'bg-border'} relative`}>
                    <span className={`absolute top-0.5 w-4 h-4 rounded-full bg-white transition-all ${a.is_online ? 'left-5' : 'left-0.5'}`} />
                  </button>
                </td>
                <td className="px-4 py-3 text-text-muted text-xs">{format(new Date(a.created_at), 'MMM d, yyyy')}</td>
                <td className="px-4 py-3">
                  <div className="flex items-center justify-end gap-1.5">
                    <button onClick={() => setRatesModal(a)} className="p-1.5 rounded-lg bg-surface-light hover:bg-border transition-colors" title="Set rates">
                      <Edit2 size={14} className="text-text-secondary" />
                    </button>
                    {a.status === 'pending' && (
                      <>
                        <button onClick={() => approve(a.id)} className="p-1.5 rounded-lg bg-success/15 hover:bg-success/25 transition-colors" title="Approve">
                          <Check size={14} className="text-success" />
                        </button>
                        <button onClick={() => reject(a.id)} className="p-1.5 rounded-lg bg-error/15 hover:bg-error/25 transition-colors" title="Reject">
                          <X size={14} className="text-error" />
                        </button>
                      </>
                    )}
                    {a.status === 'rejected' && (
                      <button onClick={() => approve(a.id)} className="p-1.5 rounded-lg bg-success/15 hover:bg-success/25 transition-colors" title="Re-approve">
                        <Check size={14} className="text-success" />
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-border">
            <p className="text-xs text-text-muted">Page {page} of {totalPages}</p>
            <div className="flex gap-2">
              <button disabled={page === 1} onClick={() => setPage(p => p - 1)} className="btn-ghost px-2 py-1.5 disabled:opacity-30"><ChevronLeft size={16} /></button>
              <button disabled={page === totalPages} onClick={() => setPage(p => p + 1)} className="btn-ghost px-2 py-1.5 disabled:opacity-30"><ChevronRight size={16} /></button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
