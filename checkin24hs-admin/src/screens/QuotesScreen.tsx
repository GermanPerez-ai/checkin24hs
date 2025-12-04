import React from 'react';
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Button,
} from '@mui/material';

const QuotesScreen: React.FC = () => {
  const quotes = [
    {
      id: '1',
      hotelName: 'Hotel Plaza Mayor',
      customerName: 'María González',
      checkIn: '2024-12-15',
      checkOut: '2024-12-18',
      adults: 2,
      children: 1,
      status: 'pending',
      totalPrice: '€450',
    },
    {
      id: '2',
      hotelName: 'Hotel Central',
      customerName: 'Juan Pérez',
      checkIn: '2024-12-20',
      checkOut: '2024-12-22',
      adults: 1,
      children: 0,
      status: 'confirmed',
      totalPrice: '€300',
    },
    {
      id: '3',
      hotelName: 'Hotel Deluxe',
      customerName: 'Ana López',
      checkIn: '2024-12-25',
      checkOut: '2024-12-28',
      adults: 2,
      children: 2,
      status: 'cancelled',
      totalPrice: '€600',
    },
  ];

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending':
        return 'warning';
      case 'confirmed':
        return 'success';
      case 'cancelled':
        return 'error';
      default:
        return 'default';
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Gestión de Cotizaciones
      </Typography>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Hotel</TableCell>
              <TableCell>Cliente</TableCell>
              <TableCell>Fechas</TableCell>
              <TableCell>Huéspedes</TableCell>
              <TableCell>Precio Total</TableCell>
              <TableCell>Estado</TableCell>
              <TableCell>Acciones</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {quotes.map((quote) => (
              <TableRow key={quote.id}>
                <TableCell>{quote.hotelName}</TableCell>
                <TableCell>{quote.customerName}</TableCell>
                <TableCell>
                  <Box>
                    <Typography variant="body2">
                      Entrada: {quote.checkIn}
                    </Typography>
                    <Typography variant="body2">
                      Salida: {quote.checkOut}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  {quote.adults} adultos, {quote.children} niños
                </TableCell>
                <TableCell>{quote.totalPrice}</TableCell>
                <TableCell>
                  <Chip
                    label={getStatusLabel(quote.status)}
                    color={getStatusColor(quote.status) as any}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  <Button size="small" variant="outlined" sx={{ mr: 1 }}>
                    Ver Detalles
                  </Button>
                  {quote.status === 'pending' && (
                    <Button size="small" variant="contained" color="success">
                      Confirmar
                    </Button>
                  )}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};

export default QuotesScreen; 