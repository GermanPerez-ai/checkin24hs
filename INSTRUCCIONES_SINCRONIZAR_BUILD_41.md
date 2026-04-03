# 🔄 Sincronizar Build #41 al Servidor

## 📊 Situación Actual

- **Local**: Build #41 ✅
- **Servidor**: Build #40 ⚠️
- **Necesita**: Actualizar servidor a Build #41

---

## 🚀 Pasos para Sincronizar

### Paso 1: Subir el archivo desde Windows (PowerShell)

**Abre PowerShell** y ejecuta:

```powershell
cd C:\Users\German\Downloads\Checkin24hs
.\SINCRONIZAR_BUILD_41.ps1
```

**O manualmente:**

```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp dashboard.html root@72.61.58.240:/root/checkin24hs/
```

Cuando te pida la contraseña, ingrésala.

---

### Paso 2: Aplicar en el servidor (SSH)

**Conéctate al servidor:**

```bash
ssh root@72.61.58.240
```

**Luego ejecuta:**

```bash
cd /root/checkin24hs

# Opción A: Usar el script automático
chmod +x SINCRONIZAR_BUILD_41.sh
./SINCRONIZAR_BUILD_41.sh

# Opción B: Comandos manuales
CONTAINER=$(docker ps --filter "name=dashboard" --format "{{.Names}}" | head -1)
echo "Contenedor: $CONTAINER"
docker cp dashboard.html "$CONTAINER:/app/dashboard.html"
docker service update --force checkin24hs_dashboard
```

---

### Paso 3: Verificar en el navegador

1. **Abre**: https://dashboard.checkin24hs.com/
2. **Limpia la caché**: 
   - Presiona **Ctrl+Shift+Delete**
   - Selecciona "Caché" y "Borrar datos"
   - O simplemente **Ctrl+Shift+R** (hard refresh)
3. **Verifica en consola** (F12 → Console):
   ```javascript
   window.DASHBOARD_BUILD_NUMBER
   ```
   Debería mostrar: `41` ✅

---

## ✅ Verificación Completa

Después de sincronizar, verifica que:

- [ ] `window.DASHBOARD_BUILD_NUMBER` muestra `41`
- [ ] `window.DASHBOARD_VERSION` muestra `2.1.0`
- [ ] Las mejoras de estabilidad funcionan:
  - [ ] Mensajes claros al guardar hoteles
  - [ ] Validación de fechas en reservas
  - [ ] Botón de cerrar sesión visible
  - [ ] Chats cargan desde Supabase

---

## 🔧 Si hay problemas

### El archivo no se sube

**Usa WinSCP:**
1. Descarga WinSCP: https://winscp.net/
2. Conecta a: `72.61.58.240` (usuario: `root`)
3. Arrastra `dashboard.html` a `/root/checkin24hs/`

### El contenedor no se actualiza

**Verifica el servicio:**
```bash
docker service ls | grep dashboard
docker service ps checkin24hs_dashboard
```

**Si es un contenedor directo:**
```bash
docker ps | grep dashboard
docker restart <nombre_contenedor>
```

### La versión no cambia en el navegador

1. **Limpia completamente la caché**:
   - Ctrl+Shift+Delete → "Todo el tiempo" → "Caché" → Borrar
2. **Cierra y vuelve a abrir** el navegador
3. **Prueba en modo incógnito**: Ctrl+Shift+N

---

## 📝 Notas

- El Build # se incrementa con cada deploy
- Build #41 incluye todas las mejoras de estabilidad documentadas
- Si el servidor muestra Build #40, significa que falta actualizar
- Las mejoras están documentadas en `docs/stability/`

---

**Última actualización**: 2025-01-27  
**Build objetivo**: #41  
**Versión**: v2.1.0
