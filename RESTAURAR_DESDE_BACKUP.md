# 🔄 Restaurar desde Backup - Guía Paso a Paso

## 📋 Opciones Disponibles

Tienes **3 opciones** para restaurar a un estado funcional:

1. **Opción A: Restaurar desde backup local** (más rápido)
2. **Opción B: Restaurar desde un commit de Git anterior** (más seguro)
3. **Opción C: Restaurar directamente en el servidor** (si no tienes acceso local)

---

## 🔄 Opción A: Restaurar desde Backup Local

### Paso 1: Verificar que el Backup Existe

```bash
# En tu máquina local (Windows PowerShell o CMD)
cd C:\Users\German\Downloads\Checkin24hs
dir backups\backup_2025-08-06_11-04-23\dashboard.html
```

**Si existe:** Verás el archivo listado

**Si NO existe:** Usa la Opción B o C

### Paso 2: Copiar el Backup al Archivo Actual

```bash
# Hacer backup del archivo actual primero (por si acaso)
copy dashboard.html dashboard.html.backup_antes_restaurar

# Copiar el backup al archivo actual
copy backups\backup_2025-08-06_11-04-23\dashboard.html dashboard.html
```

### Paso 3: Verificar que se Copió

```bash
# Verificar que el archivo existe y tiene contenido
dir dashboard.html
```

### Paso 4: Subir a GitHub

```bash
git add dashboard.html
git commit -m "Restaurar dashboard.html desde backup funcional"
git push origin main
```

### Paso 5: Desplegar en EasyPanel

- Ve a EasyPanel
- Forzar re-deploy del servicio dashboard
- O usar el script para aplicar directamente en el servidor (Opción C)

---

## 🔄 Opción B: Restaurar desde Commit de Git

### Paso 1: Ver Commits Disponibles

```bash
# Ver los últimos 20 commits
git log --oneline -20
```

**Busca un commit ANTES de los problemas de `saveHotelChanges`**

**Commits recomendados (antes de los problemas):**
- `266b8b0` - "Agregar script completo para corregir Bad Gateway en dashboard"
- `258e39e` - "Agregar nueva pestaña WhatsApp separada con funcionalidad completa"
- `f6989f4` - "Corregir modales: hacer funciones globales y agregar validaciones"

### Paso 2: Ver el Contenido de un Commit Específico

```bash
# Ver qué archivos cambió un commit
git show --name-only 266b8b0

# Ver el contenido de dashboard.html en ese commit
git show 266b8b0:dashboard.html > dashboard_backup_commit.html
```

### Paso 3: Restaurar desde un Commit

```bash
# Hacer backup del archivo actual primero
copy dashboard.html dashboard.html.backup_antes_restaurar

# Restaurar dashboard.html desde un commit específico
git checkout 266b8b0 -- dashboard.html

# O restaurar todo el proyecto desde ese commit (CUIDADO: esto restaura TODO)
# git checkout 266b8b0 -- .
```

### Paso 4: Verificar que se Restauró

```bash
# Ver el estado
git status

# Ver diferencias
git diff dashboard.html
```

### Paso 5: Subir a GitHub

```bash
git add dashboard.html
git commit -m "Restaurar dashboard.html desde commit funcional 266b8b0"
git push origin main
```

---

## 🔄 Opción C: Restaurar Directamente en el Servidor

### Paso 1: Conectarte al Servidor

```bash
ssh usuario@tu-servidor
# O usa el terminal web de EasyPanel
```

### Paso 2: Encontrar el Contenedor

```bash
docker ps | grep dashboard
# Anota el nombre del contenedor (ejemplo: checkin24hs-dashboard-1)
```

### Paso 3: Crear Backup del Archivo Actual en el Servidor

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← Cambia esto
docker exec $CONTAINER_NAME cp /usr/share/nginx/html/dashboard.html /tmp/dashboard_backup_servidor.html
```

### Paso 4: Descargar el Backup desde GitHub

**Opción 4A: Desde un commit específico de Git**

```bash
# Descargar dashboard.html desde un commit específico
curl -o /tmp/dashboard_restaurado.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/266b8b0/dashboard.html
```

**Opción 4B: Desde el backup local (si tienes acceso)**

```bash
# Si tienes el archivo backup local, súbelo primero a un lugar accesible
# O usa scp para copiarlo al servidor:
# scp backups/backup_2025-08-06_11-04-23/dashboard.html usuario@servidor:/tmp/dashboard_restaurado.html
```

### Paso 5: Copiar al Contenedor

```bash
CONTAINER_NAME="checkin24hs-dashboard-1"  # ← Cambia esto
docker cp /tmp/dashboard_restaurado.html $CONTAINER_NAME:/usr/share/nginx/html/dashboard.html
```

### Paso 6: Verificar que se Copió

```bash
docker exec $CONTAINER_NAME ls -lh /usr/share/nginx/html/dashboard.html
```

### Paso 7: Reiniciar el Contenedor

```bash
docker restart $CONTAINER_NAME
sleep 5
docker ps | grep $CONTAINER_NAME
```

### Paso 8: Verificar en el Navegador

1. Abre `https://dashboard.checkin24hs.com`
2. Presiona **Ctrl+F5** (limpiar caché)
3. Abre la consola (F12)
4. Verifica que NO hay errores de `saveHotelChanges`

---

## 🎯 Recomendación: Opción A (Backup Local)

**Es la más rápida y segura:**

1. El backup está en: `backups/backup_2025-08-06_11-04-23/dashboard.html`
2. Es de antes de todos los problemas de `saveHotelChanges`
3. Solo necesitas copiarlo y subirlo a GitHub

**Comandos rápidos:**

```bash
# En Windows PowerShell
cd C:\Users\German\Downloads\Checkin24hs
copy dashboard.html dashboard.html.backup_antes_restaurar
copy backups\backup_2025-08-06_11-04-23\dashboard.html dashboard.html
git add dashboard.html
git commit -m "Restaurar dashboard.html desde backup funcional"
git push origin main
```

Luego despliega en EasyPanel o usa el script para aplicar en el servidor.

---

## 🆘 Si Algo Sale Mal

### Restaurar el Backup que Acabas de Crear

```bash
# Si restauraste y algo salió mal, puedes volver al estado anterior
copy dashboard.html.backup_antes_restaurar dashboard.html
git add dashboard.html
git commit -m "Revertir restauracion - volver al estado anterior"
git push origin main
```

### Verificar el Estado

```bash
# Ver qué archivos cambiaron
git status

# Ver diferencias
git diff dashboard.html

# Ver historial
git log --oneline -10
```

---

## ✅ Checklist Final

- [ ] Hice backup del archivo actual antes de restaurar
- [ ] Restauré desde backup o commit
- [ ] Verifiqué que el archivo se restauró correctamente
- [ ] Subí los cambios a GitHub
- [ ] Desplegué en EasyPanel o apliqué en el servidor
- [ ] Verifiqué en el navegador que funciona
- [ ] No hay errores en la consola (F12)

---

## 💡 Notas Importantes

- **Siempre crea un backup** antes de restaurar
- **El backup local es del 6 de agosto de 2025** - puede estar un poco desactualizado
- **Los commits de Git son más recientes** pero pueden tener algunos problemas
- **Recomiendo usar el backup local** y luego aplicar solo las correcciones necesarias

---

## 📞 Si Necesitas Ayuda

Dime:
1. ¿Qué opción quieres usar? (A, B o C)
2. ¿En qué paso estás?
3. ¿Qué error ves?
4. Te ayudo a resolverlo

