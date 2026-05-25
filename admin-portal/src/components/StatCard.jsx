import React from 'react';

export default function StatCard({ icon: Icon, label, value, sub, color = 'orange' }) {
  const colorMap = {
    orange: 'bg-orange/15 text-orange',
    green:  'bg-success/15 text-success',
    blue:   'bg-blue-500/15 text-blue-400',
    gold:   'bg-yellow-500/15 text-yellow-400',
    purple: 'bg-purple-500/15 text-purple-400',
  };
  return (
    <div className="card flex items-start gap-4">
      <div className={`p-3 rounded-xl ${colorMap[color] || colorMap.orange}`}>
        <Icon size={20} />
      </div>
      <div className="min-w-0">
        <p className="text-text-secondary text-xs mb-1">{label}</p>
        <p className="text-2xl font-bold text-white truncate">{value}</p>
        {sub && <p className="text-xs text-text-muted mt-0.5">{sub}</p>}
      </div>
    </div>
  );
}
