import React, { useEffect, useState, useCallback } from 'react';
import { ChevronLeft, ChevronRight, Check, X } from 'lucide-react';
import { format } from 'date-fns';
import api from '../services/api';
import PageHeader from '../components/PageHeader';
import { TableShimmer } from '../components/Shimmer';
import toast from 'react-hot-toast';

const fmt = (n) => `₹${new Intl.NumberFormat('en-IN').format(parseFloat(n) || 0)}`;

function PayoutDetail({ row }) {
  if (!row.payout_method) return <span className="text-text-muted">—</span>;
  if (row.payout_method === 'upi')   return <span>{row.upi_id}</span>;
  if (row.payout_method === 'paytm') return <span>{row.paytm_number}</span>;
  return (
    <span>
      {row.bank_account_number} · {row.bank_ifsc}
      {row.bank_name ? ` · ${row.bank_name}` : ''}
    </span>
  );
}

export default function WithdrawalsPage() {
  const [withdrawals, setWithdrawals] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('pending');
  const [loading, setLoading] = useState(false);
  const limit = 20;

  const fetchData = useCallback(() => {
    setLoading(true);
    api.get('/withdrawals', { params: { page, limit, status: statusFilter || undefined } })
      .then((r) => { setWithdrawals(r.data.data); setTotal(r.data.total); })
      .finally(() => setLoading(false));
  }, [page, statusFilter]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const approve = async (id) => {
    try {
      await api.post(`/withdrawals/${id}/approve`);
      toast.success('Approved — queued for processing');
      fetchData();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed');
    }
  };

  const reject = async (id) => {
    const reason = prompt('Rejection reason:');
    if (reason === null) return;
    try {
      await api.post(`/withdrawals/${id}/reject`, { reason });
      toast.success('Rejected — amount refunded to astrologer');
      fetchData();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed');
    }
  };

  const totalPages = Math.ceil(total / limit);

  const statusBadge = (s) => {
    if (s === 'completed')  return 'badge-success';
    if (s === 'rejected')   return 'badge-error';
    if (s === 'processing') return 'badge-warning';
    return 'badge-gray';
  };

  return (
    <div className="p-8">
      <PageHeader title="Withdrawal Requests" subtitle={`${total} total`} />

      <div className="flex gap-3 mb-6">
        {['pending', 'processing', 'completed', 'rejected', ''].map((s) => (
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
              <th className="px-4 py-3 text-right">Amount</th>
              <th className="px-4 py-3 text-left">Method</th>
              <th className="px-4 py-3 text-left">Payout Details</th>
              <th className="px-4 py-3 text-left">Status</th>
              <th className="px-4 py-3 text-left">Requested</th>
              <th className="px-4 py-3 text-left">Remarks</th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <TableShimmer rows={8} cols={8} />
            ) : withdrawals.length === 0 ? (
              <tr><td colSpan={8} className="text-center py-12 text-text-muted">No withdrawal requests</td></tr>
            ) : withdrawals.map((w) => (
              <tr key={w.id} className="border-b border-divider hover:bg-surface-light/50">
                <td className="px-4 py-3">
                  <p className="font-medium text-white">{w.astrologer_name}</p>
                  <p className="text-text-muted text-xs">{w.astrologer_email}</p>
                </td>
                <td className="px-4 py-3 text-right font-bold text-white">{fmt(w.amount)}</td>
                <td className="px-4 py-3 capitalize text-text-secondary">{w.payout_method || '—'}</td>
                <td className="px-4 py-3 text-text-muted text-xs max-w-[180px] truncate">
                  <PayoutDetail row={w} />
                </td>
                <td className="px-4 py-3">
                  <span className={statusBadge(w.status)}>
                    {w.status.charAt(0).toUpperCase() + w.status.slice(1)}
                  </span>
                </td>
                <td className="px-4 py-3 text-text-muted text-xs">
                  {format(new Date(w.requested_at), 'MMM d, yyyy HH:mm')}
                </td>
                <td className="px-4 py-3 text-text-muted text-xs max-w-[140px] truncate">{w.remarks || '—'}</td>
                <td className="px-4 py-3">
                  {w.status === 'pending' && (
                    <div className="flex items-center gap-1.5">
                      <button onClick={() => approve(w.id)} className="p-1.5 rounded-lg bg-success/15 hover:bg-success/25 transition-colors" title="Approve">
                        <Check size={14} className="text-success" />
                      </button>
                      <button onClick={() => reject(w.id)} className="p-1.5 rounded-lg bg-error/15 hover:bg-error/25 transition-colors" title="Reject">
                        <X size={14} className="text-error" />
                      </button>
                    </div>
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
