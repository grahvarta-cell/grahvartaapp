import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Layout from './components/Layout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import UsersPage from './pages/UsersPage';
import UserDetailPage from './pages/UserDetailPage';
import AstrologersPage from './pages/AstrologersPage';
import ReportsPage from './pages/ReportsPage';
import TransactionsPage from './pages/TransactionsPage';
import NotificationsPage from './pages/NotificationsPage';
import WithdrawalsPage from './pages/WithdrawalsPage';
import CommunityPage from './pages/CommunityPage';
import HiringsPage from './pages/HiringsPage';

function ProtectedRoute({ children }) {
  const { admin, loading } = useAuth();
  if (loading) return <div className="min-h-screen bg-background flex items-center justify-center"><div className="w-8 h-8 border-2 border-orange border-t-transparent rounded-full animate-spin" /></div>;
  return admin ? children : <Navigate to="/login" replace />;
}

function AppRoutes() {
  const { admin } = useAuth();
  return (
    <Routes>
      <Route path="/login" element={admin ? <Navigate to="/" replace /> : <LoginPage />} />
      <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
        <Route index element={<DashboardPage />} />
        <Route path="users" element={<UsersPage />} />
        <Route path="users/:id" element={<UserDetailPage />} />
        <Route path="astrologers" element={<AstrologersPage />} />
        <Route path="withdrawals" element={<WithdrawalsPage />} />
        <Route path="reports" element={<ReportsPage />} />
        <Route path="transactions" element={<TransactionsPage />} />
        <Route path="community" element={<CommunityPage />} />
        <Route path="notifications" element={<NotificationsPage />} />
        <Route path="hirings" element={<HiringsPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <AppRoutes />
    </AuthProvider>
  );
}
