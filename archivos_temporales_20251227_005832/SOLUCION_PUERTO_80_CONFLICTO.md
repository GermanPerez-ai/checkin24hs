# 🔧 Solución: Conflicto de Puerto 80

## 📸 Basado en tu Configuración

Veo que **webmail** está configurado para usar el puerto **80** en el destino. Este es el puerto por defecto de HTTP y puede estar causando conflictos.

## 🎯 Problema Identificado

El contenedor se mata ("Killed") probablemente porque:
1. **El puerto 80 ya está en uso** por otro servicio (nginx, roundcube, etc.)
2. **Falta de recursos** (memoria insuficiente)
3. **Permisos insuficientes** para usar el puerto 80

## ✅ Solución Inmediata

### Opción 1: Cambiar el Puerto del Contenedor (Recomendado)

1. **Cierra el modal** de "Actualizar dominio" (por ahora)
2. En la configuración de **webmail**, busca:
   - **"Ports"** o **"Puertos"**
   - **"Network"** o **"Red"**
   - **"Exposed Ports"** o **"Puertos Expuestos"**

3. **Cambia el puerto interno del contenedor** de `80` a otro puerto:
   - `8080` (recomendado)
   - `8081`
   - `3000`

4. **Luego vuelve a "Actualizar dominio"** y cambia:
   - **Puerto**: de `80` a `8080` (o el puerto que elegiste)

### Opción 2: Verificar qué está usando el Puerto 80

1. Haz clic en el icono de **terminal** (`>_`) en cualquier servicio
2. Ejecuta:

```bash
sudo netstat -tulpn | grep :80
# O
sudo ss -tulpn | grep :80
```

3. Esto te mostrará qué servicio está usando el puerto 80
4. Si es **roundcube** o **nginx**, necesitas cambiar el puerto de webmail

### Opción 3: Configuración Correcta

En el modal "Actualizar dominio", la configuración debería ser:

**Si el contenedor usa puerto interno 8080:**
- **Protocolo**: HTTP
- **Puerto**: `8080` (NO 80)
- **Ruta**: `/`

**Si el contenedor usa puerto interno 80 pero hay conflicto:**
- Cambia el puerto interno del contenedor a `8080` primero
- Luego en el dominio usa puerto `8080`

## 🔍 Verificar Puerto del Contenedor

1. En la configuración de **webmail**, busca la sección de **"Ports"**
2. Verifica qué puerto está configurado para el contenedor
3. Debe ser algo como:
   - `80:80` (puerto externo:puerto interno)
   - O solo `80` (puerto interno)

## 📋 Pasos Completos

1. ✅ **Cierra el modal** "Actualizar dominio"
2. ✅ **Ve a la configuración de Ports** en webmail
3. ✅ **Cambia el puerto interno** de `80` a `8080`
4. ✅ **Guarda los cambios**
5. ✅ **Vuelve a "Actualizar dominio"**
6. ✅ **Cambia el puerto de destino** de `80` a `8080`
7. ✅ **Guarda**
8. ✅ **Haz clic en "Implementar"**

## 🆘 Si No Encuentras la Configuración de Puertos

1. En la configuración de webmail, busca todas las pestañas:
   - **"Imagen Docker"**
   - **"Variables de entorno"**
   - **"Ports"** o **"Network"**
   - **"Settings"** o **"Configuración"**

2. O haz clic en el icono de **terminal** (`>_`) y ejecuta:

```bash
docker inspect webmail | grep -i port
# O
docker inspect checkin24hs-webmail | grep -i port
```

## 💡 Nota Importante

Si **roundcube** también está usando el puerto 80:
- **Solo uno puede usar el puerto 80**
- Cambia webmail a `8080` y roundcube puede quedarse en `80`
- O viceversa

## ✅ Configuración Final Recomendada

**Webmail:**
- Puerto interno del contenedor: `80` (interno de Apache)
- Puerto externo/mapeo: `8080`
- En "Actualizar dominio": Puerto `8080`

**Roundcube:**
- Si está en puerto `80`, déjalo así
- O cámbialo a otro puerto si prefieres

