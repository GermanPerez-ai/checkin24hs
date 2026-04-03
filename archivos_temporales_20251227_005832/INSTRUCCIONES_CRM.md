# Instrucciones para Crear CRM Separado (crm.checkin24hs.com)

## Objetivo
Crear una página web separada en `crm.checkin24hs.com` que contenga solo:
- Interacciones
- Chats  
- Flor IA

Esto aislará estas funcionalidades y evitará que afecten al dashboard principal.

## Pasos para Implementar

### 1. Crear archivo crm.html

El archivo `crm.html` debe contener:
- Estructura HTML básica con head y body
- Estilos CSS mínimos (copiar del dashboard.html)
- Solo las secciones: `interactions-section`, `chats-section`, `flor-config-section`
- JavaScript necesario para estas secciones
- Supabase client
- showSection function en el head

### 2. Crear serve-crm.js

Ya está creado el archivo `serve-crm.js` que servirá el CRM.

### 3. Configurar en EasyPanel

1. **Crear nuevo servicio:**
   - Nombre: `crm`
   - Tipo: Static Site o Node.js
   - Si es Node.js, usar comando: `node serve-crm.js`
   - Puerto: 3000 (o el que prefieras)

2. **Configurar dominio:**
   - Dominio: `crm.checkin24hs.com`
   - EasyPanel debería configurar Traefik automáticamente

3. **Si Traefik no se configura automáticamente, agregar labels manualmente:**
   ```bash
   docker service update \
     --label-add "traefik.enable=true" \
     --label-add "traefik.http.routers.crm.rule=Host(\`crm.checkin24hs.com\`)" \
     --label-add "traefik.http.routers.crm.entrypoints=web" \
     --label-add "traefik.http.services.crm.loadbalancer.server.port=3000" \
     crm
   ```

### 4. Remover del dashboard principal (opcional)

Una vez que el CRM esté funcionando, puedes remover del `dashboard.html`:
- Las pestañas de Interacciones, Chats y Flor IA del menú
- Las secciones HTML correspondientes
- El JavaScript relacionado (opcional, no afecta si está)

### 5. Archivos necesarios

Asegúrate de tener en el mismo directorio que `crm.html`:
- `supabase-client.js`
- `supabase-config.js`
- `logo.png` o logos SVG
- Cualquier otro recurso estático necesario

## Ventajas

✅ Dashboard principal funcionará sin errores  
✅ CRM será independiente y fácil de mantener  
✅ Errores en CRM no afectarán el dashboard  
✅ Más fácil de depurar y actualizar  

## Próximos Pasos

1. Crear el archivo `crm.html` completo con las secciones extraídas
2. Subir `crm.html` y `serve-crm.js` al servidor
3. Configurar el servicio en EasyPanel
4. Probar acceso a `crm.checkin24hs.com`

¿Quieres que proceda a crear el archivo `crm.html` completo ahora?


