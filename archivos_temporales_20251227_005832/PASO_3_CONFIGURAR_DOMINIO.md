# 📋 Paso 3: Configurar Dominio en EasyPanel

## 🎯 Objetivo
Configurar el dominio `configwp.checkin24hs.com` para el servicio `whatsapp-api` y habilitar SSL automático.

---

## 📝 Instrucciones Detalladas

### 3.1. Buscar la Sección "Dominios"

Después de guardar los módulos, deberías ver varias secciones en la configuración del servicio. Busca:

- **"Dominios"** o **"Domains"**
- Puede estar en el menú lateral izquierdo
- O en pestañas horizontales en la parte superior
- O como una tarjeta/sección en la página principal

---

### 3.2. Agregar el Dominio

1. Haz clic en la sección **"Dominios"** o **"Domains"**

2. Busca un botón o campo para agregar dominio:
   - Botón **"Agregar Dominio"** o **"Add Domain"**
   - Campo de texto con placeholder "ejemplo.com"
   - Botón **"+"** o **"Nuevo Dominio"**

3. Ingresa el dominio:
   ```
   configwp.checkin24hs.com
   ```

4. Haz clic en **"Agregar"**, **"Guardar"** o **"Save"**

---

### 3.3. Habilitar SSL

Después de agregar el dominio, deberías ver opciones para SSL:

1. Busca un toggle o checkbox que diga:
   - **"Enable SSL"** o **"Habilitar SSL"**
   - **"SSL/TLS"**
   - **"Let's Encrypt"**
   - O un icono de candado 🔒

2. **Activa SSL** (cambia el toggle a azul/activado)

3. EasyPanel debería configurar automáticamente SSL con Let's Encrypt

4. Guarda los cambios

---

### 3.4. Verificar Configuración

Después de guardar, deberías ver:
- ✅ El dominio `configwp.checkin24hs.com` en la lista
- ✅ Estado SSL: "Active", "Enabled" o un candado verde 🔒
- ✅ Puede mostrar "Generating..." o "Pending" mientras se crea el certificado

**⏱️ Espera 1-2 minutos** para que se genere el certificado SSL.

---

## ✅ Verificación

### Verificar SSL en el Navegador

1. Abre una nueva pestaña en tu navegador
2. Visita: `https://configwp.checkin24hs.com`
3. Deberías ver:
   - ✅ Candado verde 🔒 (SSL válido)
   - ✅ Sin errores de certificado
   - ⚠️ Posiblemente una página de error o "502 Bad Gateway" (eso está bien, significa que el dominio funciona pero aún no hay rutas configuradas)

---

## 🆘 Si Tienes Problemas

### Problema: No encuentro la sección "Dominios"
**Solución:**
- Busca en el menú lateral izquierdo
- Revisa las pestañas horizontales en la parte superior
- Puede estar dentro de "Configuración" o "Settings"

### Problema: SSL no se genera
**Solución:**
1. Verifica que el DNS esté configurado (ver Paso 6)
2. Asegúrate de que los puertos 80 y 443 estén abiertos
3. Espera 5-10 minutos y vuelve a intentar
4. Revisa los logs de EasyPanel

### Problema: Error "Domain already exists"
**Solución:**
- El dominio puede estar usado en otro servicio
- Verifica en otros servicios de EasyPanel
- O usa un subdominio diferente temporalmente

---

## ➡️ Siguiente Paso

Una vez que hayas configurado el dominio y SSL esté activo, avísame y pasamos al **Paso 4: Configurar Rutas de Proxy**.

---

## 📸 Ayuda Visual

Si puedes, toma una captura de pantalla de:
1. La sección "Dominios" con el dominio agregado
2. El estado de SSL (activo o pendiente)
3. Cualquier error que aparezca

Esto me ayudará a guiarte mejor.


