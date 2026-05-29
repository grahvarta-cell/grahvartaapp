import React, { useEffect, useState, useCallback } from 'react';
import { X, Edit2, Trash2, Check } from 'lucide-react';
import api from '../services/api';
import PageHeader from '../components/PageHeader';
import toast from 'react-hot-toast';

const PERMISSIONS = [
  { key: 'dashboard', label: 'Dashboard' },
  { key: 'users', label: 'Users' },
  { key: 'astrologers', label: 'Astrologers' },
  { key: 'withdrawals', label: 'Withdrawals' },
  { key: 'reports', label: 'Reports' },
  { key: 'transactions', label: 'Transactions' },
  { key: 'community', label: 'Community' },
  { key: 'notifications', label: 'Notifications' },
  { key: 'hirings', label: 'Hirings' },
  { key: 'recharge_offers', label: 'Recharge Offers' },
];

function SubadminModal({ isOpen, onClose, onSave, mode = 'create', initialData = null }) {
  const [formData, setFormData] = useState(initialData || { name: '', email: '', password: '', permissions: [], is_active: true });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (initialData) {
      setFormData(initialData);
    }
  }, [initialData]);

  const handleSave = async () => {
    if (!formData.name || !formData.email) {
      toast.error('Name and email are required');
      return;
    }
    if (mode === 'create' && !formData.password) {
      toast.error('Password is required');
      return;
    }
    setLoading(true);
    try {
      await onSave(formData);
      setFormData({ name: '', email: '', password: '', permissions: [], is_active: true });
      onClose();
    } finally {
      setLoading(false);
    }
  };

  const togglePermission = (key) => {
    setFormData(prev => ({
      ...prev,
      permissions: prev.permissions.includes(key)
        ? prev.permissions.filter(p => p !== key)
        : [...prev.permissions, key]
    }));
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-surface rounded-xl max-w-md w-full">
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <h2 className="text-lg font-bold text-white">{mode === 'create' ? 'Create Sub-admin' : 'Edit Sub-admin'}</h2>
          <button onClick={onClose} className="text-text-muted hover:text-white">
            <X size={20} />
          </button>
        </div>

        <div className="px-6 py-4 space-y-4 max-h-[calc(100vh-200px)] overflow-y-auto">
          <div>
            <label className="block text-xs text-text-secondary mb-1.5">Name</label>
            <input
              type="text"
              className="input"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              placeholder="John Doe"
            />
          </div>

          <div>
            <label className="block text-xs text-text-secondary mb-1.5">Email</label>
            <input
              type="email"
              className="input"
              value={formData.email}
              onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
              placeholder="john@example.com"
            />
          </div>

          <div>
            <label className="block text-xs text-text-secondary mb-1.5">{mode === 'create' ? 'Password' : 'Password (leave blank to keep)'}</label>
            <input
              type="password"
              className="input"
              value={formData.password}
              onChange={(e) => setFormData(prev => ({ ...prev, password: e.target.value }))}
              placeholder="••••••••"
            />
          </div>

          <div>
            <label className="block text-xs text-text-secondary mb-2">Permissions</label>
            <div className="space-y-2">
              {PERMISSIONS.map(perm => (
                <label key={perm.key} className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formData.permissions.includes(perm.key)}
                    onChange={() => togglePermission(perm.key)}
                    className="w-4 h-4"
                  />
                  <span className="text-sm text-text-secondary">{perm.label}</span>
                </label>
              ))}
            </div>
          </div>

          {mode === 'edit' && (
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                id="is_active"
                checked={formData.is_active}
                onChange={(e) => setFormData(prev => ({ ...prev, is_active: e.target.checked }))}
                className="w-4 h-4"
              />
              <label htmlFor="is_active" className="text-sm text-text-secondary cursor-pointer">
                Active
              </label>
            </div>
          )}
        </div>

        <div className="px-6 py-4 border-t border-border flex gap-3">
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2 rounded-xl text-sm font-medium bg-surface-light text-text-secondary hover:text-white transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleSave}
            disabled={loading}
            className="flex-1 btn-primary"
          >
            {loading ? 'Saving...' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function SubadminsPage() {
  const [subadmins, setSubadmins] = useState([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState(null);

  const fetchSubadmins = useCallback(() => {
    setLoading(true);
    api.get('/sub-admins')
      .then(r => setSubadmins(r.data.data))
      .catch(err => toast.error(err.response?.data?.message || 'Failed to fetch'))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { fetchSubadmins(); }, [fetchSubadmins]);

  const handleCreate = async (data) => {
    try {
      const payload = {
        name: data.name,
        email: data.email,
        password: data.password,
        permissions: data.permissions,
      };
      await api.post('/sub-admins', payload);
      toast.success('Sub-admin created');
      fetchSubadmins();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to create');
      throw err;
    }
  };

  const handleUpdate = async (data) => {
    try {
      const payload = {
        name: data.name,
        email: data.email,
        permissions: data.permissions,
        is_active: data.is_active,
      };
      if (data.password) {
        payload.password = data.password;
      }
      await api.put(`/sub-admins/${data.id}`, payload);
      toast.success('Sub-admin updated');
      fetchSubadmins();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to update');
      throw err;
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this sub-admin?')) return;
    try {
      await api.delete(`/sub-admins/${id}`);
      toast.success('Sub-admin deleted');
      fetchSubadmins();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to delete');
    }
  };

  const handleEdit = (item) => {
    setEditingItem(item);
    setModalOpen(true);
  };

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <PageHeader title="Sub-admins" subtitle={`${subadmins.length} total`} />
        <button
          onClick={() => { setEditingItem(null); setModalOpen(true); }}
          className="btn-primary"
        >
          + Create Sub-admin
        </button>
      </div>

      <div className="card p-0 overflow-hidden">
        {loading ? (
          <div className="p-8 text-center">
            <div className="w-8 h-8 border-2 border-orange border-t-transparent rounded-full animate-spin mx-auto" />
          </div>
        ) : subadmins.length === 0 ? (
          <div className="p-8 text-center text-text-muted">
            No sub-admins yet. Create one to get started.
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border text-text-muted text-xs uppercase">
                <th className="px-4 py-3 text-left">Name</th>
                <th className="px-4 py-3 text-left">Email</th>
                <th className="px-4 py-3 text-left">Permissions</th>
                <th className="px-4 py-3 text-left">Status</th>
                <th className="px-4 py-3" />
              </tr>
            </thead>
            <tbody>
              {subadmins.map(item => (
                <tr key={item.id} className="border-b border-border hover:bg-surface-light transition-colors">
                  <td className="px-4 py-3 text-white font-medium">{item.name}</td>
                  <td className="px-4 py-3 text-text-secondary">{item.email}</td>
                  <td className="px-4 py-3">
                    <div className="flex flex-wrap gap-1">
                      {item.permissions.length === 0 ? (
                        <span className="text-text-muted text-xs">—</span>
                      ) : (
                        item.permissions.map(p => (
                          <span key={p} className="badge-gray text-xs">
                            {PERMISSIONS.find(x => x.key === p)?.label || p}
                          </span>
                        ))
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <span className={item.is_active ? 'badge-success' : 'badge-gray'}>
                      {item.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-right">
                    <button
                      onClick={() => handleEdit(item)}
                      className="inline-flex items-center gap-2 px-3 py-1 rounded-lg text-sm text-orange hover:bg-orange/10 transition-colors"
                    >
                      <Edit2 size={16} />
                      Edit
                    </button>
                    <button
                      onClick={() => handleDelete(item.id)}
                      className="inline-flex items-center gap-2 px-3 py-1 rounded-lg text-sm text-error hover:bg-error/10 transition-colors ml-2"
                    >
                      <Trash2 size={16} />
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <SubadminModal
        isOpen={modalOpen}
        onClose={() => { setModalOpen(false); setEditingItem(null); }}
        onSave={editingItem ? handleUpdate : handleCreate}
        mode={editingItem ? 'edit' : 'create'}
        initialData={editingItem}
      />
    </div>
  );
}
