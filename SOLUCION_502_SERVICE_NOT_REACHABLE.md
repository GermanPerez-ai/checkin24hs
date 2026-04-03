# 🔧 Solución: Error 502 - Service is not reachable

## 🚨 Problema Identificado

Aunque los logs muestran que Apache está corriendo, Nginx no puede conectarse al contenedor. Esto indica un problema de configuración del puerto o del proxy.

## 🔍 Diagnóstico

El mensaje "Service is not reachable" significa que:
- ✅ El contenedor está corriendo (Apache iniciado)
- ❌ Nginx no puede conectarse al contenedor
- ⚠️ Probable problema de configuración del puerto

## ✅ Soluciones

### Solución 1: Verificar el Puerto en "Dominios"

1. Ve a **"Dominios"** en EasyPanel
2. Verifica la configuración:
   - **Protocolo**: `HTTP`
   - **Puerto**: Debe ser el puerto **interno del contenedor** (generalmente `80`)
   - **NO** debe ser el puerto externo (8080)

**IMPORTANTE**: En EasyPanel, el puerto en "Dominios" debe ser el puerto **interno** del contenedor, no el externo.

Roundcube/Apache escucha en el puerto **80** internamente, así que:

1. Ve a **"Dominios"**
2. Cambia el puerto de `8080` a `80`
3. **Guarda** los cambios
4. Espera 10-15 segundos
5. Actualiza la página del webmail

### Solución 2: Verificar la Configuración del Contenedor

El contenedor de Roundcube escucha en el puerto **80** internamente (puerto por defecto de Apache).

EasyPanel debería mapear automáticamente:
- Puerto externo: `8080` (o el que configuraste)
- Puerto interno: `80` (donde Apache escucha)

Pero en la configuración del dominio, debes usar el puerto **interno** (`80`).

### Solución 3: Verificar el Mapeo de Puertos

1. En la configuración de webmail, busca la sección de **"Ports"** o **"Network"**
2. Verifica que haya un mapeo como:
   - `8080:80` (externo:interno)
   - O solo `80` (puerto interno)

3. En "Dominios", el puerto debe ser `80` (el interno)

## 🎯 Pasos Exactos

1. ✅ Ve a **"Dominios"** en EasyPanel
2. ✅ Haz clic en el dominio `webmail.checkin24hs.com`
3. ✅ En el campo **"Puerto"**, cambia de `8080` a `80`
4. ✅ **Guarda** los cambios
5. ✅ Espera 10-15 segundos
6. ✅ Actualiza la página del webmail (F5)

## 🔍 Verificación

Después de cambiar el puerto a `80`:

1. **Espera 10-15 segundos**
2. **Actualiza la página** (F5)
3. **Deberías ver** la página de login de Roundcube
4. **El error 502 debería desaparecer**

## 💡 Explicación Técnica

En Docker/EasyPanel:
- **Puerto interno**: Donde el contenedor escucha (Apache usa `80`)
- **Puerto externo**: Donde Nginx se conecta (puede ser `8080`, `3000`, etc.)
- **En "Dominios"**: Debes usar el puerto **interno** (`80`)

EasyPanel maneja el mapeo automáticamente, pero la configuración del dominio debe apuntar al puerto interno.

## 🆘 Si Sigue Sin Funcionar

1. **Verifica los logs** de nuevo para ver si hay nuevos mensajes
2. **Reinicia el servicio** (botón refresh)
3. **Verifica que el contenedor esté en verde**
4. **Intenta desde otro navegador** o en modo incógnito

## 📋 Resumen

- ✅ Apache está corriendo (confirmado por los logs)
- ✅ Roundcube está instalado
- ⚠️ Nginx no puede conectarse (problema de puerto)
- ✅ **Solución**: Cambiar el puerto en "Dominios" de `8080` a `80`

