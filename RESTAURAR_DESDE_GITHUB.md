# 🔄 Restaurar desde GitHub - Guía Paso a Paso

## 📋 Objetivo

Restaurar `dashboard.html` desde un commit de GitHub que funcionaba correctamente (antes de los problemas de `saveHotelChanges`).

---

## 🎯 Paso 1: Identificar el Commit Funcional

### Ver commits disponibles:

```bash
git log --oneline -30
```

### Commits recomendados (antes de los problemas):

- **`266b8b0`** - "Agregar script completo para corregir Bad Gateway en dashboard"
- **`258e39e`** - "Agregar nueva pestaña WhatsApp separada con funcionalidad completa"
- **`f6989f4`** - "Corregir modales: hacer funciones globales y agregar validaciones"

**Recomendación:** Usar `266b8b0` (antes de todos los problemas de `saveHotelChanges`)

---

## 🔄 Paso 2: Restaurar desde GitHub (Local)

### Opción A: Restaurar solo dashboard.html

```bash
# 1. Hacer backup del archivo actual
copy dashboard.html dashboard.html.backup_antes_restaurar

# 2. Restaurar desde el commit funcional
git checkout 266b8b0 -- dashboard.html

# 3. Verificar que se restauró
git status

# 4. Subir a GitHub
git add dashboard.html
git commit -m "Restaurar dashboard.html desde commit funcional 266b8b0"
git push origin main
```

### Opción B: Ver el contenido antes de restaurar

```bash
# Ver el contenido del archivo en ese commit
git show 266b8b0:dashboard.html > dashboard_commit_266b8b0.html

# Revisar el archivo
# Si te gusta, cópialo:
copy dashboard_commit_266b8b0.html dashboard.html
```

---

## 🚀 Paso 3: Aplicar en el Servidor

### Opción A: Desde GitHub (Recomendado)

```bash
# 1. Conectarte al servidor
ssh usuario@tu-servidor

# 2. Encontrar el contenedor
docker ps | grep dashboard
# Anota el nombre (ejemplo: checkin24hs-dashboard-1)

# 3. Crear backup en el servidor
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← Cambia esto
docker exec $CONTAINER_NAME cp /usr/share/nginx/html/dashboard.html /tmp/dashboard_backup_servidor.html

# 4. Descargar desde GitHub (commit específico)
curl -o /tmp/dashboard_restaurado.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/266b8b0/dashboard.html

# 5. Verificar que se descargó
ls -lh /tmp/dashboard_restaurado.html

# 6. Copiar al contenedor
docker cp /tmp/dashboard_restaurado.html $CONTAINER_NAME:/usr/share/nginx/html/dashboard.html

# 7. Verificar que se copió
docker exec $CONTAINER_NAME ls -lh /usr/share/nginx/html/dashboard.html

# 8. Reiniciar el contenedor
docker restart $CONTAINER_NAME
sleep 5

# 9. Verificar que está corriendo
docker ps | grep $CONTAINER_NAME

# 10. Limpiar archivo temporal
rm /tmp/dashboard_restaurado.html
```

### Opción B: Desde la rama main (después de hacer push)

```bash
# 1. Conectarte al servidor
ssh usuario@tu-servidor

# 2. Encontrar el contenedor
docker ps | grep dashboard
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← Cambia esto

# 3. Crear backup
docker exec $CONTAINER_NAME cp /usr/share/nginx/html/dashboard.html /tmp/dashboard_backup_servidor.html

# 4. Descargar desde GitHub (rama main - después del push)
curl -o /tmp/dashboard_restaurado.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

# 5. Copiar al contenedor
docker cp /tmp/dashboard_restaurado.html $CONTAINER_NAME:/usr/share/nginx/html/dashboard.html

# 6. Reiniciar
docker restart $CONTAINER_NAME
sleep 5

# 7. Verificar
docker ps | grep $CONTAINER_NAME
rm /tmp/dashboard_restaurado.html
```

---

## 📋 Comandos Completos (Copia y Pega)

### En tu máquina local (PowerShell):

```powershell
# Ir a la carpeta
cd C:\Users\German\Downloads\Checkin24hs

# Backup del archivo actual
copy dashboard.html dashboard.html.backup_antes_restaurar

# Restaurar desde commit funcional
git checkout 266b8b0 -- dashboard.html

# Verificar
git status

# Subir a GitHub
git add dashboard.html
git commit -m "Restaurar dashboard.html desde commit funcional 266b8b0"
git push origin main
```

### En el servidor (SSH):

```bash
# Configurar variables
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← CAMBIA ESTO

# Backup
docker exec $CONTAINER_NAME cp /usr/share/nginx/html/dashboard.html /tmp/dashboard_backup_servidor.html

# Descargar desde GitHub
curl -o /tmp/dashboard_restaurado.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/266b8b0/dashboard.html

# Copiar al contenedor
docker cp /tmp/dashboard_restaurado.html $CONTAINER_NAME:/usr/share/nginx/html/dashboard.html

# Reiniciar
docker restart $CONTAINER_NAME
sleep 5

# Verificar
docker ps | grep $CONTAINER_NAME
rm /tmp/dashboard_restaurado.html
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

3. **Verificar que la función existe:**
   - En la consola, escribe: `typeof window.saveHotelChanges`
   - Debe retornar: `"function"` o `"undefined"` (si no existía antes)

---

## 🆘 Si Algo Sale Mal

### Revertir los cambios:

```bash
# En local
git checkout main -- dashboard.html
git add dashboard.html
git commit -m "Revertir restauracion"
git push origin main
```

### Restaurar desde backup del servidor:

```bash
# En el servidor
CONTAINER_NAME="checkin24hs-dashboard-1"
docker exec $CONTAINER_NAME cp /tmp/dashboard_backup_servidor.html /usr/share/nginx/html/dashboard.html
docker restart $CONTAINER_NAME
```

---

## 📝 Notas Importantes

- **El commit `266b8b0` es de antes de los problemas de `saveHotelChanges`**
- **Puede que algunas funcionalidades nuevas no estén en ese commit**
- **Siempre crea backups antes de restaurar**
- **Verifica cada paso antes de continuar**

---

## 🎯 Resumen Rápido

1. **Local:** `git checkout 266b8b0 -- dashboard.html` → `git push`
2. **Servidor:** Descargar desde GitHub → Copiar al contenedor → Reiniciar
3. **Verificar:** Navegador → Ctrl+F5 → Consola (F12) → Sin errores

