# 🔄 Restaurar desde Commit ab0b9f5

## 📋 Información del Commit

- **Commit:** `ab0b9f5`
- **Mensaje:** "Actualizar Dockerfile para servir dashboard.html completo con todas las funcionalidades"
- **Fecha:** Hace 2 días
- **Rama:** `main`

Este commit actualizó el Dockerfile, pero el `dashboard.html` de ese momento debería estar funcional.

---

## 🚀 Pasos para Restaurar

### Paso 1: En tu máquina local (PowerShell)

```powershell
# Ir a la carpeta
cd C:\Users\German\Downloads\Checkin24hs

# Hacer backup del archivo actual (IMPORTANTE)
copy dashboard.html dashboard.html.backup_antes_restaurar_ab0b9f5

# Restaurar dashboard.html desde el commit ab0b9f5
git checkout ab0b9f5 -- dashboard.html

# Verificar que cambió
git status

# Subir a GitHub
git add dashboard.html
git commit -m "Restaurar dashboard.html desde commit ab0b9f5 (Dockerfile funcional)"
git push origin main
```

### Paso 2: Aplicar en el Servidor

#### Opción A: Descargar directamente desde GitHub (Recomendado)

```bash
# 1. Conectarte al servidor
ssh usuario@tu-servidor

# 2. Encontrar el contenedor
docker ps | grep dashboard
# Anota el nombre (ejemplo: checkin24hs-dashboard-1)

# 3. Configurar variables
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← CAMBIA ESTO

# 4. Crear backup en el servidor
docker exec $CONTAINER_NAME cp /usr/share/nginx/html/dashboard.html /tmp/dashboard_backup_servidor_ab0b9f5.html

# 5. Descargar desde GitHub (commit ab0b9f5)
curl -o /tmp/dashboard_restaurado_ab0b9f5.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/ab0b9f5/dashboard.html

# 6. Verificar que se descargó
ls -lh /tmp/dashboard_restaurado_ab0b9f5.html

# 7. Copiar al contenedor
docker cp /tmp/dashboard_restaurado_ab0b9f5.html $CONTAINER_NAME:/usr/share/nginx/html/dashboard.html

# 8. Verificar que se copió
docker exec $CONTAINER_NAME ls -lh /usr/share/nginx/html/dashboard.html

# 9. Reiniciar el contenedor
docker restart $CONTAINER_NAME
sleep 5

# 10. Verificar que está corriendo
docker ps | grep $CONTAINER_NAME

# 11. Limpiar archivo temporal
rm /tmp/dashboard_restaurado_ab0b9f5.html
```

#### Opción B: Desde la rama main (después del push)

```bash
# Después de hacer push en el Paso 1, descargar desde main
curl -o /tmp/dashboard_restaurado.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
docker cp /tmp/dashboard_restaurado.html $CONTAINER_NAME:/usr/share/nginx/html/dashboard.html
docker restart $CONTAINER_NAME
```

---

## 📋 Comandos Completos (Copia y Pega)

### En tu máquina local (PowerShell):

```powershell
cd C:\Users\German\Downloads\Checkin24hs
copy dashboard.html dashboard.html.backup_antes_restaurar_ab0b9f5
git checkout ab0b9f5 -- dashboard.html
git status
git add dashboard.html
git commit -m "Restaurar dashboard.html desde commit ab0b9f5"
git push origin main
```

### En el servidor (SSH):

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← CAMBIA ESTO

# Backup
docker exec $CONTAINER_NAME cp /usr/share/nginx/html/dashboard.html /tmp/dashboard_backup_servidor_ab0b9f5.html

# Descargar desde GitHub
curl -o /tmp/dashboard_restaurado_ab0b9f5.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/ab0b9f5/dashboard.html

# Copiar al contenedor
docker cp /tmp/dashboard_restaurado_ab0b9f5.html $CONTAINER_NAME:/usr/share/nginx/html/dashboard.html

# Reiniciar
docker restart $CONTAINER_NAME
sleep 5

# Verificar
docker ps | grep $CONTAINER_NAME
rm /tmp/dashboard_restaurado_ab0b9f5.html
```

---

## ✅ Verificación Final

1. **En el navegador:**
   - Abre `https://dashboard.checkin24hs.com`
   - Presiona **Ctrl+F5** (limpiar caché)
   - Abre la consola (F12)

2. **Verificar que NO hay errores:**
   - NO debe aparecer: `Identifier 'saveHotelChanges' has already been declared`
   - Debe aparecer: `✅ Cliente de Supabase inicializado correctamente`

3. **Verificar funcionalidad:**
   - Intenta iniciar sesión
   - Verifica que el dashboard carga correctamente

---

## 🆘 Si Algo Sale Mal

### Revertir los cambios:

```powershell
# En local
git checkout main -- dashboard.html
git add dashboard.html
git commit -m "Revertir restauracion desde ab0b9f5"
git push origin main
```

### Restaurar desde backup del servidor:

```bash
# En el servidor
CONTAINER_NAME="checkin24hs-dashboard-1"
docker exec $CONTAINER_NAME cp /tmp/dashboard_backup_servidor_ab0b9f5.html /usr/share/nginx/html/dashboard.html
docker restart $CONTAINER_NAME
```

---

## 📝 Notas Importantes

- **El commit `ab0b9f5` es de hace 2 días** - debería estar funcional
- **Siempre crea backups** antes de restaurar
- **Verifica cada paso** antes de continuar
- **El commit actualizó el Dockerfile**, pero el dashboard.html de ese momento debería funcionar

---

## 🎯 Resumen Rápido

1. **Local:** `git checkout ab0b9f5 -- dashboard.html` → `git push`
2. **Servidor:** Descargar desde GitHub → Copiar al contenedor → Reiniciar
3. **Verificar:** Navegador → Ctrl+F5 → Consola (F12) → Sin errores

