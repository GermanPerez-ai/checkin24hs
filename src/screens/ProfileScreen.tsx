import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Avatar,
  Button,
  Container,
  List,
  ListItem,
  ListItemText,
  Divider
} from '@mui/material';
import { sampleUser, sampleSearchHistory } from '../data/sampleData';

const ProfileScreen: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Container maxWidth="md">
      <Typography variant="h4" component="h1" gutterBottom sx={{ mb: 3 }}>
        Mi Perfil
      </Typography>

      {/* Información del usuario */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <Avatar sx={{ width: 80, height: 80, mr: 2 }}>
              {sampleUser.name.charAt(0)}
            </Avatar>
            <Box>
              <Typography variant="h5" component="h2">
                {sampleUser.name}
              </Typography>
              <Typography variant="body1" color="text.secondary">
                {sampleUser.email}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {sampleUser.phone}
              </Typography>
            </Box>
          </Box>
          <Button variant="outlined" onClick={() => navigate('/login')}>
            Editar Perfil
          </Button>
        </CardContent>
      </Card>

      {/* Historial de búsquedas */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Historial de Búsquedas
          </Typography>
          <List>
            {sampleSearchHistory.map((search, index) => (
              <React.Fragment key={search.id}>
                <ListItem>
                  <ListItemText
                    primary={search.hotelName}
                    secondary={`${search.location} - ${search.searchDate}`}
                  />
                </ListItem>
                {index < sampleSearchHistory.length - 1 && <Divider />}
              </React.Fragment>
            ))}
          </List>
        </CardContent>
      </Card>
    </Container>
  );
};

export default ProfileScreen; 