/**
 * Checkin24hs - Aplicación Web
 * 
 * Copyright (c) 2024 German Perez
 * Todos los derechos reservados.
 * 
 * Este archivo contiene el componente principal de la aplicación web Checkin24hs.
 * Desarrollado por German Perez en 2024.
 */

import React, { useState, useMemo } from 'react';
import { BrowserRouter as Router, Routes, Route, useNavigate, useLocation } from 'react-router-dom';
import {
  AppBar,
  Toolbar,
  Typography,
  Box,
  Paper,
  BottomNavigation,
  BottomNavigationAction,
  Container,
  CssBaseline,
  ThemeProvider,
  createTheme
} from '@mui/material';
import {
  Home as HomeIcon,
  Search as SearchIcon,
  Person as PersonIcon
} from '@mui/icons-material';

// Importar pantallas
import WelcomeScreenAlt from './screens/WelcomeScreenAlt';
import HomeScreen from './screens/HomeScreen';
import SearchScreen from './screens/SearchScreen';
import ProfileScreen from './screens/ProfileScreen';
import HotelDetailScreen from './screens/HotelDetailScreen';
import QuoteScreen from './screens/QuoteScreen';
import LoginScreen from './screens/LoginScreen';


// Crear tema personalizado
const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

// Componente de navegación inferior
function BottomNav() {
  const navigate = useNavigate();
  const location = useLocation();
  
  const [value, setValue] = useState(0);

  const tabs = useMemo(() => [
    { title: 'Inicio', icon: HomeIcon, path: '/home' },
    { title: 'Buscar', icon: SearchIcon, path: '/search' },
    { title: 'Perfil', icon: PersonIcon, path: '/profile' }
  ], []);

  const handleChange = (event: React.SyntheticEvent, newValue: number) => {
    setValue(newValue);
    navigate(tabs[newValue].path);
  };

  // Determinar el valor activo basado en la ruta actual
  React.useEffect(() => {
    const currentIndex = tabs.findIndex(tab => tab.path === location.pathname);
    if (currentIndex !== -1) {
      setValue(currentIndex);
    }
  }, [location.pathname, tabs]);

  return (
    <Paper sx={{ position: 'fixed', bottom: 0, left: 0, right: 0 }} elevation={3}>
      <BottomNavigation
        value={value}
        onChange={handleChange}
        showLabels
      >
        {tabs.map((tab, index) => (
          <BottomNavigationAction
            key={index}
            label={tab.title}
            icon={<tab.icon />}
          />
        ))}
      </BottomNavigation>
    </Paper>
  );
}

// Componente principal de la aplicación
function AppContent() {
  return (
    <Box sx={{ pb: 7 }}> {/* pb: 7 para dar espacio al BottomNavigation */}
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Checkin24hs
          </Typography>
        </Toolbar>
      </AppBar>
      
      <Container maxWidth="lg" sx={{ mt: 2, mb: 2 }}>
        <Routes>
          <Route path="/" element={<WelcomeScreenAlt />} />
          <Route path="/home" element={<HomeScreen />} />
          <Route path="/search" element={<SearchScreen />} />
          <Route path="/profile" element={<ProfileScreen />} />
          <Route path="/hotel/:hotelId" element={<HotelDetailScreen />} />
          <Route path="/quote/:hotelId" element={<QuoteScreen />} />
          <Route path="/login" element={<LoginScreen />} />
  
        </Routes>
      </Container>
      
      <BottomNav />
    </Box>
  );
}

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <AppContent />
      </Router>
    </ThemeProvider>
  );
}

export default App; 