/**
 * Checkin24hs - Panel de Administración
 * 
 * Copyright (c) 2024 German Perez
 * Todos los derechos reservados.
 * 
 * Este archivo contiene el componente principal del panel de administración.
 * Desarrollado por German Perez en 2024.
 */

import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { Box } from '@mui/material';
import LoginScreen from './screens/LoginScreen';
import DashboardScreen from './screens/DashboardScreen';
import HotelsScreen from './screens/HotelsScreen';
import UsersScreen from './screens/UsersScreen';
import QuotesScreen from './screens/QuotesScreen';
import Layout from './components/Layout';
import { AuthProvider, useAuth } from './contexts/AuthContext';

const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated } = useAuth();
  
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  
  return <>{children}</>;
};

const AppRoutes: React.FC = () => {
  return (
    <Routes>
      <Route path="/login" element={<LoginScreen />} />
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<DashboardScreen />} />
        <Route path="hotels" element={<HotelsScreen />} />
        <Route path="users" element={<UsersScreen />} />
        <Route path="quotes" element={<QuotesScreen />} />
      </Route>
    </Routes>
  );
};

const App: React.FC = () => {
  return (
    <AuthProvider>
      <Box sx={{ minHeight: '100vh' }}>
        <AppRoutes />
      </Box>
    </AuthProvider>
  );
};

export default App; 