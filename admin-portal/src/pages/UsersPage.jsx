import React, { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, ChevronLeft, ChevronRight } from 'lucide-react';
import { format } from 'date-fns';
import api from '../services/api';
import PageHeader from '../components/PageHeader';
import { TableShimmer } from '../components/Shimmer';
import toast from 'react-hot-toast';

const fmt = (n) => `₹${new Intl.NumberFormat('en-IN').format(n)}`;

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const limit = 20;

  const fetchUsers = useCallback(() => {
    setLoading(true);
    const params = { page, limit, search: search || undefined, is_banned: filter || undefined };
    api.get('/users', { params })
      .then((r) => { setUsers(r.data.data); setTotal(r.data.total); })
      .finally(() => setLoading(false));
  }, [page, search, filter]);

  useEffect(() => { fetchUsers(); }, [fetchUsers]);

  const toggleBan = async (user) => {
    const action = user.is_banned ? 'unban' : 'ban';
    try {
      await api.post(`/users/${user.id}/${action}`);
      toast.success(`User ${action}ned`);
      fetchUsers();
    } catch {
      toast.error('Action failed');
    }
  };

  const totalPages = Math.ceil(total / limit);

  return (
    <div className="p-8">
      <PageHeader title="Users" subtitle={`${total} total users`} />

      <div className="flex gap-3 mb-6">
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
          <input
            className="input pl-9"
            placeholder="Search by name or email…"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
          />
        </div>
        <select
          className="input w-40"
          value={filter}
          onChange={(e) => { setFilter(e.target.value); setPage(1); }}
        >
          <option value="">All users</option>
          <option value="false">Active</option>
          <option value="true">Banned</option>
        </select>
      </div>

      <div className="card p-0 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-text-muted text-xs uppercase">
              <th className="px-4 py-3 text-left">User</th>
              <th className="px-4 py-3 text-left">Sun Sign</th>
              <th className="px-4 py-3 text-left">Plan</th>
              <th className="px-4 py-3 text-right">Wallet</th>
              <th className="px-4 py-3 text-right">Consults</th>
              <th className="px-4 py-3 text-left">Joined</th>
              <th className="px-4 py-3 text-left">Status</th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <TableShimmer rows={8} cols={8} />
            ) : users.length === 0 ? (
              <tr><td colSpan={8} className="text-center py-12 text-text-muted">No users found</td></tr>
            ) : users.map((u) => (
              <tr key={u.id} className="border-b border-divider hover:bg-surface-light/50 cursor-pointer" onClick={() => navigate(`/users/${u.id}`)}>
                <td className="px-4 py-3">
                  <p className="font-medium text-white capitalize">{u.name}</p>
                  <p className="text-text-muted text-xs">{u.email}</p>
                </td>
                <td className="px-4 py-3 text-text-secondary capitalize">{u.sun_sign || '—'}</td>
                <td className="px-4 py-3">
                  <span className={u.subscription_plan === 'free' ? 'badge-gray' : 'badge-success'}>
                    {u.subscription_plan ? u.subscription_plan.charAt(0).toUpperCase() + u.subscription_plan.slice(1) : '—'}
                  </span>
                </td>
                <td className="px-4 py-3 text-right text-text-secondary">{fmt(u.wallet_balance)}</td>
                <td className="px-4 py-3 text-right text-text-secondary">{u.consultation_count}</td>
                <td className="px-4 py-3 text-text-muted text-xs">{format(new Date(u.created_at), 'MMM d, yyyy')}</td>
                <td className="px-4 py-3">
                  <span className={u.is_banned ? 'badge-error' : 'badge-success'}>
                    {u.is_banned ? 'Banned' : 'Active'}
                  </span>
                </td>
                <td className="px-4 py-3" onClick={(e) => e.stopPropagation()}>
                  <button
                    onClick={() => toggleBan(u)}
                    className={`text-xs px-3 py-1 rounded-lg font-medium transition-colors ${
                      u.is_banned
                        ? 'bg-success/15 text-success hover:bg-success/25'
                        : 'bg-error/15 text-error hover:bg-error/25'
                    }`}
                  >
                    {u.is_banned ? 'Unban' : 'Ban'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-border">
            <p className="text-xs text-text-muted">Page {page} of {totalPages}</p>
            <div className="flex gap-2">
              <button disabled={page === 1} onClick={() => setPage(p => p - 1)} className="btn-ghost px-2 py-1.5 disabled:opacity-30">
                <ChevronLeft size={16} />
              </button>
              <button disabled={page === totalPages} onClick={() => setPage(p => p + 1)} className="btn-ghost px-2 py-1.5 disabled:opacity-30">
                <ChevronRight size={16} />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
