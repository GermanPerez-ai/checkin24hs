# 🔧 Solución: DNS no funciona en teléfono pero sí en computadora

## 🔍 Problema

- ✅ Funciona en computadora: `cotizar.checkin24hs.com`
- ❌ No funciona en teléfono: Error `DNS_PROBE_FINISHED_NXDOMAIN`

## 📋 Posibles Causas

1. **Cache DNS del teléfono**: El teléfono tiene una versión antigua del DNS en caché
2. **Propagación DNS incompleta**: El DNS aún no se propagó a todos los servidores DNS
3. **URL incorrecta**: Escribiste mal la URL (vi "dor.checkin24hs.com" en lugar de "cotizar.checkin24hs.com")

## ✅ Soluciones

### Solución 1: Verificar que escribiste bien la URL

**Asegúrate de escribir exactamente:**
```
https://cotizar.checkin24hs.com
```

**NO escribas:**
- ❌ `dor.checkin24hs.com` (falta "cotiza")
- ❌ `cotizar.checkin24hs` (falta .com)
- ❌ `cotizador.checkin24hs.com` (tiene "d" extra)

### Solución 2: Limpiar Cache DNS del teléfono

#### En Android:
1. Ve a **Ajustes** → **Red e Internet** → **Internet**
2. Mantén presionado tu red Wi-Fi
3. **Editar** o **Modificar red**
4. **Opciones avanzadas** → **IP estática**
5. Cambiar DNS a: `8.8.8.8` (Google) o `1.1.1.1` (Cloudflare)
6. O simplemente **Olvidar** la red Wi-Fi y volver a conectarte

#### En iPhone/iOS:
1. Ve a **Ajustes** → **Wi-Fi**
2. Toca el **ⓘ** (info) junto a tu red Wi-Fi
3. **Configurar DNS** → **Manual**
4. Agregar servidores DNS: `8.8.8.8` y `8.8.4.4` (Google)
5. Guardar

### Solución 3: Usar datos móviles en lugar de Wi-Fi

Si estás en Wi-Fi, intenta:
1. **Desactivar Wi-Fi**
2. **Usar datos móviles (4G/5G)**
3. Acceder a: `https://cotizar.checkin24hs.com`

Si funciona con datos móviles pero no con Wi-Fi, el problema es el DNS de tu Wi-Fi.

### Solución 4: Verificar DNS en servidor

**Desde tu computadora, verifica que el DNS está configurado:**

```bash
# Verificar DNS desde tu computadora
nslookup cotizar.checkin24hs.com

# O desde PowerShell:
Resolve-DnsName cotizar.checkin24hs.com
```

### Solución 5: Esperar propagación DNS

Si acabas de configurar el DNS:
- Puede tardar **5 minutos a 24 horas** en propagarse completamente
- Prueba desde tu computadora: si funciona, el DNS está bien configurado
- El teléfono puede tardar más en actualizarse

### Solución 6: Usar IP directamente (temporal)

Mientras se propaga el DNS, puedes acceder temporalmente usando la IP:

```
https://72.61.58.240
```

(Nota: Es posible que necesites configurar el header Host en la petición, o que funcione directamente si el servidor acepta conexiones por IP)

## 🎯 Verificación Rápida

**Desde tu teléfono:**
1. Asegúrate de escribir: `https://cotizar.checkin24hs.com`
2. Intenta con datos móviles (sin Wi-Fi)
3. Si no funciona, espera 10-15 minutos y vuelve a intentar

**Desde tu computadora (verificar que está bien):**
```bash
# Verificar que el DNS resuelve correctamente
nslookup cotizar.checkin24hs.com
# Debe devolver: 72.61.58.240
```

---

**La causa más común es el cache DNS del teléfono. Prueba primero desactivar Wi-Fi y usar datos móviles, o cambiar el DNS manualmente en la configuración Wi-Fi del teléfono.**
