import React, { useEffect, useState } from 'react';
import { Edit2, ToggleLeft, ToggleRight, Trash2, Plus } from 'lucide-react';
import api from '../services/api';
import PageHeader from '../components/PageHeader';
import { TableShimmer } from '../components/Shimmer';
import toast from 'react-hot-toast';

const EMPTY = { name: '', category: '', icon: '📄', description: '', inclusions: '', sort_order: 0 };

function ReportModal({ report, onClose, onSaved }) {
  const isNew = !report.id;
  const [form, setForm] = useState({
    name: report.name || '',
    category: report.category || '',
    icon: report.icon || '📄',
    description: report.description || '',
    inclusions: (report.inclusions || []).join('\n'),
    sort_order: report.sort_order || 0,
  });
  const [loading, setLoading] = useState(false);

  const set = (k, v) => setForm(p => ({ ...p, [k]: v }));

  const save = async () => {
    if (!form.name.trim() || !form.category.trim()) return toast.error('Name and category are required');
    setLoading(true);
    try {
      const payload = {
        name: form.name,
        category: form.category,
        icon: form.icon,
        description: form.description,
        inclusions: form.inclusions.split('\n').map(s => s.trim()).filter(Boolean),
        sort_order: parseInt(form.sort_order) || 0,
      };
      if (isNew) {
        await api.post('/reports', payload);
        toast.success('Report created');
      } else {
        await api.put(`/reports/${report.id}`, payload);
        toast.success('Report updated');
      }
      onSaved();
      onClose();
    } catch {
      toast.error('Failed to save');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 overflow-y-auto">
      <div className="card w-full max-w-lg my-4">
        <h3 className="font-semibold text-white mb-4">{isNew ? 'Add Report' : 'Edit Report'}</h3>
        <div className="space-y-3">
          <div className="grid grid-cols-5 gap-3">
            <div className="col-span-1">
              <label className="text-xs text-text-secondary mb-1 block">Icon</label>
              <input className="input text-center text-xl" value={form.icon} onChange={e => set('icon', e.target.value)} maxLength={2} />
            </div>
            <div className="col-span-4">
              <label className="text-xs text-text-secondary mb-1 block">Name *</label>
              <input className="input" placeholder="e.g. Career (Salaried Employee)" value={form.name} onChange={e => set('name', e.target.value)} />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs text-text-secondary mb-1 block">Category *</label>
              <input className="input" placeholder="e.g. Plan Your Professional Roadmap" value={form.category} onChange={e => set('category', e.target.value)} />
            </div>
            <div>
              <label className="text-xs text-text-secondary mb-1 block">Sort Order</label>
              <input className="input" type="number" value={form.sort_order} onChange={e => set('sort_order', e.target.value)} />
            </div>
          </div>
          <div>
            <label className="text-xs text-text-secondary mb-1 block">Description</label>
            <textarea className="input h-20 resize-none" placeholder="Short description shown to users" value={form.description} onChange={e => set('description', e.target.value)} />
          </div>
          <div>
            <label className="text-xs text-text-secondary mb-1 block">Inclusions <span className="text-text-muted">(one per line)</span></label>
            <textarea className="input h-32 resize-none font-mono text-xs" placeholder={"Life purpose & soul mission\nKey life themes\nKarmic lessons to overcome"} value={form.inclusions} onChange={e => set('inclusions', e.target.value)} />
          </div>
        </div>
        <div className="flex gap-2 mt-5">
          <button onClick={onClose} className="btn-ghost flex-1">Cancel</button>
          <button onClick={save} disabled={loading} className="btn-primary flex-1">{loading ? 'Saving…' : isNew ? 'Create Report' : 'Save Changes'}</button>
        </div>
      </div>
    </div>
  );
}

export default function ReportsPage() {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(null); // null | report object (with id = edit, without = add)

  const fetchReports = () => {
    setLoading(true);
    api.get('/reports').then((r) => setReports(r.data.data)).finally(() => setLoading(false));
  };

  useEffect(() => { fetchReports(); }, []);

  const toggle = async (id) => {
    try {
      const r = await api.post(`/reports/${id}/toggle`);
      setReports(prev => prev.map(rp => rp.id === id ? { ...rp, is_active: r.data.data.is_active } : rp));
    } catch {
      toast.error('Failed');
    }
  };

  const deleteReport = async (report) => {
    if (!window.confirm(`Delete "${report.name}"? This cannot be undone.`)) return;
    try {
      await api.delete(`/reports/${report.id}`);
      toast.success('Report deleted');
      fetchReports();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to delete');
    }
  };

  return (
    <div className="p-8">
      {modal && <ReportModal report={modal} onClose={() => setModal(null)} onSaved={fetchReports} />}

      <PageHeader
        title="Reports"
        subtitle={`${reports.length} reports`}
        action={
          <button onClick={() => setModal(EMPTY)} className="btn-primary flex items-center gap-2">
            <Plus size={14} /> Add Report
          </button>
        }
      />

      <div className="card p-0 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-text-muted text-xs uppercase">
              <th className="px-4 py-3 text-left">Report</th>
              <th className="px-4 py-3 text-left">Category</th>
              <th className="px-4 py-3 text-right">Unlocks</th>
              <th className="px-4 py-3 text-right">Rating</th>
              <th className="px-4 py-3 text-center">Sort</th>
              <th className="px-4 py-3 text-left">Status</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <TableShimmer rows={6} cols={7} />
            ) : reports.length === 0 ? (
              <tr><td colSpan={7} className="text-center py-12 text-text-muted">No reports yet</td></tr>
            ) : reports.map((r) => (
              <tr key={r.id} className="border-b border-divider hover:bg-surface-light/50">
                <td className="px-4 py-3">
                  <span className="mr-2">{r.icon}</span>
                  <span className="font-medium text-white">{r.name}</span>
                </td>
                <td className="px-4 py-3 text-text-secondary text-xs">{r.category}</td>
                <td className="px-4 py-3 text-right text-text-secondary">{parseInt(r.total_unlocks || 0).toLocaleString()}</td>
                <td className="px-4 py-3 text-right text-gold font-medium">★ {r.avg_rating}</td>
                <td className="px-4 py-3 text-center text-text-muted text-xs">{r.sort_order}</td>
                <td className="px-4 py-3">
                  <span className={r.is_active ? 'badge-success' : 'badge-error'}>{r.is_active ? 'Active' : 'Inactive'}</span>
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center justify-end gap-2">
                    <button onClick={() => setModal(r)} className="p-1.5 rounded-lg bg-surface-light hover:bg-border transition-colors" title="Edit">
                      <Edit2 size={14} className="text-text-secondary" />
                    </button>
                    <button onClick={() => toggle(r.id)} className="p-1.5 rounded-lg bg-surface-light hover:bg-border transition-colors" title="Toggle active">
                      {r.is_active
                        ? <ToggleRight size={16} className="text-success" />
                        : <ToggleLeft size={16} className="text-text-muted" />
                      }
                    </button>
                    <button onClick={() => deleteReport(r)} className="p-1.5 rounded-lg bg-error/10 hover:bg-error/20 transition-colors" title="Delete">
                      <Trash2 size={14} className="text-error" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
