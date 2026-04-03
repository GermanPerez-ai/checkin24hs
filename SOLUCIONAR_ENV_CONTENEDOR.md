# 🔧 Solucionar: .env no se lee en el Contenedor

## 🔍 Problema

El archivo `.env` existe en el sistema de archivos del servidor (`/etc/easypanel/projects/checkin24hs/dashboard/code/.env`), pero el contenedor Docker no lo está leyendo.

## 📋 Soluciones

### **Solución 1: Verificar dónde está el código dentro del contenedor**

```bash
# Entrar al contenedor
docker exec -it 5dad1338275e sh

# Dentro del contenedor, verificar:
pwd
ls -la
cat .env  # Ver si existe el archivo
exit
```

### **Solución 2: Copiar .env al contenedor (Temporal)**

```bash
# Copiar el .env al contenedor
docker cp /etc/easypanel/projects/checkin24hs/dashboard/code/.env 5dad1338275e:/app/.env

# Reiniciar el contenedor
docker restart 5dad1338275e
```

### **Solución 3: Configurar como Variable de Entorno en EasyPanel (RECOMENDADO)**

En EasyPanel, las variables de entorno se configuran mejor desde el panel:

1. Ve a EasyPanel en tu navegador
2. Busca el servicio "dashboard"
3. Ve a la sección de "Environment Variables" o "Variables de Entorno"
4. Agrega:
   - `GEMINI_API_KEY` = `AIzaSyDvza5tlt0fjEgTamUKG1ZjTuqU8qjCaxI`
   - `GEMINI_MODEL` = `gemini-2.5-flash`
5. Guarda y reinicia el servicio

### **Solución 4: Verificar si EasyPanel monta el directorio**

```bash
# Ver volúmenes montados del contenedor
docker inspect 5dad1338275e | grep -A 10 "Mounts"

# Ver dónde está montado el código
docker inspect 5dad1338275e | grep -i "source\|destination\|workdir"
```

---

## ✅ Verificación Rápida

Ejecuta esto para verificar:

```bash
# 1. Verificar que el .env existe en el host
ls -la /etc/easypanel/projects/checkin24hs/dashboard/code/.env

# 2. Ver qué hay dentro del contenedor
docker exec 5dad1338275e ls -la /app/

# 3. Verificar si el .env está dentro del contenedor
docker exec 5dad1338275e cat /app/.env 2>&1
```

---

## 💡 Recomendación

**La mejor solución es usar Variables de Entorno en EasyPanel** (Solución 3), porque:
- ✅ Las variables persisten entre reinicios
- ✅ No dependen de archivos dentro del contenedor
- ✅ Es la forma estándar de manejar secretos en contenedores
- ✅ No se pierden cuando EasyPanel reconstruye el contenedor

---

**Ejecuta primero la "Verificación Rápida" para entender dónde está el problema.**
