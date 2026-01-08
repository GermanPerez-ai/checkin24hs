# 🚨 Plan de Acción: Si el Deploy No Funciona

## 📋 Escenario: Desplegaste la corrección pero el error persiste

### 🔍 Paso 1: Verificar que el Deploy se Completó

1. **Verifica en EasyPanel:**
   - Ve a tu proyecto en EasyPanel
   - Revisa el historial de deploys
   - Confirma que el último deploy se completó exitosamente
   - Verifica la fecha/hora del último deploy

2. **Verifica en el servidor:**
   ```bash
   # Conectarte al servidor
   ssh usuario@tu-servidor
   
   # Verificar el contenedor
   docker ps | grep dashboard
   
   # Verificar la fecha del archivo
   docker exec checkin24hs-dashboard-1 ls -lh /usr/share/nginx/html/dashboard.html
   ```

### 🔍 Paso 2: Verificar que el Código Correcto Está en el Servidor

1. **Verificar la corrección en el servidor:**
   ```bash
   # Buscar la corrección en el archivo del servidor
   docker exec checkin24hs-dashboard-1 grep -n "window\.saveHotelChanges = window\.saveHotelChanges ||" /usr/share/nginx/html/dashboard.html
   ```

2. **Si NO encuentra la corrección:**
   - El deploy no se aplicó correctamente
   - Usa el script `aplicar_correccion_savehotelchanges_servidor.sh` para aplicar los cambios directamente

### 🔍 Paso 3: Aplicar Corrección Directamente en el Servidor

**Opción A: Usar el Script Automático**

1. **Conectarte al servidor:**
   ```bash
   ssh usuario@tu-servidor
   ```

2. **Ejecutar el script:**
   ```bash
   # Copiar el script al servidor primero
   scp aplicar_correccion_savehotelchanges_servidor.sh usuario@tu-servidor:/tmp/
   
   # O crear el script directamente en el servidor
   nano aplicar_correccion_savehotelchanges_servidor.sh
   # (pegar el contenido del script)
   
   # Dar permisos de ejecución
   chmod +x aplicar_correccion_savehotelchanges_servidor.sh
   
   # Ejecutar
   ./aplicar_correccion_savehotelchanges_servidor.sh
   ```

**Opción B: Aplicar Manualmente**

1. **Descargar el archivo desde GitHub:**
   ```bash
   curl -o /tmp/dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
   ```

2. **Copiar al contenedor:**
   ```bash
   docker cp /tmp/dashboard.html checkin24hs-dashboard-1:/usr/share/nginx/html/dashboard.html
   ```

3. **Reiniciar el contenedor:**
   ```bash
   docker restart checkin24hs-dashboard-1
   ```

### 🔍 Paso 4: Verificar que la Corrección Funcionó

1. **En el navegador:**
   - Abre `https://dashboard.checkin24hs.com`
   - Presiona **Ctrl+F5** (o Cmd+Shift+R en Mac) para limpiar caché
   - Abre la consola (F12)
   - Verifica que NO haya el error `Identifier 'saveHotelChanges' has already been declared`

2. **En la consola del navegador:**
   ```javascript
   // Verificar que la función existe
   typeof window.saveHotelChanges
   // Debe retornar: "function"
   
   // Verificar que solo hay una declaración
   // (no debería haber errores en la consola)
   ```

### 🔍 Paso 5: Si el Error Persiste

**Diagnóstico Adicional:**

1. **Verificar múltiples declaraciones:**
   ```bash
   # En el servidor
   docker exec checkin24hs-dashboard-1 grep -n "function saveHotelChanges\|async function saveHotelChanges\|window\.saveHotelChanges" /usr/share/nginx/html/dashboard.html
   ```

2. **Verificar el orden de carga:**
   - Abre la consola del navegador (F12)
   - Ve a la pestaña "Network"
   - Recarga la página
   - Verifica que `dashboard.html` se carga correctamente
   - Verifica que no hay errores 404 o 500

3. **Verificar caché del navegador:**
   - Abre el dashboard en modo incógnito
   - O limpia completamente el caché del navegador
   - O usa `Ctrl+Shift+Delete` para limpiar caché

4. **Verificar caché del servidor/CDN:**
   - Si usas un CDN (Cloudflare, etc.), purga el caché
   - Si usas Nginx con caché, reinicia Nginx

### 🔍 Paso 6: Verificar Logs del Contenedor

```bash
# Ver logs del contenedor
docker logs checkin24hs-dashboard-1 --tail 50

# Ver logs en tiempo real
docker logs -f checkin24hs-dashboard-1
```

### 🔍 Paso 7: Verificar Configuración de EasyPanel

1. **Verificar la rama configurada:**
   - En EasyPanel, verifica que esté configurada la rama `main`
   - Verifica que el build path sea correcto

2. **Forzar un nuevo deploy:**
   - Cambia temporalmente a otra rama
   - Guarda los cambios
   - Vuelve a cambiar a `main`
   - Guarda los cambios
   - Esto debería forzar un nuevo build

### 🔍 Paso 8: Solución de Último Recurso

Si nada funciona, puedes:

1. **Restaurar desde backup:**
   ```bash
   # Si creaste un backup antes
   docker exec checkin24hs-dashboard-1 cp /tmp/dashboard_backup_*.html /usr/share/nginx/html/dashboard.html
   docker restart checkin24hs-dashboard-1
   ```

2. **Clonar el repositorio directamente:**
   ```bash
   # En el servidor
   cd /tmp
   git clone https://github.com/GermanPerez-ai/checkin24hs.git
   docker cp checkin24hs/dashboard.html checkin24hs-dashboard-1:/usr/share/nginx/html/dashboard.html
   docker restart checkin24hs-dashboard-1
   ```

---

## 📋 Checklist de Verificación

- [ ] El deploy en EasyPanel se completó exitosamente
- [ ] El archivo en el servidor tiene la corrección (`window.saveHotelChanges = window.saveHotelChanges ||`)
- [ ] El contenedor se reinició después de aplicar los cambios
- [ ] Limpié el caché del navegador (Ctrl+F5)
- [ ] Verifiqué la consola del navegador (F12) y no hay errores
- [ ] La función `window.saveHotelChanges` existe (verificado en consola)
- [ ] Intenté iniciar sesión y funciona correctamente

---

## 🆘 Si Nada Funciona

1. **Contacta con soporte:**
   - Proporciona los logs del contenedor
   - Proporciona capturas de pantalla de los errores
   - Proporciona la versión del código que está en el servidor

2. **Revisa el código manualmente:**
   - Descarga el archivo del servidor
   - Compara con el archivo en GitHub
   - Identifica las diferencias

3. **Considera un rollback:**
   - Si el problema es crítico, restaura una versión anterior
   - Identifica qué cambio causó el problema
   - Aplica una solución más específica

---

## 💡 Prevención Futura

Para evitar este problema en el futuro:

1. **Siempre usa `window.functionName = window.functionName ||`** para funciones globales
2. **Verifica que no haya declaraciones duplicadas** antes de hacer commit
3. **Prueba localmente** antes de desplegar
4. **Mantén backups** antes de hacer cambios importantes
5. **Usa scripts de verificación** para detectar problemas antes del deploy

