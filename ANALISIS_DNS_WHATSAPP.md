# 📋 Análisis de DNS - Qué Borrar para WhatsApp

## ✅ DNS que SÍ debes MANTENER (no son de WhatsApp)

| Tipo | Nombre | Uso | Acción |
|------|--------|-----|--------|
| A | `cotizar` | Cotizador | ✅ **MANTENER** |
| A | `crm` | CRM | ✅ **MANTENER** |
| A | `webmail` | Webmail | ✅ **MANTENER** |
| A | `mail` | Servidor de correo | ✅ **MANTENER** |
| A | `dashboard` | Dashboard | ✅ **MANTENER** |
| A | `@` | Dominio principal | ✅ **MANTENER** |
| CNAME | `www` | Redirección www | ✅ **MANTENER** |
| MX | `@` | Correo electrónico | ✅ **MANTENER** |
| TXT | `_dmarc` | Seguridad correo | ✅ **MANTENER** |
| TXT | `@` | SPF correo | ✅ **MANTENER** |
| CAA | `@` | Certificados SSL | ✅ **MANTENER** |

---

## ❌ DNS que SÍ debes BORRAR (son de WhatsApp - múltiples conexiones)

### Para 4 conexiones (ya no necesitas):
| Tipo | Nombre | Uso | Acción |
|------|--------|-----|--------|
| A | `whatsapp1` | WhatsApp conexión 1 | ❌ **BORRAR** |
| A | `whatsapp2` | WhatsApp conexión 2 | ❌ **BORRAR** |
| A | `whatsapp3` | WhatsApp conexión 3 | ❌ **BORRAR** |
| A | `whatsapp4` | WhatsApp conexión 4 | ❌ **BORRAR** |
| A | `api1` | API WhatsApp 1 | ❌ **BORRAR** |
| A | `api2` | API WhatsApp 2 | ❌ **BORRAR** |
| A | `api3` | API WhatsApp 3 | ❌ **BORRAR** |
| A | `api4` | API WhatsApp 4 | ❌ **BORRAR** |
| A | `configwp` | Configuración WhatsApp | ❌ **BORRAR** |

**Total a borrar: 9 registros DNS**

---

## 🎯 Para 1 Solo Teléfono - Opciones

### Opción A: Usar un subdominio simple (RECOMENDADO)
**Crear solo 1 DNS nuevo:**
```
Tipo: A | Nombre: whatsapp | Apunta a: 72.61.58.240 | TTL: 14400
```
**URL resultante:** `https://whatsapp.checkin24hs.com`

### Opción B: Reutilizar uno existente
Si quieres reutilizar `api1` (solo ese), puedes mantenerlo y borrar los demás:
- ✅ Mantener: `api1`
- ❌ Borrar: `api2`, `api3`, `api4`, `whatsapp1-4`, `configwp`

---

## 📝 Resumen de Acciones

### Borrar estos 9 DNS:
1. ❌ `whatsapp1`
2. ❌ `whatsapp2`
3. ❌ `whatsapp3`
4. ❌ `whatsapp4`
5. ❌ `api1`
6. ❌ `api2`
7. ❌ `api3`
8. ❌ `api4`
9. ❌ `configwp`

### Mantener estos DNS:
- ✅ `cotizar`
- ✅ `crm`
- ✅ `webmail`
- ✅ `mail`
- ✅ `dashboard`
- ✅ `@` (dominio principal)
- ✅ `www` (CNAME)
- ✅ Todos los MX, TXT, CAA (correo y SSL)

---

## 🆕 Después de Borrar - Crear Nuevo DNS

Una vez que borres los 9 DNS de WhatsApp, crea **1 solo DNS nuevo**:

```
Tipo: A
Nombre: whatsapp
Apunta a: 72.61.58.240
TTL: 14400
```

Esto te dará: `https://whatsapp.checkin24hs.com` para tu única conexión.
