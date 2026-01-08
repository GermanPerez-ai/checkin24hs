import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Card,
  CardContent,
  CardMedia,
  Grid,
  Rating,
  Chip,
  Button,
  Container,
  Paper
} from '@mui/material';
import { sampleHotels } from '../data/sampleData';
import { Hotel } from '../types';

const HomeScreen: React.FC = () => {
  const navigate = useNavigate();

  const handleHotelClick = (hotel: Hotel) => {
    navigate(`/hotel/${hotel.id}`);
  };

  const handleSearchClick = () => {
    navigate('/search');
  };

  return (
    <Container maxWidth="lg">
      {/* Header con imagen de fondo */}
      <Paper
        sx={{
          position: 'relative',
          backgroundColor: 'grey.800',
          color: '#fff',
          mb: 4,
          backgroundSize: 'cover',
          backgroundRepeat: 'no-repeat',
          backgroundPosition: 'center',
          backgroundImage: `url(https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800)`,
          height: 300,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center'
        }}
      >
        <Box
          sx={{
            position: 'absolute',
            top: 0,
            bottom: 0,
            right: 0,
            left: 0,
            backgroundColor: 'rgba(0,0,0,.3)',
          }}
        />
        <Box
          sx={{
            position: 'relative',
            p: { xs: 3, md: 6 },
            pr: { md: 0 },
            textAlign: 'center'
          }}
        >
          <Typography variant="h3" component="h1" gutterBottom>
            Checkin24hs
          </Typography>
          <Typography variant="h5" paragraph>
            Encuentra los mejores hoteles para tu próxima aventura
          </Typography>
          <Button
            variant="contained"
            size="large"
            onClick={handleSearchClick}
            sx={{ mt: 2 }}
          >
            Buscar Hoteles
          </Button>
        </Box>
      </Paper>

      {/* Hoteles de Experiencias */}
      <Typography variant="h4" component="h2" gutterBottom sx={{ mb: 3 }}>
        Hoteles de Experiencias
      </Typography>

      <Grid container spacing={3}>
        {sampleHotels.slice(0, 3).map((hotel) => (
          <Grid item xs={12} sm={6} md={4} key={hotel.id}>
            <Card 
              sx={{ 
                height: '100%', 
                display: 'flex', 
                flexDirection: 'column',
                cursor: 'pointer',
                '&:hover': {
                  transform: 'translateY(-4px)',
                  transition: 'transform 0.2s ease-in-out',
                  boxShadow: 3
                }
              }}
              onClick={() => handleHotelClick(hotel)}
            >
              <CardMedia
                component="img"
                height="200"
                image={hotel.imageUrl}
                alt={hotel.name}
              />
              <CardContent sx={{ flexGrow: 1 }}>
                <Typography gutterBottom variant="h6" component="h3">
                  {hotel.name}
                </Typography>
                <Typography variant="body2" color="text.secondary" paragraph>
                  {hotel.location}
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <Rating value={hotel.rating} precision={0.1} readOnly size="small" />
                  <Typography variant="body2" sx={{ ml: 1 }}>
                    {hotel.rating}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Chip 
                    label={hotel.priceRange} 
                    color="primary" 
                    size="small" 
                  />
                  <Typography variant="body2" color="text.secondary">
                    {hotel.description.substring(0, 80)}...
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Botón para ver más hoteles */}
      <Box sx={{ textAlign: 'center', mt: 4 }}>
        <Button
          variant="outlined"
          size="large"
          onClick={handleSearchClick}
        >
          Ver Todos los Hoteles
        </Button>
      </Box>
    </Container>
  );
};

export default HomeScreen; 