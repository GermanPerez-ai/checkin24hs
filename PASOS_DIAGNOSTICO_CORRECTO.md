# 🔍 Pasos Correctos para el Diagnóstico

## ⚠️ IMPORTANTE
- Los comandos con `cd C:\Users\...` se ejecutan en tu **computadora** (PowerShell de Windows)
- Los comandos con `cd /root/...` se ejecutan en el **servidor** (SSH)

---

## 📋 Paso 1: Subir el script desde tu COMPUTADORA

**Abre PowerShell en tu computadora** (NO en el servidor):

```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp DIAGNOSTICO_SERVIDOR.sh root@72.61.58.240:/root/checkin24hs/
```

Cuando te pida la contraseña, ingrésala.

---

## 📋 Paso 2: Conectarse al servidor y ejecutar el diagnóstico

**Abre una nueva conexión SSH** (o usa la que ya tienes abierta):

```bash
ssh root@72.61.58.240
```

**Una vez conectado al servidor, ejecuta:**

```bash
cd /root/checkin24hs
chmod +x DIAGNOSTICO_SERVIDOR.sh
./DIAGNOSTICO_SERVIDOR.sh
```

---

## 📋 Paso 3: Enviar los resultados

Copia y pega aquí toda la salida del script `./DIAGNOSTICO_SERVIDOR.sh`

---

## 🔄 Resumen rápido

1. **En tu computadora (PowerShell):** `scp DIAGNOSTICO_SERVIDOR.sh root@72.61.58.240:/root/checkin24hs/`
2. **En el servidor (SSH):** `cd /root/checkin24hs && chmod +x DIAGNOSTICO_SERVIDOR.sh && ./DIAGNOSTICO_SERVIDOR.sh`
3. **Copia los resultados** y pégalos aquí
