# Configurar DNS para los 4 Servicios de WhatsApp

## 📋 Registros DNS Necesarios

Necesitas agregar **4 registros A** en tu panel DNS, uno para cada servicio:

| Tipo | Nombre | Apunta a | TTL |
|------|--------|----------|-----|
| **A** | `whatsapp1` | `72.61.58.240` | `14400` |
| **A** | `whatsapp2` | `72.61.58.240` | `14400` |
| **A** | `whatsapp3` | `72.61.58.240` | `14400` |
| **A** | `whatsapp4` | `72.61.58.240` | `14400` |

---

## 🔧 Pasos para Configurar DNS

### Paso 1: Ir a tu Panel DNS

1. Ve a tu proveedor de dominio (donde compraste `checkin24hs.com`)
2. Busca la sección de **"DNS"** o **"Zona DNS"** o **"Registros DNS"**
3. Busca la opción **"Agregar registro"** o **"Add Record"**

### Paso 2: Agregar WhatsApp 1

1. **Tipo:** Selecciona **"A"**
2. **Nombre/Host:** `whatsapp1` (sin el punto final)
3. **Apunta a/IP:** `72.61.58.240`
4. **TTL:** `14400` (o déjalo por defecto)
5. **Guardar**

### Paso 3: Agregar WhatsApp 2

1. **Tipo:** Selecciona **"A"**
2. **Nombre/Host:** `whatsapp2` (sin el punto final)
3. **Apunta a/IP:** `72.61.58.240`
4. **TTL:** `14400` (o déjalo por defecto)
5. **Guardar**

### Paso 4: Agregar WhatsApp 3

1. **Tipo:** Selecciona **"A"**
2. **Nombre/Host:** `whatsapp3` (sin el punto final)
3. **Apunta a/IP:** `72.61.58.240`
4. **TTL:** `14400` (o déjalo por defecto)
5. **Guardar**

### Paso 5: Agregar WhatsApp 4

1. **Tipo:** Selecciona **"A"**
2. **Nombre/Host:** `whatsapp4` (sin el punto final)
3. **Apunta a/IP:** `72.61.58.240`
4. **TTL:** `14400` (o déjalo por defecto)
5. **Guardar**

---

## ✅ Resultado Esperado

Después de agregar los 4 registros, deberías ver algo así en tu panel DNS:

```
Tipo  Nombre      Apunta a        TTL
A     whatsapp1   72.61.58.240    14400
A     whatsapp2   72.61.58.240    14400
A     whatsapp3   72.61.58.240    14400
A     whatsapp4   72.61.58.240    14400
```

---

## ⏱️ Tiempo de Propagación

- **Mínimo:** 15 minutos - 1 hora
- **Máximo:** Hasta 24 horas (raro)
- **Normal:** 1-4 horas

---

## 🧪 Verificar que DNS Está Configurado

Después de agregar los registros, puedes verificar con:

```bash
# Verificar WhatsApp 1
nslookup whatsapp1.checkin24hs.com

# Verificar WhatsApp 2
nslookup whatsapp2.checkin24hs.com

# Verificar WhatsApp 3
nslookup whatsapp3.checkin24hs.com

# Verificar WhatsApp 4
nslookup whatsapp4.checkin24hs.com
```

O desde tu navegador, prueba acceder a:
- `https://whatsapp1.checkin24hs.com`
- `https://whatsapp2.checkin24hs.com`
- `https://whatsapp3.checkin24hs.com`
- `https://whatsapp4.checkin24hs.com`

---

## ⚠️ Notas Importantes

1. **Todos apuntan a la misma IP:** Los 4 registros apuntan a `72.61.58.240` porque Traefik se encarga de enrutar cada dominio al servicio correcto según la configuración.

2. **No uses "www":** Solo `whatsapp1`, no `www.whatsapp1`.

3. **Espera la propagación:** Después de agregar los registros, espera unos minutos antes de probar.

4. **Certificados SSL:** Traefik generará automáticamente certificados SSL para cada dominio una vez que DNS esté propagado.

---

## 📝 Ejemplo Visual

Si tu panel DNS se ve así:

```
checkin24hs.com - DNS Records

Tipo  Nombre      Apunta a        TTL
A     @           84.32.84.32     50
A     crm         72.61.58.240    14400
A     dashboard   72.61.58.240    14400
A     webmail     72.61.58.240    14400
A     mail        72.61.58.240    14400
```

Después de agregar los 4 registros, debería verse así:

```
checkin24hs.com - DNS Records

Tipo  Nombre      Apunta a        TTL
A     @           84.32.84.32     50
A     crm         72.61.58.240    14400
A     dashboard   72.61.58.240    14400
A     webmail     72.61.58.240    14400
A     mail        72.61.58.240    14400
A     whatsapp1   72.61.58.240    14400  ← NUEVO
A     whatsapp2   72.61.58.240    14400  ← NUEVO
A     whatsapp3   72.61.58.240    14400  ← NUEVO
A     whatsapp4   72.61.58.240    14400  ← NUEVO
```

---

## 🎯 Resumen

**Sí, necesitas agregar los 4 registros DNS.** Cada uno apunta al mismo servidor (`72.61.58.240`), pero Traefik los enrutará a los servicios correctos según la configuración que ya hicimos.

Una vez agregados, espera unos minutos y luego prueba acceder a cada dominio. Los certificados SSL se generarán automáticamente.


















