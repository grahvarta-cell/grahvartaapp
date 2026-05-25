import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Wallet, MessageSquare, FileText } from 'lucide-react';
import { format } from 'date-fns';
import api from '../services/api';
import { ShimmerBlock } from '../components/Shimmer';

const fmt = (n) => `₹${new Intl.NumberFormat('en-IN').format(parseFloat(n) || 0)}`;

export default function UserDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get(`/users/${id}`).then((r) => setData(r.data.data)).finally(() => setLoading(false));
  }, [id]);

  if (loading) return (
    <div className="p-8 max-w-4xl">
      <ShimmerBlock className="h-4 w-28 mb-6" />
      <div className="card mb-6">
        <div className="flex items-start justify-between mb-5">
          <div className="space-y-2">
            <ShimmerBlock className="h-6 w-48" />
            <ShimmerBlock className="h-4 w-64" />
          </div>
          <ShimmerBlock className="h-6 w-16 rounded-full" />
        </div>
        <div className="grid grid-cols-3 gap-4 pt-5 border-t border-border">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="space-y-1.5">
              <ShimmerBlock className="h-3 w-16" />
              <ShimmerBlock className="h-5 w-24" />
            </div>
          ))}
        </div>
      </div>
      <div className="card mb-6">
        <ShimmerBlock className="h-4 w-20 mb-4" />
        <div className="grid grid-cols-4 gap-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="space-y-1.5">
              <ShimmerBlock className="h-3 w-20" />
              <ShimmerBlock className="h-5 w-28" />
            </div>
          ))}
        </div>
      </div>
      <div className="card mb-6">
        <ShimmerBlock className="h-4 w-40 mb-4" />
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="flex justify-between py-3 border-b border-divider">
            <ShimmerBlock className="h-4 w-36" />
            <ShimmerBlock className="h-4 w-20" />
          </div>
        ))}
      </div>
    </div>
  );
  if (!data) return <div className="p-8 text-text-secondary">User not found</div>;

  return (
    <div className="p-8 max-w-4xl">
      <button onClick={() => navigate(-1)} className="flex items-center gap-2 text-text-secondary hover:text-white text-sm mb-6 transition-colors">
        <ArrowLeft size={16} /> Back to Users
      </button>

      {/* Profile */}
      <div className="card mb-6">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-xl font-bold text-white">{data.name}</h1>
            <p className="text-text-secondary text-sm mt-0.5">{data.email}</p>
            {data.phone && <p className="text-text-muted text-xs mt-0.5">{data.phone}</p>}
          </div>
          <span className={data.is_banned ? 'badge-error' : 'badge-success'}>
            {data.is_banned ? 'Banned' : 'Active'}
          </span>
        </div>
        <div className="grid grid-cols-3 gap-4 mt-5 pt-5 border-t border-border">
          <div><p className="text-xs text-text-muted">Sun Sign</p><p className="text-white font-medium capitalize mt-0.5">{data.sun_sign || '—'}</p></div>
          <div><p className="text-xs text-text-muted">Plan</p><p className="text-white font-medium capitalize mt-0.5">{data.subscription_plan}</p></div>
          <div><p className="text-xs text-text-muted">Joined</p><p className="text-white font-medium mt-0.5">{format(new Date(data.created_at), 'MMM d, yyyy')}</p></div>
        </div>
      </div>

      {/* Wallet */}
      {data.wallet && (
        <div className="card mb-6">
          <div className="flex items-center gap-2 mb-4">
            <Wallet size={16} className="text-orange" />
            <h2 className="text-sm font-semibold text-white">Wallet</h2>
          </div>
          <div className="grid grid-cols-4 gap-4">
            {[
              ['Balance', fmt(data.wallet.balance)],
              ['Total Added', fmt(data.wallet.total_added)],
              ['Total Spent', fmt(data.wallet.total_spent)],
              ['Total Refunded', fmt(data.wallet.total_refunded)],
            ].map(([label, val]) => (
              <div key={label}>
                <p className="text-xs text-text-muted">{label}</p>
                <p className="text-white font-semibold mt-0.5">{val}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Consultations */}
      <div className="card mb-6">
        <div className="flex items-center gap-2 mb-4">
          <MessageSquare size={16} className="text-orange" />
          <h2 className="text-sm font-semibold text-white">Recent Consultations</h2>
        </div>
        {data.consultations.length === 0 ? (
          <p className="text-text-muted text-sm">No consultations yet</p>
        ) : (
          <div className="space-y-2">
            {data.consultations.map((c) => (
              <div key={c.id} className="flex items-center justify-between py-2 border-b border-divider last:border-0">
                <div>
                  <p className="text-sm text-white">{c.astrologer_name}</p>
                  <p className="text-xs text-text-muted capitalize">{c.type} · {c.status}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm text-white">{fmt(c.total_amount)}</p>
                  <p className="text-xs text-text-muted">{c.created_at ? format(new Date(c.created_at), 'MMM d, yyyy') : '—'}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Reports */}
      <div className="card">
        <div className="flex items-center gap-2 mb-4">
          <FileText size={16} className="text-orange" />
          <h2 className="text-sm font-semibold text-white">Reports Unlocked</h2>
        </div>
        {data.reports_unlocked.length === 0 ? (
          <p className="text-text-muted text-sm">No reports unlocked</p>
        ) : (
          <div className="space-y-2">
            {data.reports_unlocked.map((r) => (
              <div key={r.id} className="flex items-center justify-between py-2 border-b border-divider last:border-0">
                <p className="text-sm text-white">{r.report_name}</p>
                <p className="text-xs text-text-muted">{format(new Date(r.created_at), 'MMM d, yyyy')}</p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
