import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  TextField,
  Button,
  Typography,
  Card,
  CardContent,
  CardMedia,
  Grid,
  Rating,
  Chip,
  Container,
  InputAdornment
} from '@mui/material';
import { Search as SearchIcon } from '@mui/icons-material';
import { sampleHotels } from '../data/sampleData';
import { Hotel } from '../types';

const SearchScreen: React.FC = () => {
  const navigate = useNavigate();
  const [searchTerm, setSearchTerm] = useState('');
  const [filteredHotels, setFilteredHotels] = useState<Hotel[]>(sampleHotels);

  const handleSearch = () => {
    const filtered = sampleHotels.filter(hotel =>
      hotel.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      hotel.location.toLowerCase().includes(searchTerm.toLowerCase())
    );
    setFilteredHotels(filtered);
  };

  const handleHotelClick = (hotel: Hotel) => {
    navigate(`/hotel/${hotel.id}`);
  };

  return (
    <Container maxWidth="lg">
      <Typography variant="h4" component="h1" gutterBottom sx={{ mb: 3 }}>
        Buscar Hoteles
      </Typography>

      {/* Barra de búsqueda */}
      <Box sx={{ mb: 4 }}>
        <TextField
          fullWidth
          variant="outlined"
          placeholder="Buscar por nombre o ubicación..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          InputProps={{
            endAdornment: (
              <InputAdornment position="end">
                <Button
                  variant="contained"
                  onClick={handleSearch}
                  startIcon={<SearchIcon />}
                >
                  Buscar
                </Button>
              </InputAdornment>
            ),
          }}
          onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
        />
      </Box>

      {/* Resultados */}
      <Grid container spacing={3}>
        {filteredHotels.map((hotel) => (
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
                <Chip 
                  label={hotel.priceRange} 
                  color="primary" 
                  size="small" 
                />
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Container>
  );
};

export default SearchScreen; 