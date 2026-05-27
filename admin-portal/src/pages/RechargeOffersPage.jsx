import React, { useEffect, useState } from 'react';
import { Plus, Pencil, Trash2, ToggleLeft, ToggleRight, Gift } from 'lucide-react';
import api from '../services/api';
import PageHeader from '../components/PageHeader';
import toast from 'react-hot-toast';

const EMPTY = { amount: '', bonus_percent: '', label: '', sort_order: 0 };

function OfferModal({ offer, onClose, onSaved }) {
  const isEdit = Boolean(offer?.id);
  const [form, setForm] = useState(offer ? { ...offer } : { ...EMPTY });
  const [saving, setSaving] = useState(false);

  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));

  const save = async () => {
    if (!form.amount || form.bonus_percent === '') return toast.error('Amount and bonus % are required');
    if (Number(form.amount) < 1) return toast.error('Amount must be > 0');
    if (Number(form.bonus_percent) < 0 || Number(form.bonus_percent) > 500) return toast.error('Bonus % must be 0–500');
    setSaving(true);
    try {
      if (isEdit) {
        await api.put(`/recharge-offers/${offer.id}`, form);
        toast.success('Offer updated');
      } else {
        await api.post('/recharge-offers', form);
        toast.success('Offer created');
      }
      onSaved();
      onClose();
    } catch (err) {
      toast.error(err.response?.data?.message || 'Save failed');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
      <div className="bg-surface border border-border rounded-2xl w-full max-w-md mx-4 p-6">
        <h2 className="text-lg font-bold text-white mb-5">{isEdit ? 'Edit Offer' : 'New Offer'}</h2>

        <div className="space-y-4">
          <div>
            <label className="text-xs text-text-muted mb-1 block">Recharge Amount (₹)</label>
            <input
              type="number" min="1" value={form.amount}
              onChange={e => set('amount', e.target.value)}
              className="w-full bg-card border border-border rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-orange"
              placeholder="e.g. 100"
            />
          </div>

          <div>
            <label className="text-xs text-text-muted mb-1 block">Bonus % (extra credited)</label>
            <input
              type="number" min="0" max="500" value={form.bonus_percent}
              onChange={e => set('bonus_percent', e.target.value)}
              className="w-full bg-card border border-border rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-orange"
              placeholder="e.g. 50"
            />
            {form.amount > 0 && form.bonus_percent > 0 && (
              <p className="text-xs text-green-400 mt-1">
                User pays ₹{form.amount} → gets ₹{(Number(form.amount) * (1 + Number(form.bonus_percent) / 100)).toFixed(0)} credited
              </p>
            )}
          </div>

          <div>
            <label className="text-xs text-text-muted mb-1 block">Label (shown in app)</label>
            <input
              type="text" value={form.label}
              onChange={e => set('label', e.target.value)}
              className="w-full bg-card border border-border rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-orange"
              placeholder="e.g. 50% Extra"
            />
          </div>

          <div>
            <label className="text-xs text-text-muted mb-1 block">Sort Order</label>
            <input
              type="number" min="0" value={form.sort_order}
              onChange={e => set('sort_order', e.target.value)}
              className="w-full bg-card border border-border rounded-xl px-4 py-2.5 text-white focus:outline-none focus:border-orange"
            />
          </div>
        </div>

        <div className="flex gap-3 mt-6">
          <button onClick={onClose} className="flex-1 py-2.5 rounded-xl border border-border text-text-secondary hover:text-white transition-colors text-sm">
            Cancel
          </button>
          <button
            onClick={save} disabled={saving}
            className="flex-1 py-2.5 rounded-xl bg-orange text-white font-medium text-sm hover:bg-orange/90 disabled:opacity-50 transition-colors"
          >
            {saving ? 'Saving…' : (isEdit ? 'Save Changes' : 'Create')}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function RechargeOffersPage() {
  const [offers, setOffers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(null); // null | 'new' | offer object

  const load = async () => {
    try {
      const res = await api.get('/recharge-offers');
      setOffers(res.data.data);
    } catch {
      toast.error('Failed to load offers');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const toggleActive = async (offer) => {
    try {
      await api.put(`/recharge-offers/${offer.id}`, { is_active: !offer.is_active });
      toast.success(offer.is_active ? 'Offer disabled' : 'Offer enabled');
      load();
    } catch {
      toast.error('Update failed');
    }
  };

  const remove = async (offer) => {
    if (!window.confirm(`Delete ₹${offer.amount} offer?`)) return;
    try {
      await api.delete(`/recharge-offers/${offer.id}`);
      toast.success('Offer deleted');
      load();
    } catch {
      toast.error('Delete failed');
    }
  };

  return (
    <div className="p-6 max-w-3xl mx-auto">
      <PageHeader
        title="Recharge Offers"
        subtitle="Control bonus credits shown to users on wallet recharge"
        action={
          <button
            onClick={() => setModal('new')}
            className="flex items-center gap-2 px-4 py-2 bg-orange text-white rounded-xl text-sm font-medium hover:bg-orange/90 transition-colors"
          >
            <Plus size={16} /> New Offer
          </button>
        }
      />

      {loading ? (
        <div className="flex justify-center py-16"><div className="w-6 h-6 border-2 border-orange border-t-transparent rounded-full animate-spin" /></div>
      ) : offers.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-text-muted gap-3">
          <Gift size={40} className="opacity-40" />
          <p className="text-sm">No recharge offers yet. Add one to get started.</p>
        </div>
      ) : (
        <div className="space-y-3">
          {offers.map(offer => {
            const walletCredit = Number(offer.amount) * (1 + Number(offer.bonus_percent) / 100);
            const bonusAmt = walletCredit - Number(offer.amount);
            return (
              <div
                key={offer.id}
                className={`flex items-center gap-4 bg-surface border rounded-2xl px-5 py-4 transition-opacity ${offer.is_active ? 'border-border' : 'border-border opacity-50'}`}
              >
                {/* Amount & credit */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-white font-bold text-base">₹{offer.amount}</span>
                    {offer.bonus_percent > 0 && (
                      <span className="bg-green-500/15 text-green-400 text-xs font-medium px-2 py-0.5 rounded-full">
                        +{offer.bonus_percent}%
                      </span>
                    )}
                    {!offer.is_active && (
                      <span className="bg-red-500/15 text-red-400 text-xs px-2 py-0.5 rounded-full">Disabled</span>
                    )}
                  </div>
                  <p className="text-text-muted text-sm mt-0.5">
                    User gets ₹{walletCredit.toFixed(0)} credited
                    {bonusAmt > 0 && <span className="text-green-400"> (+₹{bonusAmt.toFixed(0)} bonus)</span>}
                  </p>
                  {offer.label && <p className="text-text-muted text-xs mt-0.5">Label: {offer.label}</p>}
                </div>

                {/* Sort order badge */}
                <span className="text-xs text-text-muted bg-card border border-border px-2 py-1 rounded-lg">
                  #{offer.sort_order}
                </span>

                {/* Actions */}
                <div className="flex items-center gap-1">
                  <button
                    onClick={() => toggleActive(offer)}
                    title={offer.is_active ? 'Disable' : 'Enable'}
                    className={`p-2 rounded-lg transition-colors ${offer.is_active ? 'text-green-400 hover:bg-green-500/10' : 'text-text-muted hover:bg-surface-light'}`}
                  >
                    {offer.is_active ? <ToggleRight size={20} /> : <ToggleLeft size={20} />}
                  </button>
                  <button
                    onClick={() => setModal(offer)}
                    className="p-2 rounded-lg text-text-muted hover:text-orange hover:bg-orange/10 transition-colors"
                  >
                    <Pencil size={16} />
                  </button>
                  <button
                    onClick={() => remove(offer)}
                    className="p-2 rounded-lg text-text-muted hover:text-red-400 hover:bg-red-500/10 transition-colors"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {modal && (
        <OfferModal
          offer={modal === 'new' ? null : modal}
          onClose={() => setModal(null)}
          onSaved={load}
        />
      )}
    </div>
  );
}
