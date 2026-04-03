# 🐳 Instrucciones para Limpiar Sesión de WhatsApp en Docker

## Método 1: Usando el Script (Recomendado)

### Windows PowerShell:
```powershell
cd whatsapp-server
.\limpiar_docker.ps1
```

### Linux/Mac:
```bash
cd whatsapp-server
chmod +x limpiar_docker.sh
./limpiar_docker.sh
```

## Método 2: Comandos Manuales

### Paso 1: Listar contenedores
```bash
docker ps -a
```

Busca el nombre de tu contenedor de WhatsApp (puede ser `whatsapp-server`, `whatsapp-flor`, etc.)

### Paso 2: Detener el contenedor
```bash
docker stop NOMBRE_DEL_CONTENEDOR
```

### Paso 3: Eliminar la sesión
```bash
docker exec NOMBRE_DEL_CONTENEDOR rm -rf .wwebjs_auth
```

Si el contenedor está detenido, puedes montarlo temporalmente:
```bash
docker run --rm -v NOMBRE_DEL_CONTENEDOR:/data alpine sh -c "rm -rf /data/.wwebjs_auth"
```

O mejor aún, si tienes un volumen nombrado:
```bash
docker volume ls  # Ver volúmenes
docker run --rm -v NOMBRE_DEL_VOLUMEN:/data alpine sh -c "rm -rf /data/.wwebjs_auth"
```

### Paso 4: Reiniciar el contenedor
```bash
docker start NOMBRE_DEL_CONTENEDOR
```

### Paso 5: Ver logs para confirmar que muestra el QR
```bash
docker logs -f NOMBRE_DEL_CONTENEDOR
```

## Método 3: Si usas Docker Compose

```bash
# Detener
docker-compose stop whatsapp

# Eliminar sesión
docker-compose exec whatsapp rm -rf .wwebjs_auth

# O si está detenido, usar run
docker-compose run --rm whatsapp rm -rf .wwebjs_auth

# Reiniciar
docker-compose start whatsapp

# Ver logs
docker-compose logs -f whatsapp
```

## Método 4: Eliminar y Recrear el Contenedor

Si nada funciona, puedes eliminar y recrear el contenedor (la sesión se perderá):

```bash
# Detener y eliminar
docker stop NOMBRE_DEL_CONTENEDOR
docker rm NOMBRE_DEL_CONTENEDOR

# Recrear (ajusta según tu configuración)
docker run -d \
  --name whatsapp-server \
  -p 3001:3001 \
  -v whatsapp-data:/app \
  tu-imagen-whatsapp

# Ver logs
docker logs -f whatsapp-server
```

## Verificar que Funciona

Después de reiniciar, deberías ver en los logs:

```
📱 Escanea el código QR con WhatsApp:
WhatsApp > Dispositivos vinculados > Vincular dispositivo
```

Si ves esto, el servidor está listo para escanear el QR.

## Notas Importantes

- ⚠️ **Eliminar `.wwebjs_auth`** hará que necesites escanear el QR nuevamente
- ✅ La sesión se guarda en el contenedor o en un volumen Docker
- 🔄 Reiniciar el contenedor aplica los cambios
- 📱 El QR aparecerá en los logs del contenedor

