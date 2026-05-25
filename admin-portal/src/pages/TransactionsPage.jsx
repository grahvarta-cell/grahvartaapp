import React, { useEffect, useState, useCallback } from 'react';
import { ChevronLeft, ChevronRight, Plus, Minus, RotateCcw } from 'lucide-react';
import { format } from 'date-fns';
import api from '../services/api';
import PageHeader from '../components/PageHeader';
import { TableShimmer } from '../components/Shimmer';
import toast from 'react-hot-toast';

const fmt = (n) => `₹${new Intl.NumberFormat('en-IN').format(parseFloat(n) || 0)}`;

function ManualModal({ type, onClose, onDone }) {
  const [userId, setUserId] = useState('');
  const [amount, setAmount] = useState('');
  const [description, setDescription] = useState('');
  const [loading, setLoading] = useState(false);

  const submit = async () => {
    if (!userId || !amount) return toast.error('User ID and amount required');
    setLoading(true);
    try {
      const endpoint = type === 'credit' ? '/wallet/credit' : '/wallet/debit';
      await api.post(endpoint, { user_id: userId, amount: parseFloat(amount), description });
      toast.success(`${type === 'credit' ? 'Credit' : 'Debit'} successful`);
      onDone();
      onClose();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
      <div className="card w-full max-w-sm">
        <h3 className="font-semibold text-white mb-4">Manual {type === 'credit' ? 'Credit' : 'Debit'}</h3>
        <div className="space-y-3">
          <div>
            <label className="text-xs text-text-secondary mb-1 block">User ID</label>
            <input className="input" placeholder="UUID" value={userId} onChange={(e) => setUserId(e.target.value)} />
          </div>
          <div>
            <label className="text-xs text-text-secondary mb-1 block">Amount (₹)</label>
            <input className="input" type="number" min="1" value={amount} onChange={(e) => setAmount(e.target.value)} />
          </div>
          <div>
            <label className="text-xs text-text-secondary mb-1 block">Description</label>
            <input className="input" placeholder="Reason…" value={description} onChange={(e) => setDescription(e.target.value)} />
          </div>
        </div>
        <div className="flex gap-2 mt-4">
          <button onClick={onClose} className="btn-ghost flex-1">Cancel</button>
          <button onClick={submit} disabled={loading} className="btn-primary flex-1">{loading ? 'Processing…' : 'Confirm'}</button>
        </div>
      </div>
    </div>
  );
}

export default function TransactionsPage() {
  const [transactions, setTransactions] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [typeFilter, setTypeFilter] = useState('');
  const [loading, setLoading] = useState(false);
  const [modal, setModal] = useState(null);
  const limit = 20;

  const fetchTx = useCallback(() => {
    setLoading(true);
    api.get('/transactions', { params: { page, limit, type: typeFilter || undefined } })
      .then((r) => { setTransactions(r.data.data); setTotal(r.data.total); })
      .finally(() => setLoading(false));
  }, [page, typeFilter]);

  useEffect(() => { fetchTx(); }, [fetchTx]);

  const refund = async (id) => {
    const reason = prompt('Refund reason:');
    if (reason === null) return;
    try {
      await api.post(`/transactions/${id}/refund`, { reason });
      toast.success('Refunded');
      fetchTx();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed');
    }
  };

  const totalPages = Math.ceil(total / limit);

  const typeBadge = (t) => {
    if (t === 'credit') return 'badge-success';
    if (t === 'debit') return 'badge-error';
    if (t === 'refund') return 'badge-warning';
    return 'badge-gray';
  };

  return (
    <div className="p-8">
      {modal && <ManualModal type={modal} onClose={() => setModal(null)} onDone={fetchTx} />}

      <PageHeader
        title="Transactions"
        subtitle={`${total} total`}
        action={
          <div className="flex gap-2">
            <button onClick={() => setModal('credit')} className="btn-primary flex items-center gap-2">
              <Plus size={14} /> Credit
            </button>
            <button onClick={() => setModal('debit')} className="btn-ghost flex items-center gap-2">
              <Minus size={14} /> Debit
            </button>
          </div>
        }
      />

      <div className="flex gap-3 mb-6">
        {['', 'credit', 'debit', 'refund'].map((t) => (
          <button
            key={t}
            onClick={() => { setTypeFilter(t); setPage(1); }}
            className={`px-4 py-2 rounded-xl text-sm font-medium transition-colors ${typeFilter === t ? 'bg-orange text-white' : 'bg-surface-light text-text-secondary hover:text-white'}`}
          >
            {t === '' ? 'All' : t.charAt(0).toUpperCase() + t.slice(1)}
          </button>
        ))}
      </div>

      <div className="card p-0 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-text-muted text-xs uppercase">
              <th className="px-4 py-3 text-left">User</th>
              <th className="px-4 py-3 text-left">Type</th>
              <th className="px-4 py-3 text-right">Amount</th>
              <th className="px-4 py-3 text-left">Description</th>
              <th className="px-4 py-3 text-left">Gateway</th>
              <th className="px-4 py-3 text-left">Status</th>
              <th className="px-4 py-3 text-left">Date</th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <TableShimmer rows={8} cols={8} />
            ) : transactions.length === 0 ? (
              <tr><td colSpan={8} className="text-center py-12 text-text-muted">No transactions</td></tr>
            ) : transactions.map((t) => (
              <tr key={t.id} className="border-b border-divider hover:bg-surface-light/50">
                <td className="px-4 py-3">
                  <p className="text-white font-medium">{t.user_name}</p>
                  <p className="text-text-muted text-xs">{t.user_email}</p>
                </td>
                <td className="px-4 py-3"><span className={typeBadge(t.type)}>{t.type.charAt(0).toUpperCase() + t.type.slice(1)}</span></td>
                <td className="px-4 py-3 text-right font-semibold text-white">{fmt(t.amount)}</td>
                <td className="px-4 py-3 text-text-secondary text-xs max-w-xs truncate">{t.description || '—'}</td>
                <td className="px-4 py-3 text-text-muted text-xs capitalize">{t.payment_gateway || '—'}</td>
                <td className="px-4 py-3">
                  <span className={t.status === 'success' ? 'badge-success' : t.status === 'refunded' ? 'badge-warning' : 'badge-error'}>
                    {t.status.charAt(0).toUpperCase() + t.status.slice(1)}
                  </span>
                </td>
                <td className="px-4 py-3 text-text-muted text-xs">{format(new Date(t.created_at), 'MMM d, HH:mm')}</td>
                <td className="px-4 py-3">
                  {t.type === 'debit' && t.status !== 'refunded' && (
                    <button onClick={() => refund(t.id)} className="p-1.5 rounded-lg bg-surface-light hover:bg-border transition-colors" title="Refund">
                      <RotateCcw size={14} className="text-text-secondary" />
                    </button>
                  )}
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
