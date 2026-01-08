import React from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  Paper,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
} from '@mui/material';
import {
  Hotel,
  People,
  Receipt,
  TrendingUp,
  TrendingDown,
  Star,
} from '@mui/icons-material';

const DashboardScreen: React.FC = () => {
  const stats = [
    {
      title: 'Total Hoteles',
      value: '24',
      icon: <Hotel />,
      color: '#1976d2',
      change: '+12%',
      trend: 'up',
    },
    {
      title: 'Usuarios Activos',
      value: '1,234',
      icon: <People />,
      color: '#2e7d32',
      change: '+8%',
      trend: 'up',
    },
    {
      title: 'Cotizaciones',
      value: '567',
      icon: <Receipt />,
      color: '#ed6c02',
      change: '+15%',
      trend: 'up',
    },
    {
      title: 'Calificación Promedio',
      value: '4.8',
      icon: <Star />,
      color: '#9c27b0',
      change: '+0.2',
      trend: 'up',
    },
  ];

  const recentActivity = [
    {
      text: 'Nuevo hotel agregado: Hotel Plaza Mayor',
      time: 'Hace 2 horas',
    },
    {
      text: 'Cotización procesada para Hotel Central',
      time: 'Hace 3 horas',
    },
    {
      text: 'Usuario registrado: María González',
      time: 'Hace 4 horas',
    },
    {
      text: 'Reserva confirmada en Hotel Deluxe',
      time: 'Hace 5 horas',
    },
  ];

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>
      
      <Grid container spacing={3}>
        {/* Estadísticas */}
        {stats.map((stat, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <Box
                    sx={{
                      backgroundColor: stat.color,
                      borderRadius: '50%',
                      p: 1,
                      mr: 2,
                      color: 'white',
                    }}
                  >
                    {stat.icon}
                  </Box>
                  <Box>
                    <Typography variant="h4" component="div">
                      {stat.value}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {stat.title}
                    </Typography>
                  </Box>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  {stat.trend === 'up' ? (
                    <TrendingUp sx={{ color: 'success.main', mr: 1 }} />
                  ) : (
                    <TrendingDown sx={{ color: 'error.main', mr: 1 }} />
                  )}
                  <Typography
                    variant="body2"
                    color={stat.trend === 'up' ? 'success.main' : 'error.main'}
                  >
                    {stat.change} desde el mes pasado
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}

        {/* Actividad Reciente */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              Actividad Reciente
            </Typography>
            <List>
              {recentActivity.map((activity, index) => (
                <ListItem key={index} divider>
                  <ListItemIcon>
                    <Box
                      sx={{
                        width: 8,
                        height: 8,
                        borderRadius: '50%',
                        backgroundColor: 'primary.main',
                      }}
                    />
                  </ListItemIcon>
                  <ListItemText
                    primary={activity.text}
                    secondary={activity.time}
                  />
                </ListItem>
              ))}
            </List>
          </Paper>
        </Grid>

        {/* Gráfico de Ventas (placeholder) */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, height: 300 }}>
            <Typography variant="h6" gutterBottom>
              Ventas Mensuales
            </Typography>
            <Box
              sx={{
                height: 200,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                backgroundColor: 'grey.100',
                borderRadius: 1,
              }}
            >
              <Typography variant="body2" color="text.secondary">
                Gráfico de ventas (placeholder)
              </Typography>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default DashboardScreen; 