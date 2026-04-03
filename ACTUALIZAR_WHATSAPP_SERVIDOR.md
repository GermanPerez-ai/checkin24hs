# Actualizar el servidor WhatsApp en el servidor

El servidor WhatsApp (`whatsapp-server-baileys.js`) corre como **servicio Docker** (nombre típico: **checkin24hs_whatsapp**). Para aplicar cambios hay que **subir el código** y **reconstruir/reiniciar** el servicio.

---

## Cómo se actualiza normalmente (resumen)

| Paso | Dónde | Acción |
|------|--------|--------|
| 1 | **Tu PC** | Subir código: `git add whatsapp-server/` → `git commit -m "..."` → `git push origin main` |
| 2a | **EasyPanel** | Si el servicio usa **GitHub**: Entrar al servicio WhatsApp → **Implementar** / **Redeploy** |
| 2b | **Servidor (SSH)** | Si construís la imagen en el servidor: `cd /root/checkin24hs` (o la ruta del repo) → `git pull` → `cd whatsapp-server` → `docker build -t whatsapp-server:latest .` → `docker service update --force checkin24hs_whatsapp` (o el nombre real del servicio) |

**Si no encontrás el servicio:** `docker service ls` (Swarm) o `docker ps` (contenedores) para ver el nombre exacto. La ruta del proyecto en el servidor puede ser `/root/checkin24hs` o `~/checkin24hs`; el archivo debe estar en `whatsapp-server/whatsapp-server-baileys.js`.

---

## 1. Subir cambios a GitHub (en tu PC)

En la carpeta del proyecto (PowerShell o Git Bash):

```bash
cd C:\Users\German\Downloads\Checkin24hs
git add whatsapp-server/whatsapp-server-baileys.js
git status
git commit -m "Actualizar servidor WhatsApp (Flor systemInstruction, reglas prioridad)"
git push origin main
```

---

## 2. En el servidor (consola web del panel)

Conectate por **consola web** (o SSH) al servidor. Ejecutá los comandos según cómo tengas desplegado el servicio.

### Opción A: EasyPanel construye desde GitHub

Si el servicio **checkin24hs_whatsapp** en EasyPanel usa **Fuente → GitHub** (repositorio checkin24hs, build path `/whatsapp-server`):

1. Entrá a **EasyPanel** → proyecto → app **WhatsApp**.
2. Clic en **Implementar** / **Redeploy** (o **Deploy**).
3. Esperá a que termine el build y el servicio se reinicie.

Con eso EasyPanel vuelve a construir la imagen desde GitHub y actualiza el servicio.

---

### Opción B: Imagen Docker construida en el servidor

Si el servicio usa una **imagen local** (p. ej. `whatsapp-server:latest`) que construís en el servidor:

**2.1.** Ir a la carpeta del proyecto y actualizar desde GitHub:

```bash
cd /root/checkin24hs
```

Si `git pull` falla por archivos sin seguimiento que se sobrescribirían (como antes), movelos y volvé a hacer pull:

```bash
mkdir -p /tmp/checkin24hs-backup
mv whatsapp-server/aplicar-modo-pasivo.py whatsapp-server/aplicar-todos-cambios-modo-pasivo.py whatsapp-server/diagnosticar-y-solucionar-autenticacion.sh whatsapp-server/limpiar-sesion-y-reconectar.sh whatsapp-server/restaurar-y-aplicar-modo-pasivo.sh whatsapp-server/verificar-despues-redeploy-completo.sh /tmp/checkin24hs-backup/ 2>/dev/null || true
git pull origin main
```

**2.2.** Construir la imagen y actualizar el servicio:

```bash
cd /root/checkin24hs/whatsapp-server
docker build -t whatsapp-server:latest .
docker service update --force checkin24hs_whatsapp
```

**2.3.** Verificar:

```bash
docker service ps checkin24hs_whatsapp --no-trunc | head -5
docker service logs checkin24hs_whatsapp --tail 30
```

En los logs deberías ver algo como `🌸 Flor: usando Prompt General desde Supabase` o `por defecto` al procesar un mensaje.

---

## 3. Alternativa: subir con scp (PowerShell) y luego construir en servidor

Si tenés **SSH desde tu PC** al servidor:

**En tu PC (PowerShell):**

```powershell
cd C:\Users\German\Downloads\Checkin24hs
scp -r whatsapp-server root@72.61.58.240:/root/checkin24hs/
```

**En el servidor (consola web o SSH):**

```bash
cd /root/checkin24hs/whatsapp-server
docker build -t whatsapp-server:latest .
docker service update --force checkin24hs_whatsapp
```

---

## Resumen rápido

| Paso | Dónde | Acción |
|------|--------|--------|
| 1 | PC | `git add whatsapp-server/` → `git commit` → `git push` |
| 2a | EasyPanel | Si fuente = GitHub: **Implementar** / **Redeploy** del servicio WhatsApp |
| 2b | Servidor | Si imagen local: `git pull` → `cd whatsapp-server` → `docker build -t whatsapp-server:latest .` → `docker service update --force checkin24hs_whatsapp` |

---

## Verificar que Flor use el prompt

Después de actualizar, enviá un mensaje de prueba por WhatsApp (p. ej. *"Info de Puyehue"*) y revisá los logs:

```bash
docker service logs checkin24hs_whatsapp --tail 80
```

Buscá:

- `🌸 Flor: usando Prompt General desde Supabase` → está usando la config del Dashboard.
- `🌸 Flor: usando Prompt General por defecto` → usa el prompt por defecto (revisar que hayas guardado en Dashboard y que exista `flor_general_config` en Supabase).
