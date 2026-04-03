# 🔧 Solución: Nombre del Servicio en EasyPanel

## 🎯 Problema Identificado

- EasyPanel genera automáticamente: `http://checkin24hs_dashboard:80/` (con **guión bajo**)
- Pero el alias real en Docker es: `checkin24hs-dashboard` (con **guión**)
- **No coinciden** → 404

## ✅ Soluciones

### Solución 1: Cambiar el Nombre del Servicio en EasyPanel

EasyPanel genera el destino basándose en el nombre del servicio. Si cambias el nombre del servicio, el destino cambiará automáticamente.

**Pasos:**

1. En EasyPanel, ve al servicio `dashboard`
2. Haz clic en el **lápiz** (editar) que está al lado de "APP" o del nombre del servicio
3. Cambia el nombre del servicio a: `dashboard` (sin prefijo, sin guiones)
4. Guarda los cambios
5. Espera 30-60 segundos
6. Ve a "Dominios" y verifica que el destino ahora sea: `http://dashboard:80/`
7. Prueba acceder

### Solución 2: Verificar si el Nombre del Servicio se Puede Editar

Si no puedes editar el nombre directamente:

1. Busca en la configuración del servicio una opción de **"Renombrar"** o **"Editar nombre"**
2. O busca en la pestaña **"Fuente"** o **"Configuración"** si hay una opción para cambiar el nombre

### Solución 3: Crear un Nuevo Servicio con Nombre Correcto

Si no puedes renombrar el servicio actual:

1. Crea un **nuevo servicio** en EasyPanel
2. Nómbralo exactamente: `dashboard` (sin prefijo)
3. Configura:
   - Build Path: `/deploy`
   - Dockerfile: `Dockerfile`
   - Puerto: `80`
   - Variables de entorno: `PORT=80`
4. Agrega el dominio `dashboard.checkin24hs.com` a este nuevo servicio
5. EasyPanel debería generar: `http://dashboard:80/` (que coincide con el alias `dashboard`)

### Solución 4: Volver a la Configuración Anterior (Node.js en Puerto 3000)

Si prefieres volver a la configuración anterior que funcionaba:

1. Necesitarías cambiar el Dockerfile para usar Node.js en lugar de Nginx
2. Y cambiar `PORT=80` a `PORT=3000`
3. Pero esto requeriría modificar el Dockerfile y la configuración

**No recomendado** porque ya tenemos Nginx funcionando correctamente.

---

## 🔍 Verificación

Para verificar el nombre actual del servicio:

1. Mira la URL del navegador cuando estás en el servicio `dashboard`
2. O busca en la configuración del servicio el nombre exacto
3. El nombre probablemente sea `checkin24hs_dashboard` (con guión bajo)

---

## 🎯 Recomendación

**Intenta primero la Solución 1**: Cambiar el nombre del servicio a `dashboard` (sin prefijo) usando el lápiz de edición que está al lado de "APP".

**¿Puedes hacer clic en el lápiz al lado de "APP" y cambiar el nombre del servicio a `dashboard`?**
