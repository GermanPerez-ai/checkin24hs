# 🔧 Solución: Contenedor "Killed" en EasyPanel

## 🚨 Problema Detectado

El contenedor de webmail se está iniciando pero se mata ("Killed") inmediatamente después. Esto puede deberse a:

1. **Memoria insuficiente** en el servidor
2. **Conflicto de puertos** (otro servicio usando el mismo puerto)
3. **Configuración incorrecta** del contenedor
4. **Límites de recursos** muy bajos

## 🎯 Soluciones Paso a Paso

### Solución 1: Verificar y Aumentar Recursos

1. En la configuración de **webmail**, busca la sección:
   - **"Resources"** o **"Recursos"**
   - **"Limits"** o **"Límites"**
   - **"Memory"** o **"Memoria"**

2. Verifica los límites de memoria:
   - Debe ser al menos **512 MB** o **1024 MB** (1 GB)
   - Si está en 128 MB o menos, auméntalo

3. Si no encuentras esta opción, busca en:
   - **"Settings"** o **"Configuración"**
   - **"Advanced"** o **"Avanzado"**

### Solución 2: Verificar Conflictos de Puertos

1. En la configuración de **webmail**, busca **"Ports"** o **"Puertos"**
2. Verifica qué puerto está configurado (ej: `80`, `8080`)
3. Ve a **"roundcube"** y verifica su puerto
4. **Asegúrate de que NO usen el mismo puerto**

**Si ambos usan el mismo puerto:**
- Cambia el puerto de uno de ellos (ej: webmail usa `8080`, roundcube usa `8081`)
- O elimina uno de los servicios si no necesitas ambos

### Solución 3: Verificar Variables de Entorno

1. En **webmail**, ve a **"Variables de entorno"**
2. Verifica que todas las variables estén correctas
3. Asegúrate de que no haya espacios extra o caracteres especiales

**Variables mínimas necesarias:**
```env
ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
ROUNDCUBEMAIL_DEFAULT_PORT=993
ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
ROUNDCUBEMAIL_SMTP_PORT=587
```

### Solución 4: Ver Logs Detallados

1. Haz clic en el icono de **terminal** (`>_`) en webmail
2. O busca la sección **"Logs"** o **"Registros"**
3. Ejecuta o busca:

```bash
docker logs webmail --tail 100
# O
docker logs checkin24hs-webmail --tail 100
```

4. Busca errores específicos como:
   - `Out of memory`
   - `Port already in use`
   - `Cannot bind to port`
   - `Permission denied`

### Solución 5: Reiniciar con Configuración Mínima

1. **Detén el servicio** (botón stop)
2. **Elimina las variables de entorno** temporalmente (o déjalas mínimas)
3. **Configura un puerto específico** (ej: `8080`)
4. **Aumenta la memoria** a al menos 512 MB
5. **Haz clic en "Implementar"** de nuevo

### Solución 6: Usar Solo Un Servicio

Si tienes **roundcube** y **webmail** ambos corriendo:
- Pueden estar compitiendo por recursos
- Considera **eliminar uno** y usar solo el otro
- O configura puertos diferentes para cada uno

## 🔍 Diagnóstico Rápido

### Verificar Recursos del Servidor

1. En EasyPanel, busca **"Dashboard"** o **"Panel Principal"**
2. Revisa el uso de recursos:
   - **Memoria total disponible**
   - **Memoria usada**
   - **CPU disponible**

3. Si la memoria está al 90%+, el servidor puede estar matando contenedores

### Verificar Contenedores Corriendo

1. Haz clic en el icono de **terminal** (`>_`) en cualquier servicio
2. Ejecuta:

```bash
docker ps -a
```

3. Busca contenedores que estén:
   - `Exited` (salidos)
   - `Restarting` (reiniciándose constantemente)
   - `Dead` (muertos)

## ✅ Configuración Recomendada para Webmail

### Recursos Mínimos:
- **Memoria**: 512 MB (mejor 1024 MB)
- **CPU**: 0.5 cores (mejor 1 core)

### Puertos:
- **Puerto interno**: `80` (puerto por defecto de Apache en Roundcube)
- **Puerto externo**: `8080` o `8081` (diferente al de roundcube)

### Variables de Entorno Mínimas:
```env
ROUNDCUBEMAIL_DEFAULT_HOST=mail.checkin24hs.com
ROUNDCUBEMAIL_DEFAULT_PORT=993
ROUNDCUBEMAIL_SMTP_SERVER=mail.checkin24hs.com
ROUNDCUBEMAIL_SMTP_PORT=587
```

## 🆘 Si Nada Funciona

1. **Elimina el servicio webmail** (botón de basura)
2. **Crea un nuevo servicio** con el mismo nombre
3. **Configura desde cero** con:
   - Memoria: 1024 MB
   - Puerto: 8080
   - Variables de entorno mínimas
4. **Haz clic en "Implementar"**

## 📋 Checklist

- [ ] Verifiqué los límites de memoria (mínimo 512 MB)
- [ ] Verifiqué que no haya conflicto de puertos
- [ ] Revisé las variables de entorno
- [ ] Verifiqué los logs detallados
- [ ] Verifiqué los recursos disponibles del servidor
- [ ] Consideré eliminar uno de los servicios duplicados (roundcube/webmail)

