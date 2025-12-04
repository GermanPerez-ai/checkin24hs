import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Typography,
  Card,
  CardContent,
  TextField,
  Button,
  Container,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem
} from '@mui/material';
import { sampleHotels } from '../data/sampleData';

const QuoteScreen: React.FC = () => {
  const { hotelId } = useParams<{ hotelId: string }>();
  const navigate = useNavigate();
  
  const hotel = sampleHotels.find(h => h.id === hotelId);
  const [formData, setFormData] = useState({
    checkInDate: '',
    checkOutDate: '',
    adults: 1,
    children: 0
  });

  if (!hotel) {
    return (
      <Container>
        <Typography variant="h5">Hotel no encontrado</Typography>
      </Container>
    );
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Aquí se enviaría la cotización
    alert('Cotización enviada exitosamente');
    navigate('/');
  };

  return (
    <Container maxWidth="md">
      <Typography variant="h4" gutterBottom>
        Solicitar Cotización
      </Typography>
      
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h5" gutterBottom>
            {hotel.name}
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {hotel.location}
          </Typography>
        </CardContent>
      </Card>

      <Card>
        <CardContent>
          <form onSubmit={handleSubmit}>
            <Grid container spacing={3}>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Fecha de Check-in"
                  type="date"
                  value={formData.checkInDate}
                  onChange={(e) => setFormData({...formData, checkInDate: e.target.value})}
                  InputLabelProps={{ shrink: true }}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Fecha de Check-out"
                  type="date"
                  value={formData.checkOutDate}
                  onChange={(e) => setFormData({...formData, checkOutDate: e.target.value})}
                  InputLabelProps={{ shrink: true }}
                  required
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Adultos</InputLabel>
                  <Select
                    value={formData.adults}
                    label="Adultos"
                    onChange={(e) => setFormData({...formData, adults: Number(e.target.value)})}
                  >
                    {[1,2,3,4,5,6].map(num => (
                      <MenuItem key={num} value={num}>{num}</MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Niños</InputLabel>
                  <Select
                    value={formData.children}
                    label="Niños"
                    onChange={(e) => setFormData({...formData, children: Number(e.target.value)})}
                  >
                    {[0,1,2,3,4].map(num => (
                      <MenuItem key={num} value={num}>{num}</MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12}>
                <Button
                  type="submit"
                  variant="contained"
                  size="large"
                  fullWidth
                >
                  Enviar Cotización
                </Button>
              </Grid>
            </Grid>
          </form>
        </CardContent>
      </Card>
    </Container>
  );
};

export default QuoteScreen; 