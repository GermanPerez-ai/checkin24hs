# 🔍 Dónde Encontrar SSL/TLS en EasyPanel

## 📍 Ubicación de SSL/TLS

La opción SSL/TLS está en la sección **"Dominios"** o **"Domains"** de cada servicio.

---

## 🎯 Pasos para Encontrar SSL/TLS

### Paso 1: Abrir el Servicio

1. **Ve a EasyPanel**
2. **Haz clic en "Servicios"** o **"Services"** (en el menú lateral)
3. **Haz clic en el servicio `whatsapp`** (o el servicio que corresponda a api1)

### Paso 2: Ir a la Sección de Dominios

Una vez dentro del servicio, busca en el menú lateral o en las pestañas:

**Opciones comunes:**
- **"Dominios"** o **"Domains"** (en español o inglés)
- **"Rutas"** o **"Routes"**
- **"Proxy"** o **"Reverse Proxy"**
- **"Networking"** o **"Red"**

**Si no ves estas opciones:**
- Busca un icono de **🌐** (globo) o **🔗** (enlace)
- O busca en la parte superior del servicio, puede estar en pestañas horizontales

### Paso 3: Ver el Dominio Configurado

Cuando encuentres la sección de Dominios, deberías ver:

- Una lista de dominios configurados
- O un botón **"Agregar Dominio"** / **"Add Domain"**

### Paso 4: Verificar o Configurar SSL

**Si ya tienes el dominio agregado:**

1. **Haz clic en el dominio** `api1.checkin24hs.com` (o el que tengas)
2. Se abrirá un formulario o panel de edición
3. Busca una opción como:
   - ✅ **"SSL/TLS"** (casilla de verificación)
   - ✅ **"Enable SSL"** (activar SSL)
   - ✅ **"HTTPS"** (con un switch o toggle)
   - ✅ **"Let's Encrypt"** (con una casilla)
   - ✅ **"Auto SSL"** (SSL automático)

**Si NO tienes el dominio agregado:**

1. **Haz clic en "Agregar Dominio"** o **"Add Domain"**
2. **Ingresa el dominio**: `api1.checkin24hs.com`
3. **Configura el puerto**: `3001`
4. **Busca la opción SSL/TLS** y **márcala** ✅
5. **Guarda** los cambios

---

## 🖼️ Dónde Puede Estar Visualmente

### Opción A: En el Menú Lateral del Servicio

```
Servicio: whatsapp
├── Overview / Resumen
├── Logs
├── Terminal
├── 🔗 Dominios / Domains  ← AQUÍ
├── Variables de Entorno
├── Puertos
└── ...
```

### Opción B: En Pestañas Superiores

```
[Overview] [Logs] [Terminal] [Dominios] [Settings]
                                    ↑
                                  AQUÍ
```

### Opción C: En la Configuración del Dominio

Cuando haces clic en un dominio, puede aparecer un formulario como:

```
┌─────────────────────────────────┐
│ Dominio: api1.checkin24hs.com  │
│ Puerto: 3001                    │
│                                 │
│ ☐ SSL/TLS                      │ ← MARCAR ESTA CASILLA
│                                 │
│ [Guardar] [Cancelar]           │
└─────────────────────────────────┘
```

---

## 🔍 Si No Encuentras la Opción

### Verificación 1: ¿Estás en el Servicio Correcto?

- Asegúrate de estar dentro del servicio `whatsapp` (no en otro servicio)
- Verifica que el servicio esté creado y visible en la lista

### Verificación 2: ¿Tienes Permisos?

- Asegúrate de tener permisos de administrador en EasyPanel
- Algunas opciones pueden estar ocultas si no tienes los permisos adecuados

### Verificación 3: ¿La Versión de EasyPanel lo Soporta?

- EasyPanel puede tener diferentes versiones
- Si no ves la opción, puede que necesites actualizar EasyPanel

---

## 📸 ¿Puedes Compartir una Captura?

Si no encuentras la opción, puedes:

1. **Hacer una captura de pantalla** de:
   - La pantalla del servicio `whatsapp`
   - La sección de Dominios (si la encuentras)
   - El menú lateral del servicio

2. **Compartirla conmigo** y te indico exactamente dónde está

---

## 🎯 Resumen Rápido

1. **Servicios** → **`whatsapp`** → **"Dominios"** o **"Domains"**
2. **Haz clic en el dominio** `api1.checkin24hs.com`
3. **Busca la casilla "SSL/TLS"** o **"Enable SSL"**
4. **Márcala** ✅
5. **Guarda** los cambios

---

**¿Puedes ver la sección "Dominios" o "Domains" en el servicio `whatsapp`?**









