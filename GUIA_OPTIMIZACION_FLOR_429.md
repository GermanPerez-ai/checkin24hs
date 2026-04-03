# Guía técnica: optimización de Flor IA para evitar error 429

Correcciones de código y configuración para estabilizar el bot de WhatsApp, optimizar el consumo de tokens de Gemini 2.5 Flash y asegurar la persistencia de la sesión.

---

## 1. Cambios ya implementados en código

### RAG selectivo (optimización de tokens)
- **Qué hace:** Solo se envía a Gemini la información de los hoteles **detectados** en el mensaje (máximo 3). Se deja de enviar la base completa en cada consulta.
- **Dónde:** `procesarConFlor` en `whatsapp-server-baileys.js`.
- **Log:** `🎯 RAG: Enviando solo N hotel(es) detectado(s).`

### Exponential backoff para 429
- **Qué hace:** Ante 429, se reintenta hasta 5 veces con esperas crecientes: 2s, 8s, 18s, 32s, 50s.
- **Fórmula:** `(attempt + 1)² * 2000` ms.

### Dockerfile
- **Base:** `node:20-slim`.
- **Build deps:** `python3`, `make`, `g++` para Baileys.
- **Carpetas:** `auth_info_baileys_1` … `auth_info_baileys_4` para persistencia de sesión.

---

## 2. Configuración en EasyPanel

El programador debe aplicar estos ajustes en el panel para que todo funcione correctamente.

### 2.1 Montaje de volumen (persistencia de sesión WhatsApp)

Sin volumen, cada **Redeploy** borra la sesión y hay que escanear el QR de nuevo.

1. EasyPanel → proyecto **checkin24hs** → app **WhatsApp**.
2. **Puntos de montaje** → **«Agregar montaje de volumen»**.
3. Configurá:

   | Campo | Valor |
   |-------|--------|
   | **Nombre** (label) | `whatsapp-session` |
   | **Host path** / **Source** | `/root/checkin24hs/whatsapp-auth` |
   | **Mount path** / **Container path** | `/app/auth_info_baileys_1` |

   Crear la carpeta en el servidor si no existe:
   ```bash
   mkdir -p /root/checkin24hs/whatsapp-auth
   ```
   (Instancia 1; si usás otra, `auth_info_baileys_2`, etc.)
4. Guardá los cambios.

Así la sesión de Baileys se guarda en el host y sobrevive a redeploys.

### 2.2 Límite de réplicas: 1

- **Réplicas:** Debe estar en **1**.
- **Motivo:** Varias instancias usando la misma API Key de Gemini generan muchas más requests y **429** casi seguro.

### 2.3 Variable de entorno `FLOR_DELAY_MS`

- **Nombre:** `FLOR_DELAY_MS`
- **Valor:** `5000`
- **Motivo:** Agrupa mensajes en una ventana de 5 segundos y evita varias llamadas seguidas a Gemini.

### 2.4 Otras variables recomendadas

En **Variables** / **Environment** del servicio WhatsApp:

- `GEMINI_API_KEY` – clave de Gemini.
- `SUPABASE_URL`, `SUPABASE_ANON_KEY` – para Flor y guardado de mensajes.
- `PORT=3001` – puerto del servidor.

---

## 3. Resumen de comprobaciones

| Elemento | Acción |
|----------|--------|
| Volumen | Bind mount host → `/app/auth_info_baileys_1` |
| Réplicas | 1 |
| `FLOR_DELAY_MS` | 5000 |
| `GEMINI_API_KEY` | Configurada |
| Supabase | URL y anon key configuradas |

---

## 4. Cómo aplicar los cambios de código

1. **En tu PC:**  
   `git add whatsapp-server/` → `commit` → `push origin main`.
2. **En EasyPanel:**  
   **Implementar** / **Redeploy** del servicio WhatsApp (para que use el nuevo Dockerfile y código).
3. Si configuraste el volumen correctamente, la sesión de WhatsApp se mantiene después del redeploy.
