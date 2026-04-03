# Error: Dockerfile no such file or directory (WhatsApp en EasyPanel)

Cuando EasyPanel hace "Download Github Archive" y luego build del servicio WhatsApp, puede fallar con:

```
failed to read dockerfile: open Dockerfile: no such file or directory
```

**Causa:** El archivo que descarga GitHub (ZIP/tarball) suele extraerse con **una carpeta raíz** (por ejemplo `checkin24hs-main` o `GermanPerez-ai-checkin24hs-<sha>`). EasyPanel está configurado con ruta `whatsapp-server/Dockerfile` respecto a la raíz del clone; si la raíz del clone es esa carpeta extraída, la ruta correcta incluye ese nombre.

---

## 1. Ver la estructura en el servidor

Conectate por SSH y ejecutá:

```bash
ls -la /etc/easypanel/projects/checkin24hs/whatsapp/code/
```

Si ves **una sola carpeta** (por ejemplo `checkin24hs-main` o `GermanPerez-ai-checkin24hs-52bb4b5`), entrá y comprobá que dentro esté `whatsapp-server`:

```bash
ls -la /etc/easypanel/projects/checkin24hs/whatsapp/code/NOMBRE_DE_LA_CARPETA/
ls -la /etc/easypanel/projects/checkin24hs/whatsapp/code/NOMBRE_DE_LA_CARPETA/whatsapp-server/
```

Si existe `whatsapp-server/Dockerfile` dentro de esa carpeta, hay que decirle a EasyPanel que use esa ruta.

---

## 2. Ajustar en EasyPanel

En EasyPanel → proyecto **checkin24hs** → servicio **WhatsApp** → pestaña **Build** (o **Deploy**):

- **Build context / Context directory**  
  - Si en `code/` solo está la carpeta del repo (ej. `checkin24hs-main`), poné:  
    `checkin24hs-main`  
    (o el nombre exacto que viste en el `ls`).  
  - Si en `code/` están directamente las carpetas `whatsapp-server`, `deploy`, etc., dejá el contexto en **raíz** (`.` o vacío).

- **Dockerfile path**  
  - Si el contexto es la carpeta del repo (ej. `checkin24hs-main`):  
    `whatsapp-server/Dockerfile`  
  - Si el contexto es la raíz del repo (donde está `whatsapp-server`):  
    `whatsapp-server/Dockerfile`  
  (en ambos casos el Dockerfile está dentro de `whatsapp-server`).

Resumen: **Context** = carpeta que contiene a `whatsapp-server`. **Dockerfile path** = `whatsapp-server/Dockerfile` (siempre relativo a ese context).

---

## 3. Alternativa: build en el servidor con el repo clonado

Si preferís no depender del “Download Github Archive” de EasyPanel, podés construir la imagen en el servidor desde el repo que ya tenés en `/root/checkin24hs`:

```bash
cd /root/checkin24hs
git pull origin main
docker build -f whatsapp-server/Dockerfile -t easypanel/checkin24hs/whatsapp:latest ./whatsapp-server
docker service update --image easypanel/checkin24hs/whatsapp:latest checkin24hs_whatsapp
```

Así el Dockerfile y el context son los correctos y no dependen de cómo EasyPanel extraiga el archivo.
