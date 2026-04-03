# 🔍 Verificar Evolution API desde EasyPanel

## 📋 Pasos para Verificar en EasyPanel

### Paso 1: Acceder a EasyPanel
1. Abre tu navegador
2. Ve a la URL de EasyPanel (ej: `http://TU_IP:3000` o el dominio que uses)
3. Inicia sesión

### Paso 2: Encontrar el Contenedor
1. Ve a la sección **"Containers"** o **"Services"** o **"Docker"**
2. Busca el contenedor llamado:
   - `evolution-api-checkin24hs`
   - O busca por "evolution"

### Paso 3: Ver Logs
1. Haz clic en el contenedor `evolution-api-checkin24hs`
2. Busca la pestaña o botón **"Logs"** o **"View Logs"**
3. Haz clic para ver los logs

### Paso 4: Verificar Estado
En la vista del contenedor deberías ver:
- **Estado**: Running (verde) o Restarting (amarillo) o Stopped (rojo)
- **Puertos**: Debería mostrar `8080:8080`
- **Última actualización**: Fecha/hora

---

## 🔍 Qué Buscar en los Logs

### ✅ Si está funcionando correctamente:
Deberías ver mensajes como:
- "Evolution API started"
- "Server listening on port 8080"
- "Redis connected"
- "Application ready"

### ❌ Si hay errores:
Busca palabras como:
- "Error"
- "Failed"
- "Exception"
- "Cannot"
- "Connection refused"

---

## 📋 Información que Necesito

Por favor, comparte:

1. **Estado del contenedor**: ¿Running, Restarting, o Stopped?
2. **Últimas 20-30 líneas de los logs**: Copia y pega aquí
3. **Puertos mapeados**: ¿Muestra `8080:8080`?
4. **Cualquier error**: Si ves errores en rojo, cópialos

---

## 🔧 Si el Contenedor Está "Restarting"

Si el estado es "Restarting" (reiniciándose constantemente):

1. **Detener el contenedor**:
   - Haz clic en el contenedor
   - Busca el botón **"Stop"** o **"Pause"**
   - Detén el contenedor

2. **Ver logs completos**:
   - Con el contenedor detenido, los logs mostrarán el error completo
   - Copia los últimos 50-100 líneas

3. **Comparte los logs** para que pueda ayudarte a solucionarlo

---

## 🔧 Si el Contenedor Está "Stopped"

1. **Ver logs**:
   - Haz clic en el contenedor
   - Ve a "Logs"
   - Los logs mostrarán por qué se detuvo

2. **Reiniciar**:
   - Haz clic en **"Start"** o **"Restart"**
   - Espera unos segundos
   - Vuelve a ver los logs

---

## ✅ Verificar que Funciona

Una vez que veas los logs, intenta:

1. **Desde EasyPanel**:
   - Busca un botón **"Open"** o **"Access"** o **"Web Terminal"**
   - O ve a la sección de terminal/web shell

2. **Probar la conexión**:
   ```bash
   curl http://localhost:8080
   ```

3. **O desde tu navegador**:
   - Abre: `http://TU_IP_SERVIDOR:8080`
   - Deberías ver una página de Evolution API

---

## 📸 Capturas Útiles

Si puedes, toma capturas de pantalla de:
1. El estado del contenedor en EasyPanel
2. Los logs (especialmente si hay errores)
3. La configuración de puertos

---

## 🆘 Si No Encuentras el Contenedor

1. **Verificar que se creó**:
   - Ve a "Containers" → "All Containers"
   - Busca por "evolution" o "checkin24hs"

2. **Si no existe**:
   - Puede que no se haya creado correctamente
   - Vuelve a ejecutar: `docker-compose up -d` desde SSH
   - Espera unos segundos y refresca EasyPanel

---

## 📞 Siguiente Paso

Una vez que veas los logs en EasyPanel:
1. **Copia las últimas 30-50 líneas**
2. **Comparte el estado del contenedor**
3. **Comparte cualquier error que veas**

Con esa información podré ayudarte a solucionar el problema.


