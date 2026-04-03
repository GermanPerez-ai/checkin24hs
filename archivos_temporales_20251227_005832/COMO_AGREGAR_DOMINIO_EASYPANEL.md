# Cómo Agregar/Configurar Dominio en EasyPanel

## Veo que Ya Tienes el Dominio Configurado

En la imagen veo que `dashboard.checkin24hs.com` ya está en la lista de dominios. 

## Verificar/Actualizar la Configuración del Dominio

### Si el Dominio Ya Está Agregado:

1. **En la lista de dominios**, busca `dashboard.checkin24hs.com`
2. **Haz clic en el icono de lápiz** (pencil/edit) al lado del dominio
3. **Verifica la configuración**:
   - **Host**: `dashboard.checkin24hs.com` ✅
   - **Ruta**: `/` ✅
   - **Protocolo**: `HTTP` ✅
   - **Puerto**: `80` ✅
   - **Ruta destino**: `/` ✅
4. **Haz clic en "Guardar"** (botón verde)

### Si Necesitas Agregar un Nuevo Dominio:

1. **En la sección "Dominios"**, busca el botón **"Agregar dominio"** (al final de la lista)
2. **Haz clic en "Agregar dominio"**
3. **Se abrirá un modal** con los siguientes campos:
   - **Host**: Ingresa `dashboard.checkin24hs.com`
   - **Ruta**: `/` (dejar por defecto)
   - **Protocolo**: `HTTP` (o HTTPS si tienes SSL)
   - **Puerto**: `80` (o el puerto que use el servicio)
   - **Ruta destino**: `/` (dejar por defecto)
4. **Haz clic en "Guardar"** (botón verde)

## Configuración Recomendada

Para el dominio `dashboard.checkin24hs.com`:

- **Host**: `dashboard.checkin24hs.com`
- **Ruta**: `/`
- **Protocolo**: `HTTP` (o HTTPS si configuras SSL)
- **Puerto**: `80` (Traefik escucha en 80 y enruta al servicio)
- **Ruta destino**: `/`

## Después de Guardar

1. **Espera 1-2 minutos** para que Traefik actualice la configuración
2. **Intenta acceder**: http://dashboard.checkin24hs.com
3. **El dashboard debería aparecer sin login**

## Verificar que Funciona

Si después de guardar el dominio no funciona:

1. **Verifica que Traefik esté corriendo**:
   ```bash
   docker service ls | grep traefik
   docker ps | grep traefik
   ```

2. **Verifica los logs de Traefik**:
   ```bash
   docker service logs traefik --tail 50
   ```

3. **Verifica que el servicio dashboard esté corriendo**:
   ```bash
   docker service ps checkin24hs_dashboard
   ```

## Notas Importantes

- El puerto `80` es el puerto de Traefik (proxy), no el puerto del servicio
- Traefik enruta automáticamente al servicio correcto
- EasyPanel gestiona Traefik automáticamente cuando agregas dominios
- El dominio debe estar guardado y activo en EasyPanel


