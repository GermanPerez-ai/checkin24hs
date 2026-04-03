# 🔍 Probar Contenedor Específico

## ⚠️ Problema Detectado

Hay **3 contenedores** del dashboard corriendo simultáneamente. Esto puede causar conflictos.

## ✅ Comandos para Ejecutar

Usa el **primer contenedor** (4f00d5bf3b67):

```bash
# 1. Probar acceso desde dentro del contenedor
docker exec 4f00d5bf3b67 curl http://localhost/

# 2. Verificar que dashboard.html existe
docker exec 4f00d5bf3b67 ls -la /usr/share/nginx/html/

# 3. Verificar configuración de nginx
docker exec 4f00d5bf3b67 cat /etc/nginx/conf.d/default.conf

# 4. Ver logs del contenedor
docker logs 4f00d5bf3b67

# 5. Verificar que nginx está escuchando
docker exec 4f00d5bf3b67 netstat -tlnp | grep :80
```

## 🔍 Verificar los Otros Contenedores

También prueba con los otros dos:

```bash
docker exec 51a0c8006f59 curl http://localhost/
docker exec d0d0575b3aa9 curl http://localhost/
```

## ⚠️ Solución: Detener Contenedores Duplicados

Si hay múltiples contenedores, puede ser que EasyPanel esté creando nuevos sin detener los antiguos. 

**En EasyPanel:**
1. Ve al servicio `dashboard`
2. Haz clic en **"Detener"** (stop)
3. Espera a que se detenga completamente
4. Luego haz clic en **"Implementar"** (deploy) de nuevo

Esto debería dejar solo un contenedor activo.

---

**Ejecuta los comandos y comparte los resultados.**
