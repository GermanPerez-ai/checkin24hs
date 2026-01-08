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
  Avatar,
} from '@mui/material';

const UsersScreen: React.FC = () => {
  const users = [
    {
      id: '1',
      name: 'María González',
      email: 'maria@example.com',
      status: 'active',
      joinDate: '2024-01-15',
    },
    {
      id: '2',
      name: 'Juan Pérez',
      email: 'juan@example.com',
      status: 'active',
      joinDate: '2024-02-20',
    },
    {
      id: '3',
      name: 'Ana López',
      email: 'ana@example.com',
      status: 'inactive',
      joinDate: '2024-03-10',
    },
  ];

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Gestión de Usuarios
      </Typography>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Usuario</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Estado</TableCell>
              <TableCell>Fecha de Registro</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {users.map((user) => (
              <TableRow key={user.id}>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center' }}>
                    <Avatar sx={{ mr: 2 }}>
                      {user.name.charAt(0)}
                    </Avatar>
                    {user.name}
                  </Box>
                </TableCell>
                <TableCell>{user.email}</TableCell>
                <TableCell>
                  <Chip
                    label={user.status === 'active' ? 'Activo' : 'Inactivo'}
                    color={user.status === 'active' ? 'success' : 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell>{user.joinDate}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};

export default UsersScreen; 