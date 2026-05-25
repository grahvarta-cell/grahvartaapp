import React, { useEffect, useState, useCallback } from 'react';
import { Check, X, Trash2, ChevronLeft, ChevronRight } from 'lucide-react';
import { format } from 'date-fns';
import api from '../services/api';
import PageHeader from '../components/PageHeader';
import { TableShimmer } from '../components/Shimmer';
import toast from 'react-hot-toast';

const STATUS_FILTERS = ['pending', 'approved', 'rejected', ''];

export default function CommunityPage() {
  const [posts, setPosts] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const [loading, setLoading] = useState(false);
  const limit = 20;

  const fetchPosts = useCallback(() => {
    setLoading(true);
    api.get('/community', { params: { page, limit, status: statusFilter || undefined } })
      .then((r) => { setPosts(r.data.data); setTotal(r.data.total); })
      .finally(() => setLoading(false));
  }, [page, statusFilter]);

  useEffect(() => { fetchPosts(); }, [fetchPosts]);

  const approve = async (id) => {
    try {
      await api.post(`/community/${id}/approve`);
      toast.success('Post approved');
      fetchPosts();
    } catch { toast.error('Failed'); }
  };

  const reject = async (id) => {
    try {
      await api.post(`/community/${id}/reject`);
      toast.success('Post rejected');
      fetchPosts();
    } catch { toast.error('Failed'); }
  };

  const remove = async (post) => {
    if (!window.confirm('Delete this post permanently?')) return;
    try {
      await api.delete(`/community/${post.id}`);
      toast.success('Post deleted');
      fetchPosts();
    } catch { toast.error('Failed'); }
  };

  const statusBadge = (s) => {
    if (s === 'approved') return 'badge-success';
    if (s === 'rejected') return 'badge-error';
    return 'badge-warning';
  };

  const totalPages = Math.ceil(total / limit);

  return (
    <div className="p-8">
      <PageHeader title="Community" subtitle={`${total} posts`} />

      <div className="flex gap-3 mb-6">
        {STATUS_FILTERS.map((s) => (
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
              <th className="px-4 py-3 text-left">Author</th>
              <th className="px-4 py-3 text-left">Content</th>
              <th className="px-4 py-3 text-left">Category</th>
              <th className="px-4 py-3 text-center">Likes</th>
              <th className="px-4 py-3 text-left">Status</th>
              <th className="px-4 py-3 text-left">Posted</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <TableShimmer rows={8} cols={7} />
            ) : posts.length === 0 ? (
              <tr><td colSpan={7} className="text-center py-12 text-text-muted">No posts found</td></tr>
            ) : posts.map((p) => (
              <tr key={p.id} className="border-b border-divider hover:bg-surface-light/50">
                <td className="px-4 py-3">
                  <p className="font-medium text-white capitalize">{p.author_name}</p>
                  <p className="text-text-muted text-xs">{p.author_email}</p>
                </td>
                <td className="px-4 py-3 text-text-secondary max-w-xs">
                  <p className="line-clamp-2 text-xs leading-relaxed">{p.content}</p>
                </td>
                <td className="px-4 py-3 text-text-muted text-xs capitalize">{p.category || '—'}</td>
                <td className="px-4 py-3 text-center text-text-secondary">{p.likes_count || 0}</td>
                <td className="px-4 py-3">
                  <span className={statusBadge(p.status)}>
                    {p.status ? p.status.charAt(0).toUpperCase() + p.status.slice(1) : 'Pending'}
                  </span>
                </td>
                <td className="px-4 py-3 text-text-muted text-xs">
                  {format(new Date(p.created_at), 'MMM d, yyyy HH:mm')}
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center justify-end gap-1.5">
                    {p.status !== 'approved' && (
                      <button onClick={() => approve(p.id)} className="p-1.5 rounded-lg bg-success/15 hover:bg-success/25 transition-colors" title="Approve">
                        <Check size={14} className="text-success" />
                      </button>
                    )}
                    {p.status !== 'rejected' && (
                      <button onClick={() => reject(p.id)} className="p-1.5 rounded-lg bg-error/15 hover:bg-error/25 transition-colors" title="Reject">
                        <X size={14} className="text-error" />
                      </button>
                    )}
                    <button onClick={() => remove(p)} className="p-1.5 rounded-lg bg-error/10 hover:bg-error/20 transition-colors" title="Delete">
                      <Trash2 size={14} className="text-error" />
                    </button>
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
