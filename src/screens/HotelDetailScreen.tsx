import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Card,
  CardContent,
  CardMedia,
  Button,
  Container,
  Rating,
  Chip
} from '@mui/material';
import { sampleHotels } from '../data/sampleData';

const HotelDetailScreen: React.FC = () => {
  const { hotelId } = useParams<{ hotelId: string }>();
  const navigate = useNavigate();
  
  const hotel = sampleHotels.find(h => h.id === hotelId);

  if (!hotel) {
    return (
      <Container>
        <Typography variant="h5">Hotel no encontrado</Typography>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg">
      <Card>
        <CardMedia
          component="img"
          height="400"
          image={hotel.imageUrl}
          alt={hotel.name}
        />
        <CardContent>
          <Typography variant="h4" gutterBottom>
            {hotel.name}
          </Typography>
          <Typography variant="h6" color="text.secondary" gutterBottom>
            <a 
              href={`https://www.google.com/maps/search/${encodeURIComponent(hotel.name + ' ' + hotel.location)}`}
              target="_blank"
              rel="noopener noreferrer"
              style={{ 
                color: '#1976d2', 
                textDecoration: 'none',
                display: 'flex',
                alignItems: 'center'
              }}
            >
              📍 {hotel.location}
            </a>
          </Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <Rating value={hotel.rating} precision={0.1} readOnly />
            <Typography variant="body1" sx={{ ml: 1 }}>
              {hotel.rating}
            </Typography>
          </Box>
          <Chip label={hotel.priceRange} color="primary" sx={{ mb: 2 }} />
          <Typography variant="body1" paragraph>
            {hotel.description}
          </Typography>
          <Button
            variant="contained"
            size="large"
            onClick={() => navigate(`/quote/${hotel.id}`)}
            sx={{ mt: 2 }}
          >
            Solicitar Cotización
          </Button>
        </CardContent>
      </Card>
    </Container>
  );
};

export default HotelDetailScreen; 