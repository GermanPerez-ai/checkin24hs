import React, { useState } from 'react';
import {
  Box,
  Typography,
  Button,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Grid,
  Rating,
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  Visibility,
  Star,
} from '@mui/icons-material';

interface Hotel {
  id: string;
  name: string;
  location: string;
  rating: number;
  priceRange: string;
  status: 'active' | 'inactive';
}

const HotelsScreen: React.FC = () => {
  const [hotels, setHotels] = useState<Hotel[]>([
    {
      id: '1',
      name: 'Hotel Plaza Mayor',
      location: 'Madrid, España',
      rating: 4.8,
      priceRange: '€200-€400',
      status: 'active',
    },
    {
      id: '2',
      name: 'Hotel Central',
      location: 'Barcelona, España',
      rating: 4.5,
      priceRange: '€150-€300',
      status: 'active',
    },
    {
      id: '3',
      name: 'Hotel Deluxe',
      location: 'Valencia, España',
      rating: 4.9,
      priceRange: '€300-€600',
      status: 'inactive',
    },
  ]);

  const [openDialog, setOpenDialog] = useState(false);
  const [editingHotel, setEditingHotel] = useState<Hotel | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    location: '',
    rating: 0,
    priceRange: '',
    status: 'active' as 'active' | 'inactive',
  });

  const handleOpenDialog = (hotel?: Hotel) => {
    if (hotel) {
      setEditingHotel(hotel);
      setFormData({
        name: hotel.name,
        location: hotel.location,
        rating: hotel.rating,
        priceRange: hotel.priceRange,
        status: hotel.status,
      });
    } else {
      setEditingHotel(null);
      setFormData({
        name: '',
        location: '',
        rating: 0,
        priceRange: '',
        status: 'active',
      });
    }
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setEditingHotel(null);
  };

  const handleSave = () => {
    if (editingHotel) {
      setHotels(hotels.map(hotel =>
        hotel.id === editingHotel.id
          ? { ...hotel, ...formData }
          : hotel
      ));
    } else {
      const newHotel: Hotel = {
        id: Date.now().toString(),
        ...formData,
      };
      setHotels([...hotels, newHotel]);
    }
    handleCloseDialog();
  };

  const handleDelete = (id: string) => {
    setHotels(hotels.filter(hotel => hotel.id !== id));
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4">
          Gestión de Hoteles
        </Typography>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => handleOpenDialog()}
        >
          Agregar Hotel
        </Button>
      </Box>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Nombre</TableCell>
              <TableCell>Ubicación</TableCell>
              <TableCell>Calificación</TableCell>
              <TableCell>Rango de Precio</TableCell>
              <TableCell>Estado</TableCell>
              <TableCell>Acciones</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {hotels.map((hotel) => (
              <TableRow key={hotel.id}>
                <TableCell>{hotel.name}</TableCell>
                <TableCell>{hotel.location}</TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <Rating value={hotel.rating} readOnly size="small" />
                    <Typography variant="body2" sx={{ ml: 1 }}>
                      {hotel.rating}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>{hotel.priceRange}</TableCell>
                <TableCell>
                  <Chip
                    label={hotel.status === 'active' ? 'Activo' : 'Inactivo'}
                    color={hotel.status === 'active' ? 'success' : 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  <IconButton size="small" color="primary">
                    <Visibility />
                  </IconButton>
                  <IconButton
                    size="small"
                    color="primary"
                    onClick={() => handleOpenDialog(hotel)}
                  >
                    <Edit />
                  </IconButton>
                  <IconButton
                    size="small"
                    color="error"
                    onClick={() => handleDelete(hotel.id)}
                  >
                    <Delete />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Dialog para agregar/editar hotel */}
      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>
          {editingHotel ? 'Editar Hotel' : 'Agregar Nuevo Hotel'}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Nombre del Hotel"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Ubicación"
                value={formData.location}
                onChange={(e) => setFormData({ ...formData, location: e.target.value })}
              />
            </Grid>
            <Grid item xs={6}>
              <TextField
                fullWidth
                label="Rango de Precio"
                value={formData.priceRange}
                onChange={(e) => setFormData({ ...formData, priceRange: e.target.value })}
                placeholder="€100-€300"
              />
            </Grid>
            <Grid item xs={6}>
              <Box sx={{ display: 'flex', alignItems: 'center', height: '100%' }}>
                <Typography variant="body2" sx={{ mr: 1 }}>
                  Calificación:
                </Typography>
                <Rating
                  value={formData.rating}
                  onChange={(_, value) => setFormData({ ...formData, rating: value || 0 })}
                />
              </Box>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancelar</Button>
          <Button onClick={handleSave} variant="contained">
            {editingHotel ? 'Actualizar' : 'Agregar'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default HotelsScreen; 