# ⚡ Solución Inmediata: Copiar .env al Contenedor

## 📋 Comando Rápido

```bash
# Copiar el .env al contenedor
docker cp /etc/easypanel/projects/checkin24hs/dashboard/code/.env 5dad1338275e:/app/.env

# Verificar que se copió
docker exec 5dad1338275e cat /app/.env

# Reiniciar el contenedor para que cargue el .env
docker restart 5dad1338275e
```

**⚠️ NOTA:** Esta solución es TEMPORAL. Si EasyPanel reconstruye el contenedor, se perderá el `.env`.

---

## ✅ Solución Permanente: Variables de Entorno en EasyPanel

**RECOMENDADO** - Esta es la forma correcta y permanente:

1. Ve a EasyPanel en tu navegador
2. Abre el servicio **"dashboard"**
3. Busca la sección **"Environment Variables"** o **"Variables de Entorno"**
4. Agrega estas variables:
   - **Nombre:** `GEMINI_API_KEY`
   - **Valor:** `AIzaSyDvza5tlt0fjEgTamUKG1ZjTuqU8qjCaxI`
   
   - **Nombre:** `GEMINI_MODEL`
   - **Valor:** `gemini-2.5-flash`

5. **Guarda** los cambios
6. **Reinicia** el servicio desde EasyPanel

**Ventajas:**
- ✅ Persiste entre reconstrucciones
- ✅ Más seguro (no está en archivos)
- ✅ Es la forma estándar en contenedores
- ✅ Fácil de actualizar desde el panel

---

## 🔄 Si usas la Solución Temporal

Después de copiar el `.env` al contenedor, verifica:

```bash
# Ver logs después de reiniciar
docker logs 5dad1338275e --tail 30 | grep GEMINI
```

Deberías ver:
```
🔑 GEMINI_API_KEY: ✅ Configurada
```

---

**Recomendación: Usa la Solución Permanente (Variables de Entorno en EasyPanel)** para evitar problemas futuros.
