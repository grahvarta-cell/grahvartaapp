import React from 'react';

/* Single shimmer block */
export function ShimmerBlock({ className = '' }) {
  return <div className={`shimmer ${className}`} />;
}

/* A table body skeleton — rows x cols shimmer cells */
export function TableShimmer({ rows = 6, cols = 5 }) {
  return Array.from({ length: rows }).map((_, i) => (
    <tr key={i} className="border-b border-divider">
      {Array.from({ length: cols }).map((_, j) => (
        <td key={j} className="px-4 py-3">
          <ShimmerBlock className="h-4 w-full" />
        </td>
      ))}
    </tr>
  ));
}

/* Stat card skeleton */
export function StatCardShimmer() {
  return (
    <div className="card flex items-start gap-4">
      <ShimmerBlock className="w-12 h-12 rounded-xl flex-shrink-0" />
      <div className="flex-1 space-y-2">
        <ShimmerBlock className="h-3 w-24" />
        <ShimmerBlock className="h-7 w-32" />
      </div>
    </div>
  );
}
