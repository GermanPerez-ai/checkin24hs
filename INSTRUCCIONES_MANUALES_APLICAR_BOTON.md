# 📋 Instrucciones Manuales: Aplicar Botón de Configuración

## ✅ El botón está en el código local

El botón **"Configurar Servidor"** está correctamente agregado en el archivo `deploy/dashboard.html` en la línea **3649-3652**.

## 🔧 Para aplicarlo al servidor manualmente:

### Opción 1: Usar WinSCP o similar

1. Conecta al servidor: `72.61.58.240` (usuario: `root`)
2. Ve a: `/root/checkin24hs/deploy/`
3. Sube el archivo `deploy/dashboard.html` desde tu computadora
4. Reemplaza el archivo existente

### Opción 2: Usar SSH manualmente

```bash
# Desde tu computadora (PowerShell)
scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html

# Luego conecta al servidor
ssh root@72.61.58.240

# Aplica a los contenedores
cd /root/checkin24hs
for c in $(docker ps --format "{{.Names}}" | grep checkin24hs_dashboard); do
    echo "Procesando $c"
    docker stop $c
    docker cp deploy/dashboard.html $c:/app/dashboard.html || docker cp deploy/dashboard.html $c:/usr/share/nginx/html/dashboard.html
    docker start $c
    echo "✅ $c actualizado"
done
```

### Opción 3: Usar EasyPanel

1. Ve a EasyPanel
2. Busca el servicio del Dashboard
3. Edita el servicio
4. En la sección de archivos, sube el nuevo `dashboard.html`
5. Reinicia el servicio

---

## 📍 Ubicación del Botón en el Código

**Archivo**: `deploy/dashboard.html`  
**Líneas**: 3649-3652

```html
<button onclick="showWhatsAppConfig()" class="form-button" style="background: #ff9800; color: white; padding: 12px 24px; font-size: 1rem; font-weight: 600; border: none; border-radius: 8px; cursor: pointer; display: flex; align-items: center; gap: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.2);">
    <span style="font-size: 1.2rem;">⚙️</span>
    <span>Configurar Servidor</span>
</button>
```

---

## ✅ Después de aplicar

1. **Cierra y abre el navegador** (o presiona Ctrl+F5)
2. Ve a: **Flor IA → Pestaña WhatsApp**
3. Busca el **botón NARANJA** arriba a la derecha que dice **"⚙️ Configurar Servidor"**

---

## 🔍 Si aún no aparece

1. Verifica que el archivo se haya subido correctamente al servidor
2. Verifica que los contenedores se hayan reiniciado
3. Limpia la caché del navegador (Ctrl+Shift+Delete)
4. Prueba en modo incógnito (Ctrl+Shift+N)










