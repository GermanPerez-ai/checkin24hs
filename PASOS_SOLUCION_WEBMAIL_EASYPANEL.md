# 🔧 Pasos para Solucionar Webmail en EasyPanel

## 📸 Estado Actual

Veo que **webmail** está:
- ❌ **Punto rojo** (detenido/error)
- 📊 **Recursos en 0%** (no está corriendo)
- 🔴 **Servicio no activo**

## 🎯 Plan de Acción Paso a Paso

### Paso 1: Verificar Recursos

1. En el menú lateral, haz clic en **"Recursos"**
2. Verifica la configuración de:
   - **Memoria** (debe ser al menos 512 MB, mejor 1024 MB)
   - **CPU** (debe ser al menos 0.5, mejor 1.0)
3. Si están muy bajos, **auméntalos**
4. **Guarda los cambios**

### Paso 2: Verificar Dominios

1. En el menú lateral, haz clic en **"Dominios"**
2. Verifica que haya un dominio configurado:
   - `webmail.checkin24hs.com`
3. Si existe, haz clic en él para editarlo
4. Verifica que el **puerto** sea `8080` (NO 80)
5. Si el puerto es 80, cámbialo a 8080
6. **Guarda los cambios**

### Paso 3: Verificar Variables de Entorno

1. En el menú lateral, haz clic en **"Entorno"**
2. Verifica que tengas estas variables:

```env
ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
ROUNDCUBEMAIL_DEFAULT_PORT=993
ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
ROUNDCUBEMAIL_SMTP_PORT=587
ROUNDCUBEMAIL_PLUGINS=archive,zipdownload
ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE=5M
```

3. Si faltan, agrégalas
4. **Guarda los cambios**

### Paso 4: Ver los Logs

1. En la sección **"Registros"** (abajo), haz clic en el botón **"Actualizar registros"**
2. O haz clic en el icono de **refresh** (flecha circular)
3. Revisa los últimos mensajes
4. Busca errores específicos que indiquen la causa

### Paso 5: Verificar la Fuente (Docker Image)

1. En el menú lateral, haz clic en **"Fuente"**
2. Verifica que la imagen sea:
   - `roundcube/roundcubemail:1.6.11-apache`
3. Si está correcta, no cambies nada

### Paso 6: Desplegar el Servicio

1. Una vez que hayas verificado y ajustado:
   - ✅ Recursos (memoria suficiente)
   - ✅ Dominio (puerto 8080)
   - ✅ Variables de entorno
2. Haz clic en el botón verde **"Implementar"**
3. Espera 1-2 minutos
4. Observa los logs para ver el progreso

## 🔍 Diagnóstico Detallado

### Si el Servicio Sigue Matándose

1. Ve a **"Recursos"** y verifica:
   - **Memoria**: Mínimo 512 MB (mejor 1024 MB)
   - Si está en 128 MB o menos, ese es el problema

2. Ve a **"Dominios"** y verifica:
   - El puerto NO sea 80 (debe ser 8080 u otro)
   - El protocolo sea HTTP

3. Ve a **"Registros"** y busca:
   - `Out of memory`
   - `Port already in use`
   - `Cannot bind to port`
   - `Killed`

### Verificar Conflicto con Roundcube

1. Ve a **"roundcube"** en la lista de servicios
2. Haz clic en **"Dominios"**
3. Verifica qué puerto está usando
4. **Asegúrate de que webmail y roundcube NO usen el mismo puerto**

## ✅ Checklist Completo

Antes de hacer clic en "Implementar", verifica:

- [ ] **Recursos**: Memoria al menos 512 MB
- [ ] **Dominio**: Puerto configurado (8080, NO 80)
- [ ] **Variables de entorno**: Todas las necesarias están configuradas
- [ ] **Fuente**: Imagen Docker correcta
- [ ] **Sin conflictos**: roundcube y webmail usan puertos diferentes
- [ ] **Logs**: Revisados para entender errores previos

## 🚀 Orden de Acción Recomendado

1. **Primero**: Ve a "Recursos" → Aumenta memoria a 1024 MB → Guarda
2. **Segundo**: Ve a "Dominios" → Verifica/cambia puerto a 8080 → Guarda
3. **Tercero**: Ve a "Entorno" → Verifica variables → Guarda
4. **Cuarto**: Haz clic en "Implementar"
5. **Quinto**: Observa los logs y espera 1-2 minutos

## 🆘 Si Sigue Fallando

1. Ve a **"Registros"** y haz clic en **"Actualizar registros"**
2. Copia los últimos 50-100 líneas de logs
3. Busca específicamente:
   - Mensajes de error
   - "Killed"
   - "Out of memory"
   - "Port"

Con esa información podremos identificar el problema exacto.

