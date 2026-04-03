// Código para escribir MANUALMENTE en la consola (sin pegar)
// Escribe cada línea y presiona Enter

localStorage.setItem('dashboard_admin_users', JSON.stringify([
  {id:'admin-001',username:'admin',password:'admin123',password_hash:'admin123',name:'Administrador',role:'admin_total',email:'admin@checkin24hs.com',createdAt:new Date().toISOString(),status:'active',lastLogin:null},
  {id:'admin-002',username:'German',password:'123456',password_hash:'123456',name:'German Perez',role:'admin_total',email:'german@checkin24hs.com',createdAt:new Date().toISOString(),status:'active',lastLogin:null},
  {id:'admin-003',username:'Axel',password:'123456',password_hash:'123456',name:'Axel',role:'admin_total',email:'axel@checkin24hs.com',createdAt:new Date().toISOString(),status:'active',lastLogin:null}
]));

// Verificar que se crearon
const users = JSON.parse(localStorage.getItem('dashboard_admin_users') || '[]');
console.log('Usuarios creados:', users.length);

// Recargar la página
location.reload();
