import React, { useEffect, useState, useCallback } from 'react';
import { ChevronLeft, ChevronRight, X, Phone, Mail, Smartphone, Globe, Calendar, Users } from 'lucide-react';
import { format } from 'date-fns';
import api from '../services/api';
import PageHeader from '../components/PageHeader';
import { TableShimmer } from '../components/Shimmer';
import toast from 'react-hot-toast';

const ALL_STATUSES = ['pending', 'shortlisted', 'round1', 'round2', 'activated', 'rejected'];
const STATUS_TABS = [...ALL_STATUSES, ''];

const STATUS_LABELS = {
  pending:     'Pending',
  shortlisted: 'Shortlisted',
  round1:      'Round 1',
  round2:      'Round 2',
  activated:   'Activated',
  rejected:    'Rejected',
};

const STATUS_COLORS = {
  pending:     'badge-gray',
  shortlisted: 'badge-warning',
  round1:      'bg-blue-500/15 text-blue-400 px-2 py-0.5 rounded-full text-xs font-medium',
  round2:      'bg-purple-500/15 text-purple-400 px-2 py-0.5 rounded-full text-xs font-medium',
  activated:   'badge-success',
  rejected:    'badge-error',
};

function statusBadge(s) { return STATUS_COLORS[s] || 'badge-gray'; }

function DetailPanel({ app, onClose, onUpdated }) {
  const [notes, setNotes] = useState(app.admin_notes || '');
  const [newStatus, setNewStatus] = useState(app.status);
  const [saving, setSaving] = useState(false);

  const save = async () => {
    setSaving(true);
    try {
      await api.patch(`/hirings/${app.id}`, { status: newStatus, admin_notes: notes });
      toast.success(`Status updated to ${STATUS_LABELS[newStatus]}`);
      onUpdated();
      onClose();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed');
    } finally {
      setSaving(false);
    }
  };

  const langs = Array.isArray(app.languages) ? app.languages : [];
  const skills = Array.isArray(app.skills) ? app.skills : [];

  return (
    <div className="fixed inset-0 z-50 flex">
      <div className="flex-1 bg-black/50" onClick={onClose} />
      <div className="w-[500px] bg-surface border-l border-border flex flex-col overflow-hidden">
        <div className="flex items-center justify-between px-6 py-4 border-b border-border shrink-0">
          <div>
            <h2 className="font-semibold text-white text-lg">Application Details</h2>
            {app.token_no && <p className="text-xs text-text-muted mt-0.5">Token: <span className="text-orange font-mono">{app.token_no}</span></p>}
          </div>
          <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-surface-light text-text-muted hover:text-white transition-colors">
            <X size={18} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto px-6 py-5 space-y-5">
          {/* Photo + name */}
          <div className="flex items-center gap-4">
            {app.profile_picture_url ? (
              <img src={`https://api.grahvarta.com${app.profile_picture_url}`} alt={app.name} className="w-16 h-16 rounded-full object-cover border border-border" />
            ) : (
              <div className="w-16 h-16 rounded-full bg-surface-light flex items-center justify-center text-2xl font-bold text-orange">
                {app.name?.[0]?.toUpperCase() || '?'}
              </div>
            )}
            <div>
              <p className="text-white font-semibold text-lg">{app.name}</p>
              <span className={statusBadge(app.status)}>{STATUS_LABELS[app.status] || app.status}</span>
            </div>
          </div>

          {/* Contact */}
          <div className="card p-4 space-y-2">
            <p className="text-xs text-text-muted uppercase font-semibold tracking-wider mb-3">Contact</p>
            <Row icon={<Phone size={14} />} label="Phone" value={app.phone} />
            <Row icon={<Mail size={14} />} label="Email" value={app.email || '—'} />
            <Row icon={<Smartphone size={14} />} label="Phone type" value={app.phone_type || '—'} capitalize />
          </div>

          {/* Personal */}
          <div className="card p-4 space-y-2">
            <p className="text-xs text-text-muted uppercase font-semibold tracking-wider mb-3">Personal</p>
            <Row icon={<Calendar size={14} />} label="DOB" value={app.dob ? format(new Date(app.dob), 'dd MMM yyyy') : '—'} />
            <Row icon={<Users size={14} />} label="Gender" value={app.gender || '—'} capitalize />
            <Row icon={<Globe size={14} />} label="Works online" value={app.works_online ? 'Yes' : 'No'} />
          </div>

          {/* Languages */}
          {langs.length > 0 && (
            <div className="card p-4">
              <p className="text-xs text-text-muted uppercase font-semibold tracking-wider mb-3">Languages</p>
              <div className="flex flex-wrap gap-1.5">
                {langs.map((l) => <span key={l} className="px-2.5 py-0.5 bg-surface-light rounded-full text-xs text-text-secondary">{l}</span>)}
              </div>
            </div>
          )}

          {/* Skills */}
          {skills.length > 0 && (
            <div className="card p-4">
              <p className="text-xs text-text-muted uppercase font-semibold tracking-wider mb-3">Skills</p>
              <div className="flex flex-wrap gap-1.5">
                {skills.map((s) => <span key={s} className="px-2.5 py-0.5 bg-orange/10 text-orange rounded-full text-xs">{s}</span>)}
              </div>
            </div>
          )}

          {/* About Me */}
          {app.about_me && (
            <div className="card p-4">
              <p className="text-xs text-text-muted uppercase font-semibold tracking-wider mb-3">About Me</p>
              <p className="text-sm text-text-secondary leading-relaxed">{app.about_me}</p>
            </div>
          )}

          <p className="text-xs text-text-muted">
            Applied {format(new Date(app.created_at), 'dd MMM yyyy, HH:mm')}
          </p>

          {/* Status selector */}
          <div>
            <label className="block text-xs text-text-muted mb-2">Update Status</label>
            <div className="grid grid-cols-3 gap-2">
              {ALL_STATUSES.map((s) => (
                <button
                  key={s}
                  onClick={() => setNewStatus(s)}
                  className={`py-2 px-3 rounded-xl text-xs font-medium border transition-colors ${
                    newStatus === s
                      ? 'bg-orange text-white border-orange'
                      : 'bg-surface-light text-text-secondary border-border hover:text-white'
                  }`}
                >
                  {STATUS_LABELS[s]}
                </button>
              ))}
            </div>
          </div>

          {/* Admin notes */}
          <div>
            <label className="block text-xs text-text-muted mb-1.5">Admin Notes</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={3}
              className="w-full bg-surface-light border border-border rounded-xl px-3 py-2 text-sm text-white resize-none focus:outline-none focus:border-orange/50 placeholder:text-text-muted"
              placeholder="Optional notes about this application…"
            />
          </div>
        </div>

        <div className="px-6 py-4 border-t border-border shrink-0 flex gap-3">
          <button onClick={onClose} className="flex-1 py-2.5 rounded-xl border border-border text-text-secondary hover:text-white text-sm font-medium transition-colors">
            Cancel
          </button>
          <button
            onClick={save}
            disabled={saving || (newStatus === app.status && notes === (app.admin_notes || ''))}
            className="flex-1 py-2.5 rounded-xl bg-orange text-white text-sm font-medium hover:bg-orange/90 transition-colors disabled:opacity-40"
          >
            {saving ? 'Saving…' : 'Save Changes'}
          </button>
        </div>
      </div>
    </div>
  );
}

function Row({ icon, label, value, capitalize }) {
  return (
    <div className="flex items-center gap-2 text-sm">
      <span className="text-text-muted">{icon}</span>
      <span className="text-text-muted w-24 shrink-0">{label}</span>
      <span className={`text-white ${capitalize ? 'capitalize' : ''}`}>{value}</span>
    </div>
  );
}

export default function HiringsPage() {
  const [hirings, setHirings] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('pending');
  const [loading, setLoading] = useState(false);
  const [selected, setSelected] = useState(null);
  const limit = 20;

  const fetchData = useCallback(() => {
    setLoading(true);
    api.get('/hirings', { params: { page, limit, status: statusFilter || undefined } })
      .then((r) => { setHirings(r.data.data); setTotal(r.data.total); })
      .catch(() => toast.error('Failed to load applications'))
      .finally(() => setLoading(false));
  }, [page, statusFilter]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const totalPages = Math.ceil(total / limit);

  return (
    <div className="p-8">
      <PageHeader title="Agent Hirings" subtitle={`${total} application${total !== 1 ? 's' : ''}`} />

      <div className="flex flex-wrap gap-2 mb-6">
        {STATUS_TABS.map((s) => (
          <button
            key={s}
            onClick={() => { setStatusFilter(s); setPage(1); }}
            className={`px-4 py-2 rounded-xl text-sm font-medium transition-colors ${statusFilter === s ? 'bg-orange text-white' : 'bg-surface-light text-text-secondary hover:text-white'}`}
          >
            {s === '' ? 'All' : STATUS_LABELS[s]}
          </button>
        ))}
      </div>

      <div className="card p-0 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-text-muted text-xs uppercase">
              <th className="px-4 py-3 text-left">Applicant</th>
              <th className="px-4 py-3 text-left">Token</th>
              <th className="px-4 py-3 text-left">Phone</th>
              <th className="px-4 py-3 text-left">Languages</th>
              <th className="px-4 py-3 text-left">Skills</th>
              <th className="px-4 py-3 text-left">Status</th>
              <th className="px-4 py-3 text-left">Applied</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <TableShimmer rows={8} cols={7} />
            ) : hirings.length === 0 ? (
              <tr><td colSpan={7} className="text-center py-12 text-text-muted">No applications found</td></tr>
            ) : hirings.map((h) => (
              <tr key={h.id} onClick={() => setSelected(h)} className="border-b border-divider hover:bg-surface-light/50 cursor-pointer">
                <td className="px-4 py-3">
                  <div className="flex items-center gap-3">
                    {h.profile_picture_url ? (
                      <img src={`https://api.grahvarta.com${h.profile_picture_url}`} alt={h.name} className="w-8 h-8 rounded-full object-cover border border-border" />
                    ) : (
                      <div className="w-8 h-8 rounded-full bg-surface-light flex items-center justify-center text-sm font-bold text-orange">
                        {h.name?.[0]?.toUpperCase() || '?'}
                      </div>
                    )}
                    <p className="font-medium text-white">{h.name}</p>
                  </div>
                </td>
                <td className="px-4 py-3 font-mono text-xs text-orange">{h.token_no || '—'}</td>
                <td className="px-4 py-3 text-text-secondary">{h.phone}</td>
                <td className="px-4 py-3 text-text-muted text-xs">
                  {Array.isArray(h.languages) ? h.languages.slice(0, 3).join(', ') + (h.languages.length > 3 ? ` +${h.languages.length - 3}` : '') : '—'}
                </td>
                <td className="px-4 py-3 text-text-muted text-xs">
                  {Array.isArray(h.skills) ? h.skills.slice(0, 2).join(', ') + (h.skills.length > 2 ? ` +${h.skills.length - 2}` : '') : '—'}
                </td>
                <td className="px-4 py-3">
                  <span className={statusBadge(h.status)}>{STATUS_LABELS[h.status] || h.status}</span>
                </td>
                <td className="px-4 py-3 text-text-muted text-xs">
                  {format(new Date(h.created_at), 'MMM d, yyyy')}
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

      {selected && (
        <DetailPanel app={selected} onClose={() => setSelected(null)} onUpdated={fetchData} />
      )}
    </div>
  );
}
