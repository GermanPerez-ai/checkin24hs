# ⚠️ RECORDATORIO: Actualizar Dashboard

## 📋 Pasos Rápidos

### 1️⃣ **PRIMERO: Subir a GitHub (desde tu PC)**

```powershell
# En PowerShell
cd c:\Users\German\Downloads\Checkin24hs
.\ACTUALIZAR_DASHBOARD_COMPLETO.ps1
```

Este script:
- ✅ Actualiza automáticamente el build number
- ✅ Hace commit y push a GitHub
- ✅ Muestra recordatorios para el servidor

### 2️⃣ **SEGUNDO: Actualizar en el Servidor**

```bash
# Conecta por SSH al servidor
ssh root@72.61.58.240

# Ejecuta el script de actualización
cd /root/checkin24hs
./ACTUALIZAR_DASHBOARD_FINAL.sh
```

### 3️⃣ **TERCERO: Verificar**

1. Limpia la caché del navegador: `Ctrl + Shift + R`
2. Abre: `https://dashboard.checkin24hs.com/`
3. Verifica el build number en la consola: `window.DASHBOARD_BUILD_NUMBER`
4. El build number también se muestra en el sidebar del dashboard

---

## 🚨 Si Olvidaste los Pasos

En el servidor, ejecuta:

```bash
cd /root/checkin24hs
./RECORDATORIO_ACTUALIZAR_DASHBOARD.sh
```

Este script te mostrará las instrucciones paso a paso.

---

## ✅ Checklist Rápido

- [ ] Build number actualizado (automático con el script)
- [ ] Cambios guardados localmente
- [ ] Cambios subidos a GitHub
- [ ] Conectado al servidor por SSH
- [ ] Ejecutado `./ACTUALIZAR_DASHBOARD_FINAL.sh`
- [ ] Servicio reiniciado (automático)
- [ ] Caché del navegador limpiada
- [ ] Verificado en `https://dashboard.checkin24hs.com/`
- [ ] Build number verificado en consola

---

## 🔢 Sobre el Build Number

- **Actualización automática**: El script `ACTUALIZAR_DASHBOARD_COMPLETO.ps1` actualiza el build number automáticamente
- **Verificación**: El script del servidor verifica que el build number haya incrementado
- **Visualización**: El build number se muestra en el sidebar del dashboard y en la consola

---

**💡 Tip:** El script `ACTUALIZAR_DASHBOARD_FINAL.sh` verifica que el build number haya incrementado antes de aplicar los cambios.
