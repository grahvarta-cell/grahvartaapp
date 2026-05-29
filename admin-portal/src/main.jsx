import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { TooltipProvider } from './components/Tooltip';
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <BrowserRouter basename="/admin">
    <TooltipProvider>
      <App />
    <Toaster
      position="top-right"
      toastOptions={{
        style: { background: '#1E1E1E', color: '#fff', border: '1px solid #2A2A2A' },
        success: { iconTheme: { primary: '#43A047', secondary: '#fff' } },
        error: { iconTheme: { primary: '#E53935', secondary: '#fff' } },
      }}
    />
    </TooltipProvider>
  </BrowserRouter>
);
