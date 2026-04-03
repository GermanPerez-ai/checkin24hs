# 🔧 Recrear Evolution API en EasyPanel

## 🔍 Paso 1: Verificar si el Contenedor Existe

### Desde SSH (Terminal):

```bash
cd ~/evolution-api

# Ver todos los contenedores
docker ps -a

# Ver si existe algún contenedor con "evolution"
docker ps -a | grep evolution

# Ver si existe algún contenedor con "checkin24hs"
docker ps -a | grep checkin24hs
```

---

## 🔧 Paso 2: Si No Existe, Recrearlo

### Opción A: Desde SSH

```bash
cd ~/evolution-api

# Verificar que los archivos existen
ls -la docker-compose.yml .env

# Detener y eliminar todo (si existe algo)
docker-compose down

# Recrear todo
docker-compose up -d

# Verificar que se creó
docker ps -a | grep evolution

# Ver logs
docker logs evolution-api-checkin24hs
```

### Opción B: Crear desde EasyPanel Directamente

1. **En EasyPanel**:
   - Ve a "Containers" o "Docker"
   - Haz clic en "New Container" o "Add Container"

2. **Configuración**:
   - **Image**: `atendai/evolution-api:latest`
   - **Container Name**: `evolution-api-checkin24hs`
   - **Ports**: `8080:8080`
   - **Restart Policy**: `unless-stopped`

3. **Environment Variables** (añadir):
   ```
   AUTHENTICATION_API_KEY=checkin24hs-secret-key-2024
   SERVER_URL=http://localhost:8080
   LOG_LEVEL=INFO
   ```

4. **Crear el contenedor**

---

## 🔍 Paso 3: Buscar en EasyPanel

### Lugares donde puede estar:

1. **"Containers"** → "All Containers"
2. **"Docker"** → "Containers"
3. **"Services"** → Buscar por "evolution" o "api"
4. **"Stacks"** → Si está en un stack
5. **"Projects"** → Si está en un proyecto

### Buscar por:
- Nombre: `evolution`
- Nombre: `checkin24hs`
- Nombre: `api`
- Imagen: `atendai/evolution-api`

---

## 🔧 Paso 4: Crear Manualmente desde SSH

Si EasyPanel no lo muestra, créalo directamente:

```bash
cd ~/evolution-api

# Eliminar todo lo existente
docker-compose down -v

# Verificar archivos
cat docker-compose.yml
cat .env

# Recrear
docker-compose up -d

# Verificar
docker ps -a
docker logs evolution-api-checkin24hs
```

---

## 🔍 Paso 5: Verificar en EasyPanel Después de Crear

1. **Refrescar la página** de EasyPanel (F5)
2. **Buscar de nuevo** en "Containers"
3. **Si aparece**, haz clic y ve a "Logs"

---

## 🆘 Si Sigue Sin Aparecer

### Verificar Docker en EasyPanel:

1. **En EasyPanel**:
   - Ve a "Settings" o "System"
   - Verifica que Docker está conectado
   - Verifica que puedes ver otros contenedores

2. **Desde SSH**:
   ```bash
   # Ver todos los contenedores
   docker ps -a
   
   # Ver si EasyPanel puede verlos
   # (EasyPanel usa la API de Docker)
   ```

3. **Problema de permisos**:
   - Puede que EasyPanel no tenga permisos para ver el contenedor
   - Verifica la configuración de Docker en EasyPanel

---

## ✅ Verificación Final

Una vez que encuentres o crees el contenedor:

1. **Estado**: Debe estar "Running"
2. **Puertos**: Debe mostrar `8080:8080`
3. **Logs**: Debe mostrar que Evolution API está iniciando

---

## 📋 Próximos Pasos

Ejecuta desde SSH:

```bash
cd ~/evolution-api
docker ps -a
docker-compose ps
```

Y comparte la salida. Con eso veremos si el contenedor existe realmente o si hay que crearlo de nuevo.


