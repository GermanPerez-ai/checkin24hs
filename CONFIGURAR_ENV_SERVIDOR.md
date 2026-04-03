# 🔧 Configurar .env en el Servidor

## 📍 Ruta Encontrada

Tu proyecto está en:
```
/etc/easypanel/projects/checkin24hs/dashboard/code/
```

---

## 📋 Pasos a Seguir en el Servidor

### 1. Ir al directorio del proyecto

```bash
cd /etc/easypanel/projects/checkin24hs/dashboard/code
```

### 2. Verificar que es el lugar correcto

```bash
ls -la server.js dashboard.html package.json
```

Deberías ver esos 3 archivos.

### 3. Actualizar el código desde GitHub

```bash
git pull origin main
```

### 4. Instalar dotenv (si no está instalado)

```bash
npm install dotenv
```

### 5. Crear el archivo `.env`

```bash
nano .env
```

**Pega este contenido:**
```env
GEMINI_API_KEY=AIzaSyDvza5tlt0fjEgTamUKG1ZjTuqU8qjCaxI
GEMINI_MODEL=gemini-2.5-flash
```

**Para guardar en nano:**
- Presiona `Ctrl + X`
- Presiona `Y` (para confirmar)
- Presiona `Enter` (para salir)

### 6. Verificar que el archivo se creó correctamente

```bash
cat .env
```

Deberías ver tu API Key (sin espacios extras).

### 7. Reiniciar el servicio en EasyPanel

**Opción A: Desde EasyPanel (Recomendado)**
1. Ve a EasyPanel en tu navegador
2. Busca el servicio "dashboard"
3. Haz clic en "Restart" o "Reiniciar"

**Opción B: Desde SSH**
```bash
# Si EasyPanel usa Docker
docker restart <nombre_contenedor_dashboard>

# O si usa otro método, verifica con:
docker ps | grep dashboard
```

### 8. Verificar que funciona

**Verifica los logs del servidor:**
```bash
# Ver logs de Docker (si usa contenedor)
docker logs <nombre_contenedor> --tail 50

# O si usas PM2
pm2 logs dashboard
```

**Deberías ver:**
```
🔑 GEMINI_API_KEY: ✅ Configurada
🤖 Modelo Gemini: gemini-2.5-flash
```

---

## ✅ Checklist

- [ ] Navegué al directorio: `/etc/easypanel/projects/checkin24hs/dashboard/code`
- [ ] Verifiqué que están `server.js`, `dashboard.html`, `package.json`
- [ ] Hice `git pull origin main`
- [ ] Ejecuté `npm install dotenv`
- [ ] Creé el archivo `.env` con mi API Key
- [ ] Verifiqué el contenido con `cat .env`
- [ ] Reinicié el servicio (desde EasyPanel o Docker)
- [ ] Verifiqué los logs y veo "✅ Configurada"
- [ ] Probé "Probar Conexión" en el dashboard y funciona

---

## 🔍 Si algo no funciona

### El archivo `.env` no se guarda
- Asegúrate de usar `Ctrl+X`, luego `Y`, luego `Enter` en nano
- Verifica con `cat .env` que se guardó

### El servidor no lee el `.env`
- Verifica que el archivo está en la misma carpeta que `server.js`
- Verifica que el archivo no tiene extensión `.txt` (debe ser solo `.env`)
- Reinicia el servicio

### El git pull da error
- Es posible que haya conflictos. Usa:
  ```bash
  git stash
  git pull origin main
  ```

---

**¡Listo! Una vez completados estos pasos, tu API Key estará segura en el servidor.** 🔒
