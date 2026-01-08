/**
 * Checkin24hs - Pantalla de Bienvenida
 * 
 * Copyright (c) 2024 German Perez
 * Todos los derechos reservados.
 * 
 * Este archivo contiene la pantalla de bienvenida con imagen animada.
 * Desarrollado por German Perez en 2024.
 */

import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Button,
  Container,
  Paper,
  Fade,
  Slide,
  Zoom,
  Grow
} from '@mui/material';
import {
  Hotel as HotelIcon,
  ArrowForward as ArrowForwardIcon,
  Star as StarIcon
} from '@mui/icons-material';

const WelcomeScreen: React.FC = () => {
  const navigate = useNavigate();
  const [isVisible, setIsVisible] = useState(false);
  const [imageLoaded, setImageLoaded] = useState(false);

  useEffect(() => {
    // Animación de entrada
    const timer = setTimeout(() => {
      setIsVisible(true);
    }, 500);

    return () => clearTimeout(timer);
  }, []);

  const handleGetStarted = () => {
    navigate('/login');
  };

  const handleSkipLogin = () => {
    navigate('/');
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        position: 'relative',
        overflow: 'hidden'
      }}
    >
             {/* Imagen de fondo animada */}
       <Box
         sx={{
           position: 'absolute',
           top: 0,
           left: 0,
           right: 0,
           bottom: 0,
           backgroundImage: 'url("https://images.unsplash.com/photo-1571896349842-33c89424de2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2068&q=80")',
           backgroundSize: 'cover',
           backgroundPosition: 'center',
           backgroundRepeat: 'no-repeat',
           opacity: 0.4,
           animation: 'slowZoom 25s ease-in-out infinite alternate',
           '@keyframes slowZoom': {
             '0%': {
               transform: 'scale(1)',
             },
             '100%': {
               transform: 'scale(1.15)',
             },
           },
         }}
         onLoad={() => setImageLoaded(true)}
       />

             {/* Overlay con gradiente */}
       <Box
         sx={{
           position: 'absolute',
           top: 0,
           left: 0,
           right: 0,
           bottom: 0,
           background: 'linear-gradient(135deg, rgba(102, 126, 234, 0.7) 0%, rgba(118, 75, 162, 0.7) 50%, rgba(255, 107, 107, 0.6) 100%)',
         }}
       />

       {/* Partículas flotantes */}
       {[...Array(20)].map((_, index) => (
         <Box
           key={index}
           sx={{
             position: 'absolute',
             width: Math.random() * 4 + 2,
             height: Math.random() * 4 + 2,
             backgroundColor: 'rgba(255, 255, 255, 0.3)',
             borderRadius: '50%',
             left: `${Math.random() * 100}%`,
             top: `${Math.random() * 100}%`,
             animation: `floatParticle ${Math.random() * 10 + 10}s linear infinite`,
             '@keyframes floatParticle': {
               '0%': {
                 transform: 'translateY(100vh) rotate(0deg)',
                 opacity: 0,
               },
               '10%': {
                 opacity: 1,
               },
               '90%': {
                 opacity: 1,
               },
               '100%': {
                 transform: 'translateY(-100px) rotate(360deg)',
                 opacity: 0,
               },
             },
           }}
         />
       ))}

      <Container maxWidth="md" sx={{ position: 'relative', zIndex: 1 }}>
        <Box
          sx={{
            minHeight: '100vh',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
            alignItems: 'center',
            textAlign: 'center',
            color: 'white',
            py: 4
          }}
        >
          {/* Logo animado */}
          <Fade in={isVisible} timeout={1000}>
            <Box sx={{ mb: 4 }}>
              <HotelIcon 
                sx={{ 
                  fontSize: 80, 
                  color: 'white',
                  filter: 'drop-shadow(0 4px 8px rgba(0,0,0,0.3))',
                  animation: 'float 3s ease-in-out infinite'
                }}
              />
            </Box>
          </Fade>

          {/* Título principal */}
          <Slide direction="up" in={isVisible} timeout={1200}>
            <Typography
              variant="h2"
              component="h1"
              sx={{
                fontWeight: 'bold',
                mb: 2,
                textShadow: '2px 2px 4px rgba(0,0,0,0.5)',
                fontSize: { xs: '2.5rem', md: '3.5rem' }
              }}
            >
              Checkin24hs
            </Typography>
          </Slide>

          {/* Subtítulo */}
          <Slide direction="up" in={isVisible} timeout={1400}>
            <Typography
              variant="h5"
              sx={{
                mb: 4,
                opacity: 0.9,
                textShadow: '1px 1px 2px rgba(0,0,0,0.5)',
                fontSize: { xs: '1.2rem', md: '1.5rem' }
              }}
            >
              Estás a un check-in de tu próxima reserva
            </Typography>
          </Slide>

                     {/* Descripción */}
           <Zoom in={isVisible} timeout={1600}>
             <Typography
               variant="body1"
               sx={{
                 mb: 6,
                 maxWidth: 600,
                 opacity: 0.8,
                 lineHeight: 1.6,
                 fontSize: { xs: '1rem', md: '1.1rem' }
               }}
             >
               Descubre los mejores hoteles y resorts de Chile, desde la majestuosa Patagonia 
               hasta el desierto de Atacama. Reserva con confianza y disfruta de experiencias 
               únicas en los destinos más hermosos del país.
             </Typography>
           </Zoom>

          {/* Características destacadas */}
          <Grow in={isVisible} timeout={1800}>
            <Box sx={{ mb: 6, display: 'flex', gap: 3, flexWrap: 'wrap', justifyContent: 'center' }}>
                             {[
                 { icon: <StarIcon />, text: 'Hoteles Premium' },
                 { icon: <HotelIcon />, text: 'Reservas Seguras' },
                 { icon: <StarIcon />, text: 'Destinos Únicos' }
               ].map((feature, index) => (
                <Paper
                  key={index}
                  sx={{
                    p: 2,
                    backgroundColor: 'rgba(255,255,255,0.1)',
                    backdropFilter: 'blur(10px)',
                    border: '1px solid rgba(255,255,255,0.2)',
                    borderRadius: 2,
                    display: 'flex',
                    alignItems: 'center',
                    gap: 1,
                    minWidth: 150
                  }}
                >
                  <Box sx={{ color: 'white' }}>{feature.icon}</Box>
                  <Typography variant="body2" sx={{ color: 'white', fontWeight: 500 }}>
                    {feature.text}
                  </Typography>
                </Paper>
              ))}
            </Box>
          </Grow>

          {/* Botones de acción */}
          <Grow in={isVisible} timeout={2000}>
            <Box sx={{ display: 'flex', gap: 2, flexDirection: { xs: 'column', sm: 'row' } }}>
              <Button
                variant="contained"
                size="large"
                onClick={handleGetStarted}
                sx={{
                  backgroundColor: 'white',
                  color: '#667eea',
                  px: 4,
                  py: 1.5,
                  borderRadius: 3,
                  fontWeight: 'bold',
                  fontSize: '1.1rem',
                  '&:hover': {
                    backgroundColor: 'rgba(255,255,255,0.9)',
                    transform: 'translateY(-2px)',
                    boxShadow: '0 8px 25px rgba(0,0,0,0.3)'
                  },
                  transition: 'all 0.3s ease'
                }}
                endIcon={<ArrowForwardIcon />}
              >
                Comenzar
              </Button>
              
              <Button
                variant="outlined"
                size="large"
                onClick={handleSkipLogin}
                sx={{
                  borderColor: 'white',
                  color: 'white',
                  px: 4,
                  py: 1.5,
                  borderRadius: 3,
                  fontWeight: 'bold',
                  fontSize: '1.1rem',
                  '&:hover': {
                    backgroundColor: 'rgba(255,255,255,0.1)',
                    borderColor: 'white',
                    transform: 'translateY(-2px)'
                  },
                  transition: 'all 0.3s ease'
                }}
              >
                Explorar sin registro
              </Button>
            </Box>
          </Grow>
        </Box>
      </Container>

      {/* Animación de flotación */}
      <style>
        {`
          @keyframes float {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-10px); }
          }
        `}
      </style>
    </Box>
  );
};

export default WelcomeScreen; 