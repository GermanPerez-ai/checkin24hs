# ⚠️ RECORDATORIO: Actualizar Cotizador

## 📋 Pasos Rápidos

### 1️⃣ **PRIMERO: Subir a GitHub (desde tu PC)**

```powershell
# En PowerShell
cd c:\Users\German\Downloads\Checkin24hs
.\ACTUALIZAR_COTIZADOR_COMPLETO.ps1
```

### 2️⃣ **SEGUNDO: Actualizar en el Servidor**

```bash
# Conecta por SSH al servidor
ssh root@72.61.58.240

# Ejecuta el script de actualización
cd /root/checkin24hs
./ACTUALIZAR_COTIZADOR_FINAL.sh
```

### 3️⃣ **TERCERO: Verificar**

1. Limpia la caché del navegador: `Ctrl + Shift + R`
2. Abre: `https://cotizar.checkin24hs.com/`
3. Verifica que los cambios se aplicaron

---

## 🚨 Si Olvidaste los Pasos

En el servidor, ejecuta:

```bash
cd /root/checkin24hs
./RECORDATORIO_ACTUALIZAR_COTIZADOR.sh
```

Este script te mostrará las instrucciones paso a paso.

---

## ✅ Checklist Rápido

- [ ] Cambios guardados localmente
- [ ] Cambios subidos a GitHub
- [ ] Conectado al servidor por SSH
- [ ] Ejecutado `./ACTUALIZAR_COTIZADOR_FINAL.sh`
- [ ] Caché del navegador limpiada
- [ ] Verificado en `https://cotizar.checkin24hs.com/`

---

**💡 Tip:** El script `ACTUALIZAR_COTIZADOR_FINAL.sh` ahora te pregunta si ya subiste los cambios a GitHub antes de ejecutar.
