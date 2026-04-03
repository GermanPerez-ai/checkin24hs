# 🌐 Configurar DNS para panel.checkin24hs.com - Paso a Paso

## Paso 1: Obtener la IP del Servidor

Ejecuta este comando en SSH:

```bash
curl ifconfig.me
```

O si no funciona:

```bash
curl -4 ifconfig.me
```

**Anota la IP que te muestre** (ejemplo: `123.45.67.89`)

---

## Paso 2: Ir a tu Panel de DNS

Ve al panel donde gestionas los DNS de `checkin24hs.com`:
- **Cloudflare**: cloudflare.com → Selecciona el dominio → DNS
- **Namecheap**: namecheap.com → Domain List → Manage → Advanced DNS
- **GoDaddy**: godaddy.com → Mis Productos → DNS
- **Google Domains**: domains.google → DNS
- **Otro proveedor**: Busca la sección "DNS" o "Zona DNS"

---

## Paso 3: Agregar el Registro A

1. Busca el botón **"Agregar registro"**, **"Add Record"**, **"+"** o similar
2. Completa los campos:

   **Tipo de registro:**
   - Selecciona **"A"** o **"A Record"**

   **Nombre/Host/Subdominio:**
   - Escribe: `panel`
   - (Algunos paneles piden solo `panel`, otros `panel.checkin24hs.com`)

   **Valor/Destino/IP:**
   - Pega la **IP que obtuviste en el Paso 1**
   - Ejemplo: `123.45.67.89`

   **TTL (Time To Live):**
   - Deja el valor por defecto (generalmente 3600 o "Automático")
   - O escribe: `3600`

3. Haz clic en **"Guardar"**, **"Add"**, **"Crear"** o similar

---

## Paso 4: Verificar el Registro

Después de guardar, deberías ver en la lista de registros DNS algo como:

```
Tipo: A
Nombre: panel
Valor: [tu-ip]
TTL: 3600
```

---

## Paso 5: Esperar Propagación

- **Espera 5-30 minutos** para que el DNS se propague
- Puede ser más rápido (5 minutos) o más lento (hasta 24 horas), pero generalmente es rápido

---

## Paso 6: Verificar que Funciona

### Opción A: Desde tu computadora

Abre una terminal/consola y ejecuta:

**Windows (PowerShell o CMD):**
```cmd
nslookup panel.checkin24hs.com
```

**Linux/Mac:**
```bash
nslookup panel.checkin24hs.com
```

O:
```bash
dig panel.checkin24hs.com
```

**Debe mostrar la IP que configuraste.**

### Opción B: Desde el navegador

1. Espera 5-30 minutos
2. Abre: `https://panel.checkin24hs.com`
3. Deberías ver la aplicación funcionando (ya no el error DNS)

---

## ❌ Si No Funciona Después de 30 Minutos

1. **Verifica que el registro DNS esté correcto:**
   - Tipo: A
   - Nombre: `panel`
   - IP: La correcta

2. **Verifica que el dominio esté configurado en EasyPanel:**
   - Ve al servicio `checkin24hs-dashboard`
   - Pestaña "🔗 Dominios"
   - Verifica que `panel.checkin24hs.com` esté ahí

3. **Prueba desde SSH:**
   ```bash
   # Verificar que el servicio está corriendo
   docker service ps checkin24hs_checkin24hs-dashboard --no-trunc | head -3
   
   # Verificar logs
   docker service logs checkin24hs_checkin24hs-dashboard --tail 10
   ```

---

## 📝 Notas Importantes

- El registro DNS puede tardar en propagarse, ten paciencia
- Asegúrate de usar la **IP pública** del servidor, no la IP privada
- Si cambias la IP del servidor, deberás actualizar el registro DNS

