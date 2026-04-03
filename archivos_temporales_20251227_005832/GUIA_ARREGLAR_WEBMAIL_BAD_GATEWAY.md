# 🔧 Guía: Arreglar Webmail - Bad Gateway (502)

## 📍 Problema

El error **Bad Gateway (502)** en `webmail.checkin24hs.com` significa que:
- ✅ Nginx está funcionando (por eso responde)
- ✅ El dominio está configurado correctamente
- ❌ El contenedor de Roundcube NO está corriendo o no es accesible

## 🎯 Solución Paso a Paso

### Paso 1: Verificar Recursos en EasyPanel

1. **Abre EasyPanel** en tu navegador
2. Ve a: **Proyecto "checkin24hs"** → **Servicio "webmail"**
3. Haz clic en **"Recursos"** (menú lateral)
4. Verifica estos valores:

   ```
   Reserva de memoria: 512 MB (mínimo)
   Límite de memoria: 1024 MB (recomendado)
   Reserva de CPU: 0.5 (mínimo)
   Límite de CPU: 1.0 (recomendado)
   ```

5. **⚠️ IMPORTANTE**: Si están en **0** o muy bajos, **CÁMBIALOS**
6. **Guarda** los cambios

---

### Paso 2: Verificar Dominio y Puerto

1. Haz clic en **"Dominios"** (menú lateral)
2. Busca: `webmail.checkin24hs.com`
3. Haz clic en el dominio para editarlo
4. Verifica el **PUERTO**:

   **⚠️ CRÍTICO**: El puerto debe ser **80** (puerto INTERNO)
   **❌ NO debe ser 8080** (ese es el externo)

5. Si el puerto es **8080**, cámbialo a **80**
6. **Guarda** los cambios

#### 🔍 Explicación Técnica

En Docker/EasyPanel:
- **Puerto interno**: Donde el contenedor escucha (Apache usa `80`)
- **Puerto externo**: Donde Nginx se conecta (puede ser `8080`, `3000`, etc.)
- **En "Dominios"**: Debes usar el puerto **INTERNO** (`80`)

EasyPanel maneja el mapeo automáticamente, pero la configuración del dominio debe apuntar al puerto interno.

---

### Paso 3: Verificar Variables de Entorno

1. Haz clic en **"Entorno"** (menú lateral)
2. Verifica que tengas estas variables:

   ```env
   ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
   ROUNDCUBEMAIL_DEFAULT_PORT=993
   ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
   ROUNDCUBEMAIL_SMTP_PORT=587
   ROUNDCUBEMAIL_PLUGINS=archive,zipdownload
   ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE=5M
   ```

3. Si faltan, **agrégalas**
4. **Guarda** los cambios

---

### Paso 4: Verificar Fuente (Docker Image)

1. Haz clic en **"Fuente"** (menú lateral)
2. Verifica que la imagen sea:

   ```
   roundcube/roundcubemail:1.6.11-apache
   ```

3. Si está correcta, **no cambies nada**

---

### Paso 5: Ver los Logs

1. En la sección **"Registros"** (abajo), haz clic en **"Actualizar registros"**
2. O haz clic en el icono de **refresh** (flecha circular)
3. Revisa los últimos mensajes buscando:

   - ❌ `Killed` → Problema de memoria
   - ❌ `Out of memory` → Falta de memoria
   - ❌ `Port already in use` → Conflicto de puertos
   - ❌ `Cannot bind` → Puerto en uso
   - ❌ `502 Bad Gateway` → Nginx no puede conectar

4. Si encuentras alguno de estos errores, anótalo

---

### Paso 6: Implementar el Servicio

Una vez que hayas verificado y ajustado:

- ✅ Recursos (memoria suficiente)
- ✅ Dominio (puerto 80)
- ✅ Variables de entorno
- ✅ Fuente (imagen Docker correcta)

1. Haz clic en el botón verde **"Implementar"**
2. Espera **1-2 minutos**
3. Observa los logs para ver el progreso
4. El punto debe cambiar de **ROJO** a **VERDE**

---

## 🔧 Soluciones Específicas por Error

### Si el servicio está en ROJO (detenido)

1. Verifica que los **Recursos NO estén en 0**
2. Verifica que el **Dominio tenga puerto 80**
3. Haz clic en el botón verde **"Implementar"**
4. Espera 1-2 minutos
5. Observa los logs para ver el progreso
6. El punto debe cambiar de **ROJO** a **VERDE**

---

### Si el servicio está en VERDE pero sigue 502

1. Ve a **"Dominios"** → `webmail.checkin24hs.com`
2. Verifica que el puerto sea **80** (NO 8080)
3. Si es 8080, **cámbialo a 80**
4. **Guarda** los cambios
5. Espera **10-15 segundos**
6. Actualiza la página del webmail (**F5**)

---

### Si el log muestra "Killed" o "Out of memory"

**Causa**: Falta de memoria

**Solución**:
1. Ve a **"Recursos"**
2. Aumenta la memoria:
   - **Límite de memoria**: `2048` MB (2 GB)
3. **Guarda** los cambios
4. Haz clic en **"Implementar"**

---

### Si el log muestra "Port already in use"

**Causa**: Conflicto de puertos

**Solución**:
1. Ve a **"Dominios"**
2. Cambia el puerto a `8081` o `8082`
3. **Guarda** los cambios
4. Haz clic en **"Implementar"**

---

## ✅ Checklist Completo

Antes de hacer clic en "Implementar", verifica:

- [ ] **Recursos**: Memoria al menos 512 MB (mejor 1024 MB)
- [ ] **Recursos**: CPU al menos 0.5 (mejor 1.0)
- [ ] **Dominio**: Puerto configurado en **80** (NO 8080)
- [ ] **Variables de entorno**: Todas configuradas
- [ ] **Fuente**: Imagen Docker correcta
- [ ] **Logs**: Revisados para entender errores previos

---

## 🚀 Orden de Acción Recomendado

Sigue este orden exacto:

1. ✅ Ve a **"Recursos"** → Aumenta memoria a 1024 MB → **Guarda**
2. ✅ Ve a **"Dominios"** → Verifica/cambia puerto a **80** → **Guarda**
3. ✅ Ve a **"Entorno"** → Verifica variables → **Guarda**
4. ✅ Haz clic en **"Implementar"** (botón verde)
5. ✅ Espera **1-2 minutos**
6. ✅ Observa los logs y espera a que el punto cambie a **VERDE**
7. ✅ Intenta acceder a: `https://webmail.checkin24hs.com`

---

## 🔍 Verificación Final

Después de implementar:

- ✅ El punto junto a "webmail" debe estar **VERDE**
- ✅ Los recursos deben mostrar valores **> 0%**
- ✅ Al acceder a `webmail.checkin24hs.com` debe aparecer **Roundcube**
- ✅ **NO** debe aparecer "Bad Gateway" o "502"

---

## 📋 Resumen

El error Bad Gateway (502) generalmente se debe a:

1. ❌ **Servicio detenido** (punto rojo)
   → Solución: Configurar recursos y hacer clic en "Implementar"

2. ❌ **Puerto incorrecto en "Dominios"** (8080 en lugar de 80)
   → Solución: Cambiar puerto a 80 en "Dominios"

3. ❌ **Falta de memoria** (recursos en 0)
   → Solución: Aumentar memoria a 1024 MB mínimo

Una vez que el servicio esté en **VERDE** y el puerto sea **80**, el error Bad Gateway debería desaparecer.

---

## 🆘 Si Sigue Sin Funcionar

1. Ve a **"Registros"** y haz clic en **"Actualizar registros"**
2. Copia los últimos **50-100 líneas** de logs
3. Busca específicamente:
   - Mensajes de error
   - "Killed"
   - "Out of memory"
   - "Port"
   - "502"

Con esa información podremos identificar el problema exacto.

---

## 💡 Nota Importante

El error 502 en el navegador confirma que:
- ✅ La configuración de Nginx está correcta
- ✅ El dominio está funcionando
- ❌ Solo falta que el contenedor de Roundcube esté corriendo

Una vez que el servicio esté en **VERDE** en EasyPanel, el error 502 desaparecerá.



